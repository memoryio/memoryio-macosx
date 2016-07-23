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
@synthesize startupButton;
@synthesize windowOutlet;
@synthesize previewImage;
@synthesize locationPull;
@synthesize modePull;
@synthesize photoDelayText;
@synthesize warmupDelayText;

// not actually using these atm, but defining them to make mapping clear
typedef enum : NSUInteger
{
    Default = 0, Other, User
} LocationValue;

typedef enum : NSUInteger
{
    Photo = 0
} ModeValue;


NotificationManager *notificationManager;
NSStatusItem *statusItem;
NSImage *statusImage;
NSString *defaultPath;


#pragma Setup

- (void) populateLocation{
    [locationPull removeAllItems];
    [locationPull addItemWithTitle:defaultPath];
    [locationPull addItemWithTitle:@"Other"];

    NSString *location = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];

    if([location isEqualToString:defaultPath]) {
        [locationPull selectItemAtIndex:0];
    }else{
        [locationPull addItemWithTitle:location];
        [locationPull selectItemAtIndex:2];
    }
}

- (void) populateMode{
    [modePull removeAllItems];
    [modePull addItemWithTitle:@"Photo"];
    [modePull selectItemAtIndex:0];

    [[NSUserDefaults standardUserDefaults] valueForKey:@"memoryio-mode"];
}

- (void) populatePhotoDelay{

    float photoDelay = [[NSUserDefaults standardUserDefaults] floatForKey:@"memoryio-photo-delay"];
    [photoDelayText setFloatValue:photoDelay];
}

- (void) populateWarmupDelay{

    float warmupDelay = [[NSUserDefaults standardUserDefaults] floatForKey:@"memoryio-warmup-delay"];
    [warmupDelayText setFloatValue:warmupDelay];
}

- (void)setNSUserDefaults{
    //set startup
    // boolforkey returns NO if key does not exist

    //set mode
    if(![[NSUserDefaults standardUserDefaults] valueForKey:@"memoryio-mode"]) {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:0] forKey:@"memoryio-mode"];
    }

    //set location
    if(![[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"]) {
        [[NSUserDefaults standardUserDefaults] setObject:defaultPath forKey:@"memoryio-location"];
    }

    //set warmup delay
    if(![[NSUserDefaults standardUserDefaults] floatForKey:@"memoryio-warmup-delay"]) {
        [[NSUserDefaults standardUserDefaults] setFloat:2.0f forKey:@"memoryio-warmup-delay"];
    }

    //set photo delay
    // floatForKey returns 0 if key does not exist
}

- (void) setupMenuBar{

    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
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

- (void) setupPreferences{

    [self populateLocation];
    [self populateMode];
    [self populatePhotoDelay];
    [self populateWarmupDelay];

    bool launchAtLogin = [[NSUserDefaults standardUserDefaults] boolForKey:@"memoryio-launchatlogin"];
    if(launchAtLogin) {
        [startupButton setState:NSOnState];
    }else{
        [startupButton setState:NSOffState];
    }
}

-(void)setupNotifications{
    notificationManager = [[NotificationManager alloc] init];
    [notificationManager subscribeDisplayNotifications];
    [notificationManager subscribePowerNotifications];

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

                NSNumber *mode = [[NSUserDefaults standardUserDefaults] valueForKey:@"memoryio-mode"];
                if([mode isEqual:[NSNumber numberWithInteger:1]]){

                    float photoDelay = [[NSUserDefaults standardUserDefaults] floatForKey:@"memoryio-photo-delay"];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(photoDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf takePhoto];
                    });
                }
                break;
        }
    }];
}


#pragma Application

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    verbose("Starting memoryio");

    defaultPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Pictures/memoryIO/"];

    [self setNSUserDefaults];
    [self setupPreferences];
    [self setupNotifications];
    [self setupMenuBar];
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


#pragma Helpers

- (IBAction)tweet:(id)sender
{
    NSImage *backgroundImage = [self getLastImage];

    NSArray * shareItems = [NSArray arrayWithObjects:@"  #memoryio", backgroundImage, nil];

    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    service.delegate = self;
    [service performWithItems:shareItems];
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

- (void) takePhoto{
    typeof(self) __weak weakSelf = self;

    float warmupDelay = [[NSUserDefaults standardUserDefaults] floatForKey:@"memoryio-warmup-delay"];

    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];

    // create directory if it doesnt exist
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];

    //check error
    if(error){
        [weakSelf postNotification:@"There was a problem taking that shot :(" withActionBoolean:false];
        return;
    }

    [ImageSnap saveSingleSnapshotFrom:[ImageSnap defaultVideoDevice]
                               toPath:path
                           withWarmup:[NSNumber numberWithInt:warmupDelay]
                    withCallbackBlock:^(NSURL *imageURL, NSError *error) {

                        if(error)
                        {
                            [weakSelf postNotification:@"There was a problem taking that shot :(" withActionBoolean:false];
                        } else {
                            [weakSelf postNotification:@"Well, Look at you!" withActionBoolean:true];
                        }
                    }]; // end of callback Block
}

-(NSImage*)getLastImage
{
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];

    NSError *error;
    NSArray *pictures = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error ];

    NSString* tempFile = [path stringByAppendingPathComponent:pictures.lastObject];
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


#pragma Menu

- (IBAction)quitAction:(id)sender
{
    [NSApp terminate:self];
}

- (IBAction)aboutAction:(id)sender
{
    [sender setState: NSOffState];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)forceAction:(id)sender
{
    [self takePhoto];
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


#pragma Preferences

- (IBAction)startupAction:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if ([sender state] == NSOnState){
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.augmentous.LaunchAtLoginHelperApp", YES)) {
            [userDefaults setBool:YES forKey:@"memoryio-launchatlogin"];
        }
    }else{
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.augmentous.LaunchAtLoginHelperApp", NO)) {
            [userDefaults setBool:NO forKey:@"memoryio-launchatlogin"];
        }
    }
}

- (IBAction)setLocation:(NSPopUpButton*)sender {

    if([sender indexOfSelectedItem] == 0){
        [[NSUserDefaults standardUserDefaults] setObject:defaultPath forKey:@"memoryio-location"];
    }
    else if([sender indexOfSelectedItem] == 1){
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setCanChooseFiles:NO];
        [panel setCanChooseDirectories:YES];
        [panel setAllowsMultipleSelection:NO];

        NSInteger clicked = [panel runModal];

        if (clicked == NSFileHandlingPanelOKButton) {
            NSString *path = [NSString stringWithFormat:@"%@%@", [panel URL].path, @"/"];
            [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"memoryio-location"];
        }
    }
    [self populateLocation];
}

- (IBAction)setMode:(NSPopUpButton*)sender {
    NSMenuItem *selected = [sender selectedItem];
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:[selected tag]] forKey:@"memoryio-mode"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)photoDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:[sender floatValue] forKey:@"memoryio-photo-delay"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)warmupDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:[sender floatValue] forKey:@"memoryio-warmup-delay"];
}


#pragma Delegates

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{

    return YES;
}

@end
