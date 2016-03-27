#import <IOKit/IOMessage.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import "TSAppDelegate.h"
#import "ImageSnap.h"

//
//  TSAppDelegate.m
//  TSAppDelegate
//
//  Created by Jacob Rosenthal on 8/22/13.
//  Copyright 2012 Augmentous. All rights reserved.
//
@implementation TSAppDelegate

@synthesize root_port;
@synthesize notifyPortRef;
@synthesize notifierObject;
@synthesize displayWrangler;
@synthesize notificationPort;
@synthesize notifier;
@synthesize statusItem;
@synthesize statusMenu;
@synthesize statusImage;
@synthesize startupMenuItem;
@synthesize windowOutlet;
@synthesize previewImage;

- (instancetype)init {
    self = [super init]; // or call the designated initalizer
    if (self) {
        
        root_port = NULL;
        notifyPortRef = NULL;
        notifierObject = NULL;
        
        displayWrangler = NULL;
        notificationPort = NULL;
        notifier = NULL;
    }
    
    return self;
}

- (void)awakeFromNib
{
    
    //make run at startup up to date - TODO, check this more often?
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"memoryio-launchatlogin"]) {
        [startupMenuItem setState:NSOnState];
    }else{
        [startupMenuItem setState:NSOffState];
    }
    
	statusItem = [[NSStatusBar systemStatusBar]
                  statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setHighlightMode:YES];
	[statusItem setEnabled:YES];
	[statusItem setToolTip:@"MemoryIO"];
	
	[statusItem setTarget:self];
    
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];

    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon" ofType:@"png"]];

    //Sets the images in our NSStatusItem
    [statusItem setImage:statusImage];
    
    //put menu in menubar
    [statusItem setMenu:statusMenu];
}

- (IBAction)quitAction:(id)sender
{
    [NSApp terminate:self];
}

- (IBAction)startupAction:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults]; //should this be global?

    if ([sender state] == NSOffState){
        
        //turn on open at startup
        // Turn on launch at login
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.augmentous.LaunchAtLoginHelperApp", YES)) {
            [sender setState: NSOnState];
            [userDefaults setBool:YES
                             forKey:@"memoryio-launchatlogin"];
        }
    }else{

        //turn off open at startup
        // Turn off launch at login
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.augmentous.LaunchAtLoginHelperApp", NO)) {
            [sender setState: NSOffState];
            [userDefaults setBool:NO
                           forKey:@"memoryio-launchatlogin"];
        }
    }
}

- (IBAction)aboutAction:(id)sender
{
    [sender setState: NSOffState];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)forceAction:(id)sender
{
    [self takePhotoWithDelay:2.0f];
}

-(IBAction)preview:(id)sender
{
    NSImage *backgroundImage = [self getLastImage];

    if(!backgroundImage){
        
        //Used to detect where our files are
        NSBundle *bundle = [NSBundle mainBundle];
        backgroundImage = [[NSImage alloc] initWithContentsOfFile:
                           [bundle pathForResource:@"io_logo" ofType:@"png"]];
    }
    
    [self setPhoto:backgroundImage];
    
    [windowOutlet makeKeyAndOrderFront: self];
    [NSApp activateIgnoringOtherApps:YES];
}

-(NSImage*)getLastImage
{
    NSError *error;
    NSArray *pictures = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:
                         [NSString stringWithFormat:@"%@%@",
                          NSHomeDirectory(),
                          @"/Pictures/memoryIO/"] error:&error ];
    
    NSString* tempPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Pictures/memoryIO/"];
    NSString* tempFile = [tempPath stringByAppendingPathComponent:pictures.lastObject];
    NSURL* URL = [NSURL fileURLWithPath:tempFile];
    
    NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfURL:URL];
    
    return backgroundImage;
}

-(IBAction)setPhoto:(NSImage*)backgroundImage
{
    NSSize imageSize = [backgroundImage size];
    
    [windowOutlet setAspectRatio:imageSize];
    
    [previewImage setImage:backgroundImage];
    
    NSRect frame = [windowOutlet frame];
    frame.size.width = (frame.size.height * imageSize.width) / imageSize.height;
    [windowOutlet setFrame:frame display:YES animate:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"Starting memoryio");
    
    [self subscribeDisplayNotifications];
    [self subscribePowerNotifications];
    
    //put startup stuff here //NSUserDefaults standarduserdefaults boolforkey
    BOOL startedAtLogin = NO;
    for (NSString *arg in [[NSProcessInfo processInfo] arguments]) {
        if ([arg isEqualToString:@"launchAtLogin"]) startedAtLogin = YES;
    }

}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    NSLog(@"memoryio is exiting...");
    
    [self unsubscribeDisplayNotifications];
    [self unsubscribePowerNotifications];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    [center removeDeliveredNotification:notification];
	switch (notification.activationType) {
		case NSUserNotificationActivationTypeActionButtonClicked:
			NSLog(@"Reply Button was clicked -> quick reply");
			break;
		case NSUserNotificationActivationTypeContentsClicked:
			NSLog(@"Notification body was clicked -> redirect to item");
            [self preview:nil];
            [NSApp activateIgnoringOtherApps:YES];
			break;
		default:
			NSLog(@"Notfiication appears to have been dismissed!");
			break;
	}
}

- (IBAction)tweet:(id)sender
{
    NSImage *backgroundImage = [self getLastImage];

    NSArray * shareItems = [NSArray arrayWithObjects:@"  #memoryio", backgroundImage, nil];
    
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    service.delegate = self;
    [service performWithItems:shareItems];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    
    return YES;
}

