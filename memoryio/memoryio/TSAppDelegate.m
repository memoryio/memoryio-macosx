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
@synthesize preferencesOutlet;
@synthesize previewImage;
@synthesize locationPull;
@synthesize modePull;
@synthesize photoDelayText;
@synthesize warmupDelayText;
@synthesize frameCountText;
@synthesize frameDelayText;
@synthesize loopCountText;

// not actually using these atm, but defining them to make mapping clear
typedef enum : NSUInteger
{
    Default = 0, Other, User
} LocationValue;

typedef enum : NSUInteger
{
    Photo = 0, Gif
} ModeValue;


NotificationManager *notificationManager;
NSStatusItem *statusItem;
NSImage *statusImage;


#pragma Setup

- (void) populateFrameCount{

    NSNumber *frameCount = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-frame-count"];
    [frameCountText setIntValue:frameCount.intValue];
}

- (void) populateLoopCount{

    NSNumber *loopCount = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-loop-count"];
    [loopCountText setIntValue:loopCount.intValue];
}

- (void) populateFrameDelay{

    NSNumber *frameDelay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-frame-delay"];
    [frameDelayText setFloatValue:frameDelay.floatValue];
}

- (void) populateLocation{
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];

    [locationPull removeAllItems];
    [locationPull addItemWithTitle:path];
    [locationPull addItemWithTitle:@"Other"];
    [locationPull selectItemAtIndex:0];
}

- (void) populateMode{
    [modePull removeAllItems];
    [modePull addItemWithTitle:@"Photo"];
    [modePull addItemWithTitle:@"Gif"];

    NSNumber *mode = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-mode"];

    [modePull selectItemAtIndex:[mode intValue]];
}

- (void) populatePhotoDelay{

    NSNumber *photoDelay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-photo-delay"];
    [photoDelayText setFloatValue:photoDelay.floatValue];
}

- (void) populateWarmupDelay{

    NSNumber *warmupDelay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-warmup-delay"];
    [warmupDelayText setFloatValue:warmupDelay.floatValue];
}

- (void)setNSUserDefaults{
    //set startup
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-launchatlogin"]) {
        if (SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.augmentous.LaunchAtLoginHelperApp", YES)) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"memoryio-launchatlogin"];
        }else{
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"memoryio-launchatlogin"];
        }
    }

    //set mode
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-mode"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"memoryio-mode"];
    }

    //set location
    if(![[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"]) {
        NSString *defaultPath = [NSString stringWithFormat:@"/Users/%@/Pictures/memoryIO/", NSUserName()];
        [[NSUserDefaults standardUserDefaults] setObject:defaultPath forKey:@"memoryio-location"];
    }

    //set warmup delay
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-warmup-delay"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:2.0f] forKey:@"memoryio-warmup-delay"];
    }

    //set warmup delay
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-photo-delay"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:0.0f] forKey:@"memoryio-photo-delay"];
    }

    //set frame delay
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-frame-delay"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:0.20f] forKey:@"memoryio-gif-frame-delay"];
    }

    //set frame count
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-frame-count"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:10] forKey:@"memoryio-gif-frame-count"];
    }

    //set frame count
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-loop-count"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"memoryio-gif-loop-count"];
    }
}

- (void) setupMenuBar{

    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setHighlightMode:YES];
    [statusItem setEnabled:YES];
    [statusItem setToolTip:@"MemoryIO"];

    [statusItem setTarget:self];

    statusImage = [NSImage imageNamed:@"statusIcon"];

    //Sets the images in our NSStatusItem
    [statusItem setImage:statusImage];

    //put menu in menubar
    [statusItem setMenu:statusMenu];
}

- (bool) isEnabled{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSArray* jobDicts = CFBridgingRelease(SMCopyAllJobDictionaries(kSMDomainUserLaunchd));
#pragma clang diagnostic pop

    if (jobDicts && [jobDicts count] > 0){
        for (NSDictionary* job in jobDicts){
            if ([@"com.augmentous.LaunchAtLoginHelperApp" isEqualToString:[job objectForKey:@"Label"]] && [[job objectForKey:@"OnDemand"] boolValue]){
                return true;
            }
        }
    }
    return false;
}

