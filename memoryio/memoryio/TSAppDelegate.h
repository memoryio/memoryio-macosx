#import <Cocoa/Cocoa.h>
#import "ImageSnap.h"
#import "NSGIF.h"
#import "AVRecorderDocument.h"
#import "NotificationManager.h"

#import "MASPreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"
#import "PhotoPreferencesViewController.h"
#import "GifPreferencesViewController.h"


//
//  TSAppDelegate.h
//  TSAppDelegate
//
//  Created by Jacob Rosenthal on 8/22/13.
//  Copyright 2012 Augmentous. All rights reserved.
//
@interface TSAppDelegate : NSObject <NSUserNotificationCenterDelegate, NSSharingServiceDelegate, NSApplicationDelegate> {
    NSWindow *_previewWindow;
    NSWindowController *_preferencesWindowController;
}

@property (nonatomic, readonly) NSWindow *previewWindow;
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;

@end
