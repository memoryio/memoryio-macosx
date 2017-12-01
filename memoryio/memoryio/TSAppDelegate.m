#import "TSAppDelegate.h"

//
//  TSAppDelegate.m
//  TSAppDelegate
//
//  Created by Jacob Rosenthal on 8/22/13.
//  Copyright 2012 Augmentous. All rights reserved.
//
@implementation TSAppDelegate

NotificationManager *notificationManager;
NSStatusItem *statusItem;

#pragma Members that setup during instantiate
- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSViewController *general = [[GeneralPreferencesViewController alloc] init];
        NSViewController *photo = [[PhotoPreferencesViewController alloc] init];
        NSViewController *gif = [[GifPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:general, photo, gif, nil];

        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    }
    return _preferencesWindowController;
}

- (NSWindow *)previewWindow
{
    if (_previewWindow == nil)
    {
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setImageScaling:NSImageScaleProportionallyUpOrDown];

        NSButton *tweetButton = [[NSButton alloc] initWithFrame:NSMakeRect(384, 13, 77, 32)];
        tweetButton.title = @"Tweet";
        [tweetButton setButtonType:NSMomentaryPushButton];
        [tweetButton setBezelStyle:NSRoundedBezelStyle];
        [tweetButton setAction:@selector(tweet:)];
        [tweetButton setTarget:self];
        [imageView addSubview:tweetButton];

        // http://robin.github.io/cocoa/mac/2016/03/28/title-bar-and-toolbar-showcase/
        _previewWindow =  [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 608, 480, 270)
                                                      styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView
                                                        backing: NSBackingStoreBuffered    defer:YES];
        [_previewWindow setTitlebarAppearsTransparent:YES];

        [_previewWindow setMovable:YES];
        [_previewWindow setHasShadow:YES];
        [_previewWindow setReleasedWhenClosed:NO];

        [_previewWindow setAspectRatio:NSMakeSize(480, 270)];
        [_previewWindow setContentView:imageView];
    }
    return _previewWindow;
}

#pragma Setup

- (void)setNSUserDefaults{
    //set startup
    // boolforkey returns NO if key does not exist

    //set mode
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memoryio-mode"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"memoryio-mode"];
    }

    NSString *defaultPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Pictures/memoryIO/"];
    //set location
    if(![[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"]) {
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

- (void) setupMenuBar
{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setHighlightMode:YES];
    [statusItem setEnabled:YES];
    [statusItem setToolTip:@"memoryIO"];
    [statusItem setTarget:self];

    //Sets the images in our NSStatusItem
    [statusItem setImage:[NSImage imageNamed:@"statusIcon"]];

    NSMenu *statusMenu = [NSMenu new];

    NSMenuItem *newItem=[[NSMenuItem alloc]initWithTitle:@"About" action:@selector(aboutAction:) keyEquivalent:@""];
    [statusMenu addItem:newItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    newItem=[[NSMenuItem alloc]initWithTitle:@"View Last" action:@selector(preview:) keyEquivalent:@""];
    [statusMenu addItem:newItem];

    newItem=[[NSMenuItem alloc]initWithTitle:@"Force Photo" action:@selector(forceAction:) keyEquivalent:@""];
    [statusMenu addItem:newItem];

    newItem=[[NSMenuItem alloc]initWithTitle:@"Force Gif" action:@selector(forceActionGif:) keyEquivalent:@""];
    [statusMenu addItem:newItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    newItem=[[NSMenuItem alloc]initWithTitle:@"Preferences" action:@selector(preferencesAction:) keyEquivalent:@""];
    [statusMenu addItem:newItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    newItem=[[NSMenuItem alloc]initWithTitle:@"Quit" action:@selector(quitAction:) keyEquivalent:@""];
    [statusMenu addItem:newItem];

    //put menu in menubar
    [statusItem setMenu:statusMenu];
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

-(NSImage*)getLastImage
{
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:@"memoryio-location"];
    NSArray *pictures = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:path]
                                                      includingPropertiesForKeys:@[NSURLContentModificationDateKey]
                                                                         options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                           error:nil];

    NSArray *sortedContent = [pictures sortedArrayUsingComparator:
                              ^(NSURL *file1, NSURL *file2)
                              {
                                  // compare
                                  NSDate *file1Date;
                                  [file1 getResourceValue:&file1Date forKey:NSURLContentModificationDateKey error:nil];
                                  
                                  NSDate *file2Date;
                                  [file2 getResourceValue:&file2Date forKey:NSURLContentModificationDateKey error:nil];
                                  
                                  return [file1Date compare: file2Date];
                              }];

    NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfURL:sortedContent.lastObject];

    return backgroundImage;
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

-(IBAction)preview:(id __unused)sender
{
//    verbose("preview");
    NSImage *backgroundImage = [self getLastImage];
    if(!backgroundImage){
        backgroundImage = [NSImage imageNamed:@"statusIcon"];
    }
    [[[self previewWindow] contentView] setImage:backgroundImage];
    [[self previewWindow] makeKeyAndOrderFront: nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)preferencesAction:(id)sender
{
    [self.preferencesWindowController showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
}


#pragma Delegates

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{

    return YES;
}

@end