- (void) setupPreferences{

    [self populateFrameCount];
    [self populateLoopCount];
    [self populateFrameDelay];
    [self populateLocation];
    [self populateMode];
    [self populatePhotoDelay];
    [self populateWarmupDelay];

    //check SMLoginItem directly instead of memoryio-launchatlogin, but keep it around for posterity
    if ([self isEnabled]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"memoryio-launchatlogin"];
        [startupButton setState:NSOnState];
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"memoryio-launchatlogin"];
        [startupButton setState:NSOffState];
    }
}

-(void)setupNotifications{
    notificationManager = [[NotificationManager alloc] init];
    [notificationManager subscribeDisplayNotifications];
    [notificationManager subscribePowerNotifications];

    typeof(self) __weak weakSelf = self;
    [notificationManager setNotificationBlock:^(natural_t messageType, void *messageArgument) {

        NSNumber *delay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-photo-delay"];
        NSNumber *mode = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-mode"];

        switch ( messageType )
        {
            case kIOMessageDeviceHasPoweredOn :
                // mainly for when the display goesto sleep and wakes up
//                verbose("powerMessageReceived: got a kIOMessageDeviceHasPoweredOn - device powered on");
                break;
            case kIOMessageSystemHasPoweredOn:
                // mainly for when the system goes to sleep and wakes up
//                verbose("powerMessageReceived: got a kIOMessageSystemHasPoweredOn - system powered on");

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)( delay.floatValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                    if([mode isEqual:[NSNumber numberWithInteger:0]]){
                        [weakSelf takePhoto];
                    }else{
                        [weakSelf takeGif];
                    }

                });
                break;
        }
    }];
}


#pragma Application

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    verbose("Starting memoryio");

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
//            verbose("Reply Button was clicked -> quick reply");
            break;
        case NSUserNotificationActivationTypeContentsClicked:
//            verbose("Notification body was clicked -> redirect to item");
            [self preview:nil];
            [NSApp activateIgnoringOtherApps:YES];
            break;
        default:
//            verbose("Notfiication appears to have been dismissed!");
            break;
    }
}


#pragma Helpers

- (IBAction)tweet:(id)sender
{
    NSURL *last = [self urlForLast];

    NSArray * shareItems = [NSArray arrayWithObjects:@"#memoryio", last, nil];

    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:shareItems];

    sharingServicePicker.delegate = self;
    [sharingServicePicker showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
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

    NSNumber *warmupDelay = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-warmup-delay"];
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];

//    NSLog(@"%@, %@", warmupDelay, path);

    // create directory if it doesnt exist
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];

    //check error
    if(error){
        [self postNotification:@"There was a problem taking that shot :(" withActionBoolean:false];
        return;
    }

    typeof(self) __weak weakSelf = self;
    [ImageSnap saveSingleSnapshotFrom:[ImageSnap defaultVideoDevice]
                               toPath:path
                           withWarmup:warmupDelay
                    withCallbackBlock:^(NSURL *imageURL, NSError *error) {

                        if(error)
                        {
                            [weakSelf postNotification:@"There was a problem taking that shot :(" withActionBoolean:false];
                        } else {
                            [weakSelf postNotification:@"Well, Look at you!" withActionBoolean:true];
                        }
                    }]; // end of callback Block
}

- (NSURL *)NSURLfromPath:(NSString *)path andDate:(NSDate *)now{

    NSDateFormatter *dateFormatter;
    dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss.SSS";

    NSString *nowstr = [dateFormatter stringFromDate:now];

    NSString *pathAndFilename = [NSString stringWithFormat:@"%@%@%@", path, nowstr, @".gif"];

    return [NSURL fileURLWithPath:pathAndFilename isDirectory:NO];
}


