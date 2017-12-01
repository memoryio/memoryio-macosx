//
//  main.m
//  memoryio
//
//  Created by Jacob Rosenthal on 8/22/13.
//  Copyright 2012 Augmentous. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TSAppDelegate.h"

int main(int argc, char *argv[])
{
    //https://lapcatsoftware.com/articles/working-without-a-nib-part-10.html
    TSAppDelegate *delegate = [TSAppDelegate new];
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setDelegate:delegate];
        //        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
        return 0;
    }
}

