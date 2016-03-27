#import <Cocoa/Cocoa.h>
#import "ImageSnap.h"

//
//  TSAppDelegate.h
//  TSAppDelegate
//
//  Created by Jacob Rosenthal on 8/22/13.
//  Copyright 2012 Augmentous. All rights reserved.
//
@interface TSAppDelegate : NSObject <NSUserNotificationCenterDelegate, NSSharingServiceDelegate, NSApplicationDelegate>

@property IBOutlet NSMenu *statusMenu;
@property IBOutlet NSMenuItem *startupMenuItem;
@property (weak) IBOutlet NSWindow *windowOutlet;
@property (weak) IBOutlet NSImageView *previewImage;

@property NSStatusItem *statusItem;
@property NSImage *statusImage;

@property io_connect_t  root_port;
@property IONotificationPortRef  notifyPortRef;
@property io_object_t            notifierObject;

@property io_service_t		displayWrangler;
@property IONotificationPortRef  notificationPort;
@property io_object_t     notifier;

- (IBAction)quitAction:(id)sender;
- (IBAction)forceAction:(id)sender;
- (IBAction)aboutAction:(id)sender;
- (IBAction)startupAction:(id)sender;
- (IBAction)preview:(id)sender;
- (IBAction)tweet:(id)sender;

@end
