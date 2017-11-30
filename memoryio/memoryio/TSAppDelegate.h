#import <Cocoa/Cocoa.h>
#import "ServiceManagement/SMLoginItem.h"

#import "ImageSnap.h"
#import "NSGIF.h"
#import "AVRecorderDocument.h"
#import "NotificationManager.h"
//
//  TSAppDelegate.h
//  TSAppDelegate
//
//  Created by Jacob Rosenthal on 8/22/13.
//  Copyright 2012 Augmentous. All rights reserved.
//
@interface TSAppDelegate : NSObject <NSUserNotificationCenterDelegate, NSSharingServiceDelegate, NSApplicationDelegate> {
    NSWindow *_previewWindow;
}

@property IBOutlet NSMenu *statusMenu;
@property IBOutlet NSButton *startupButton;
@property (weak) IBOutlet NSPopUpButton *locationPull;
@property (weak) IBOutlet NSPopUpButton *modePull;
@property (weak) IBOutlet NSTextField *photoDelayText;
@property (weak) IBOutlet NSTextField *warmupDelayText;
@property (weak) IBOutlet NSTextField *frameCountText;
@property (weak) IBOutlet NSTextField *frameDelayText;
@property (weak) IBOutlet NSTextField *loopCountText;
@property (nonatomic, readonly) NSWindow *previewWindow;

- (IBAction)quitAction:(id)sender;
- (IBAction)forceAction:(id)sender;
- (IBAction)forceActionGif:(id)sender;
- (IBAction)aboutAction:(id)sender;
- (IBAction)startupAction:(id)sender;
- (IBAction)preview:(id)sender;
- (IBAction)tweet:(id)sender;

@end
