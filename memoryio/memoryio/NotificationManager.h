//
//  NotificationManager.h
//  memoryio
//
//  Created by Jacob Rosenthal on 3/30/16.
//  Copyright © 2016 Augmentous. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>

#include <mach/mach_port.h>
#include <mach/mach_interface.h>
#include <mach/mach_init.h>

#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

@interface NotificationManager : NSObject

@property (nonatomic, copy) void (^notificationBlock)(natural_t messageType, void *messageArgument);

- (void)subscribePowerNotifications;
- (void)unsubscribePowerNotifications;
- (void)subscribeDisplayNotifications;
- (void)unsubscribeDisplayNotifications;

@end
