#import "TSAppDelegate.h"

//
//  TSAppDelegate.m
//  TSAppDelegate
//
//  Created by Jacob Rosenthal on 8/22/13.
//  Copyright 2012 Augmentous. All rights reserved.
//
@implementation TSAppDelegate

@synthesize statusMenu;
@synthesize startupMenuItem;
@synthesize windowOutlet;
@synthesize previewImage;

NotificationManager *notificationManager;
NSStatusItem *statusItem;
NSImage *statusImage;

- (void)awakeFromNib
{

    notificationManager = [[NotificationManager alloc] init];
    typeof(self) __weak weakSelf = self;
    [notificationManager setNotificationBlock:^(natural_t messageType, void *messageArgument) {

        switch ( messageType )
        {
            case kIOMessageDeviceHasPoweredOn :
                // mainly for when the display goesto sleep and wakes up
                verbose("powerMessageReceived: got a kIOMessageDeviceHasPoweredOn - device powered on");
                break;
            case kIOMessageSystemHasPoweredOn:
                // mainly for when the system goes to sleep and wakes up
                verbose("powerMessageReceived: got a kIOMessageSystemHasPoweredOn - system powered on");
                [weakSelf takePhotoWithDelay:2.0f];
                break;
        }
    }];
    
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
    verbose("Starting memoryio");
    
    [notificationManager subscribeDisplayNotifications];
    [notificationManager subscribePowerNotifications];
    
    //put startup stuff here //NSUserDefaults standarduserdefaults boolforkey
    BOOL startedAtLogin = NO;
    for (NSString *arg in [[NSProcessInfo processInfo] arguments]) {
        if ([arg isEqualToString:@"launchAtLogin"]) startedAtLogin = YES;
    }
    
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    [center removeDeliveredNotification:notification];
    switch (notification.activationType) {
        case NSUserNotificationActivationTypeActionButtonClicked:
            verbose("Reply Button was clicked -> quick reply");
            break;
        case NSUserNotificationActivationTypeContentsClicked:
            verbose("Notification body was clicked -> redirect to item");
            [self preview:nil];
            [NSApp activateIgnoringOtherApps:YES];
            break;
        default:
            verbose("Notfiication appears to have been dismissed!");
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

- (void) postNotification:(NSString *) informativeText withActionBoolean:(BOOL)hasActionButton{
    //Initalize new notification
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    //Set the title of the notification
    [notification setTitle:@"memoryio"];
    
    [notification setInformativeText:informativeText];
    [notification setHasActionButton:hasActionButton];
    
    
    [notification setSoundName:nil];
    
    //Get the default notification center
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    
    center.delegate=self;
    
    //Scheldule our NSUserNotification
    [center scheduleNotification:notification];
}

- (void) takePhotoWithDelay: (float) delay {

    NSString *path = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Pictures/memoryIO/"];

    // create directory if it doesnt exist
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];

    typeof(self) __weak weakSelf = self;
    [ImageSnap saveSingleSnapshotFrom:[ImageSnap defaultVideoDevice]
                               toPath:path
                           withWarmup:[NSNumber numberWithInt:delay]
                    withCallbackBlock:^(NSURL *imageURL, NSError *error) {

                            if(error)
                            {
                                [weakSelf postNotification:@"There was a problem taking that shot :(" withActionBoolean:false];
                            } else {
                                [weakSelf postNotification:@"Well, Look at you!" withActionBoolean:true];
                            }


                    }]; // end of callback Block
}

@end
