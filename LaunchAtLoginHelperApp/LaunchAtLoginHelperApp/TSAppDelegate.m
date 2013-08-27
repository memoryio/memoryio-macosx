//
//  TSAppDelegate.m
//  LaunchAtLoginHelperApp
//
//  Created by Tim Schröder on 02.07.12.
//  Copyright (c) 2012 Tim Schröder. All rights reserved.
//

#import "TSAppDelegate.h"

@implementation TSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Check if main app is already running; if yes, do nothing and terminate helper app
    BOOL alreadyRunning = NO;
    BOOL isActive = NO; // my modification
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        
        if ([[app bundleIdentifier] isEqualToString:@"com.augmentous.memoryio"]) {
            alreadyRunning = YES;
            isActive = [app isActive]; // my modification
        }
    }
    
    if (!alreadyRunning || !isActive) { // my modification
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSArray *p = [path pathComponents];
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:p];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents addObject:@"MacOS"];
        [pathComponents addObject:@"memoryio"];
        NSString *newPath = [NSString pathWithComponents:pathComponents];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:@"launchAtLogin"], NSWorkspaceLaunchConfigurationArguments, nil];
        [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:newPath]
                                                      options:NSWorkspaceLaunchWithoutActivation
                                                configuration:dict
                                                        error:nil];
    }
    [NSApp terminate:nil];
}

@end
