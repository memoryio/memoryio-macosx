//
//  ImageSnap.h
//  ImageSnap
//
//  Created by Robert Harder on 9/10/09.
//

#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>
#include "ImageSnap.h"
#import "ExifContainer.h"
#import "NSImage+Exif.h"

#define error(...) fprintf(stderr, __VA_ARGS__)
#define console(...) (!g_quiet && printf(__VA_ARGS__))
#define verbose(...) (g_verbose && !g_quiet && fprintf(stderr, __VA_ARGS__))

static BOOL g_verbose;
static BOOL g_quiet;

FOUNDATION_EXPORT NSString *const VERSION;

@interface ImageSnap : NSObject

/**
 * Returns all attached QTCaptureDevice objects that have video.
 * This includes video-only devices (QTMediaTypeVideo) and
 * audio/video devices (QTMediaTypeMuxed).
 *
 * @return array of video devices
 */
+ (NSArray *)videoDevices;

/**
 * Returns the default QTCaptureDevice object for video
 * or nil if none is found.
 */
+ (AVCaptureDevice *)defaultVideoDevice;

/**
 * Returns the QTCaptureDevice with the given name
 * or nil if the device cannot be found.
 */
+ (AVCaptureDevice *)deviceNamed:(NSString *)name;

+ (void)saveSingleSnapshotFrom:(AVCaptureDevice *)device
                        toPath:(NSString *)path
                    withWarmup:(NSNumber *)warmup
             withCallbackBlock:(void (^)(NSURL *imageURL, NSError *error))callbackBlock;

@end