// register to receive system power notifications
// mainly for when the system goes to sleep and wakes up
- (void)subscribePowerNotifications
{
    root_port = IORegisterForSystemPower( (__bridge void *)(self), &notifyPortRef, powerCallback, &notifierObject );
    if ( root_port == 0 )
    {
        printf("IORegisterForSystemPower failed\n");
        [NSApp terminate:self];
    }
    
    // add the notification port to the application runloop
    CFRunLoopAddSource( CFRunLoopGetCurrent(),
                       IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopCommonModes );
    
}

// unsubscribe system sleep notifications
// mainly for when the system goes to sleep and wakes up
- (void)unsubscribePowerNotifications{
    // remove the sleep notification port from the application runloop
    CFRunLoopRemoveSource( CFRunLoopGetCurrent(),
                          IONotificationPortGetRunLoopSource(notifyPortRef),
                          kCFRunLoopCommonModes );
    
    // deregister for system sleep notifications
    IODeregisterForSystemPower( &notifierObject );
    
    // IORegisterForSystemPower implicitly opens the Root Power Domain IOService
    // so we close it here
    IOServiceClose( root_port );
    
    // destroy the notification port allocated by IORegisterForSystemPower
    IONotificationPortDestroy( notifyPortRef );
}

// register to receive system display notifications
// mainly for when the display goes to sleep and wakes up
- (void)subscribeDisplayNotifications
{
	displayWrangler = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceNameMatching("IODisplayWrangler"));
	if (! displayWrangler) {
		//message (LOG_ERR, "IOServiceGetMatchingService failed\n");
		[NSApp terminate:self];
	}
	notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
	if (! notificationPort) {
		//message (LOG_ERR, "IONotificationPortCreate failed\n");
		[NSApp terminate:self];
	}
	if (IOServiceAddInterestNotification(notificationPort, displayWrangler, kIOGeneralInterest,
                                         displayCallback, (__bridge void *)(self), &notifier) != kIOReturnSuccess) {
		//message (LOG_ERR, "IOServiceAddInterestNotification failed\n");
		[NSApp terminate:self];
	}
	CFRunLoopAddSource (CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notificationPort), kCFRunLoopDefaultMode);
	IOObjectRelease (displayWrangler);
}

// unsubscribe system display notifications
// mainly for when the display goes to sleep and wakes up
- (void)unsubscribeDisplayNotifications
{
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(),IONotificationPortGetRunLoopSource(notificationPort),kCFRunLoopCommonModes);
    IODeregisterForSystemPower(&notifier);
    IOServiceClose(displayWrangler);
    IONotificationPortDestroy(notificationPort );
}

- (void) powerMessageReceived:(natural_t)messageType withArgument:(void *)messageArgument{
    //careful here, kIOMessageDeviceHasPoweredOn and kIOMessageSystemHasPoweredOn will fire after sleep
    switch ( messageType )
    {
        case kIOMessageDeviceHasPoweredOn :
            // mainly for when the display goesto sleep and wakes up
            NSLog(@"powerMessageReceived: got a kIOMessageDeviceHasPoweredOn - device powered on");
            break;
        case kIOMessageSystemWillSleep:
            IOAllowPowerChange(root_port,(long)messageArgument);
            break;
        case kIOMessageCanSystemSleep:
            IOAllowPowerChange(root_port,(long)messageArgument);
            break;
        case kIOMessageSystemHasPoweredOn:
            // mainly for when the system goes to sleep and wakes up
            NSLog(@"powerMessageReceived: got a kIOMessageSystemHasPoweredOn - system powered on");
            [self takePhotoWithDelay:2.0f];
            break;
    }
}

// mainly for when the system goes to sleep and wakes up
void powerCallback( void *context, io_service_t service, natural_t messageType, void *messageArgument )
{
    [(__bridge TSAppDelegate *)context powerMessageReceived: messageType withArgument: messageArgument];
}

// mainly for when the display goesto sleep and wakes up
void displayCallback (void *context, io_service_t service, natural_t messageType, void *messageArgument)
{
    [(__bridge TSAppDelegate *)context powerMessageReceived: messageType withArgument: messageArgument];
}

- (void) takePhotoWithDelay: (float) delay {
    // This dispatch takes the function away from the UI so the menu returns immediately
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        ImageSnap *imageSnap = [ImageSnap new];
        [imageSnap setUpSessionWithDevice:[ImageSnap defaultVideoDevice]];
        [imageSnap saveSingleSnapshotFrom:[ImageSnap defaultVideoDevice]
                                                     toFile:[NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Pictures/memoryIO/"]
                                                 withWarmup:[NSNumber numberWithInt:delay] withTimelapse:nil];


        //Initalize new notification
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        //Set the title of the notification
        [notification setTitle:@"memoryio"];
        
        [notification setInformativeText:@"Well, Look at you!"];
    
//        if(imageURL != NULL)
//        {
//            
//            NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfURL:imageURL];
//            
//            [self setPhoto:backgroundImage];
//
//            //Set the text of the notification
//            [notification setInformativeText:@"Well, Look at you!"];
//            
//        } else
//        {
//            //Set the text of the notification
//            [notification setInformativeText:@"There was a problem taking that shot :("];
//            [notification setHasActionButton:false];
//        }
   
        [notification setSoundName:nil];
        
        //Get the default notification center
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        
        center.delegate=self;
        
        //Scheldule our NSUserNotification
        [center scheduleNotification:notification];
    }); // end of dispatch_async
    
}

@end