- (void) takeGif
{
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];
    // create directory if it doesnt exist
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    //check error
    if(error){
        [self postNotification:@"There was a problem taking that shot :(" withActionBoolean:false];
        return;
    }

    NSString *fileName = [NSString stringWithFormat:@"AVRecorder_%@.mov", [[NSProcessInfo processInfo] globallyUniqueString]];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
//    NSLog(@"%@", fileName);

    typeof(self) __weak weakSelf = self;
    AVRecorderDocument *recorder = [AVRecorderDocument new];
    [recorder recordToURL:fileURL withLength:[NSNumber numberWithInt:2] withCallbackBlock:^(NSError *recordError) {

//        NSLog(@"recordToURL Finished: %@", recordError);

        if (recordError != nil && [[[recordError userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey] boolValue] == NO)
        {
            [weakSelf postNotification:@"There was a problem taking that shot :(" withActionBoolean:false];
        } else
        {
//            NSLog(@"generating gif");

            NSNumber *delayTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-frame-delay"];
            NSNumber *frameCount = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-frame-count"];
            NSNumber *loopCount = [[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-gif-loop-count"];

//            NSLog(@"%f, %d, %d", delayTime.floatValue, frameCount.intValue, loopCount.intValue);

            [NSGIF createGIFfromURL:fileURL withFrameCount:frameCount.intValue delayTime:delayTime.floatValue loopCount:loopCount.intValue completion:^(NSURL *tempGIFURL) {
//                NSLog(@"Finished generating GIF: %@", tempGIFURL);

                NSDate *now = [NSDate date];
                NSURL *GifURL = [self NSURLfromPath:path andDate:now];

//                NSLog(@"Cleaning up and moving");
                [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
                [[NSFileManager defaultManager] moveItemAtURL:tempGIFURL toURL:GifURL error:nil];
//                NSLog(@"Finished moving GIF to : %@", GifURL);
                [weakSelf postNotification:@"Well, Look at you!" withActionBoolean:true];
            }];
        }
    }];
}

-(NSURL*)urlForLast
{
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];
    NSArray *pictures = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:path]
                                                      includingPropertiesForKeys:@[NSURLCreationDateKey]
                                                                         options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                           error:nil];

    NSArray *sortedContent = [pictures sortedArrayUsingComparator:
                              ^(NSURL *file1, NSURL *file2)
                              {
                                  // compare
                                  NSDate *file1Date;
                                  [file1 getResourceValue:&file1Date forKey:NSURLCreationDateKey error:nil];
                                  
                                  NSDate *file2Date;
                                  [file2 getResourceValue:&file2Date forKey:NSURLCreationDateKey error:nil];
                                  
                                  return [file1Date compare: file2Date];
                              }];
    return sortedContent.lastObject;
}

-(void)setPhoto:(NSImage*)backgroundImage
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

- (IBAction)forceActionGif:(id)sender
{
    [self takeGif];
}

-(IBAction)preview:(id)sender
{
    NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfURL:[self urlForLast]];

    if(!backgroundImage){
        backgroundImage = [NSImage imageNamed:@"statusIcon"];
    }

    [self setPhoto:backgroundImage];

    [windowOutlet makeKeyAndOrderFront: self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)preferences:(id)sender {
    [preferencesOutlet makeKeyAndOrderFront: self];
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

    if([sender indexOfSelectedItem] == 1){
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
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[sender indexOfSelectedItem]] forKey:@"memoryio-mode"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)photoDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:@"memoryio-photo-delay"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)warmupDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:@"memoryio-warmup-delay"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)frameCountDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(int)[sender integerValue]] forKey:@"memoryio-gif-frame-count"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)frameDelayDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:[sender floatValue]] forKey:@"memoryio-gif-frame-delay"];
}

//formatting is handled in nib because I cant figure out how to attach it programmatically
- (IBAction)loopCountDidChange:(NSTextField*)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(int)[sender integerValue]] forKey:@"memoryio-gif-loop-count"];
}




#pragma Delegates

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{

    return YES;
}

@end
