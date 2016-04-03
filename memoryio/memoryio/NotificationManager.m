//
//  NotificationManager.m
//  memoryio
//
//  Created by Jacob Rosenthal on 3/30/16.
//  Copyright © 2016 Augmentous. All rights reserved.
//

#import "NotificationManager.h"

@implementation NotificationManager

@synthesize notificationBlock;

io_connect_t  root_port;
IONotificationPortRef  notifyPortRef;
io_object_t            notifierObject;

io_service_t		displayWrangler;
IONotificationPortRef  notificationPort;
io_object_t     notifier;

- (void)dealloc {
    [self unsubscribePowerNotifications];
    [self unsubscribeDisplayNotifications];
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
        case kIOMessageSystemWillSleep:
            IOAllowPowerChange(root_port,(long)messageArgument);
            break;
        case kIOMessageCanSystemSleep:
            IOAllowPowerChange(root_port,(long)messageArgument);
            break;
    }
    notificationBlock(messageType, messageArgument);
    
}

// mainly for when the system goes to sleep and wakes up
void powerCallback( void *context, io_service_t service, natural_t messageType, void *messageArgument )
{
    [(__bridge NotificationManager *)context powerMessageReceived: messageType withArgument: messageArgument];
}

// mainly for when the display goesto sleep and wakes up
void displayCallback (void *context, io_service_t service, natural_t messageType, void *messageArgument)
{
    [(__bridge NotificationManager *)context powerMessageReceived: messageType withArgument: messageArgument];
}

@end
