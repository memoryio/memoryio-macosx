#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

//
//  ImageSnap.h
//  ImageSnap
//
//  Created by Robert Harder on 9/10/09.
//  Extended by Jacob Rosenthal on 8/22/13.
//
@interface ImageSnap : NSObject {
    
    QTCaptureSession                    *mCaptureSession;
    QTCaptureDeviceInput                *mCaptureDeviceInput;
    QTCaptureDecompressedVideoOutput    *mCaptureDecompressedVideoOutput;
    CVImageBufferRef                    mCurrentImageBuffer;
}

/**
 * Returns all attached QTCaptureDevice objects that have video.
 * This includes video-only devices (QTMediaTypeVideo) and
 * audio/video devices (QTMediaTypeMuxed).
 *
 * @return autoreleased array of video devices
 */
+ (NSArray *)videoDevices;

/**
 * Returns the default QTCaptureDevice object for video
 * or nil if none is found.
 */
+ (QTCaptureDevice *)defaultVideoDevice;

/**
 * Returns the QTCaptureDevice with the given name
 * or nil if the device cannot be found.
 */
+ (QTCaptureDevice *)deviceNamed:(NSString *)name;

/**
 * Primary one-stop-shopping message for capturing an image.
 * Activates the video source, saves a frame, stops the source,
 * and saves the file.
 */
+ (NSURL *)saveSingleSnapshotFrom:(QTCaptureDevice *)device toFile:(NSString *)path
                    withWarmup:(NSNumber *)warmup;

- (BOOL)startSession:(QTCaptureDevice *)device;
- (void)stopSession;

@end
