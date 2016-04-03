//
//  ImageSnap.m
//  ImageSnap
//
//  Created by Robert Harder on 9/10/09.
//

#import "ImageSnap.h"

static BOOL g_verbose = NO;
static BOOL g_quiet = NO;

NSString *const VERSION = @"0.2.5";

@interface ImageSnap()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *captureStillImageOutput;
@property (nonatomic, assign) CVImageBufferRef currentImageBuffer;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

#if OS_OBJECT_HAVE_OBJC_SUPPORT == 1
@property (nonatomic, strong) dispatch_queue_t imageQueue;
#else
@property (nonatomic, assign) dispatch_queue_t imageQueue;
#endif

@end

@implementation ImageSnap


#pragma mark - Public Interface

/**
 * Returns all attached AVCaptureDevice objects that have video.
 * This includes video-only devices (AVMediaTypeVideo) and
 * audio/video devices (AVMediaTypeMuxed).
 *
 * @return array of video devices
 */
+ (NSArray *)videoDevices {
    NSMutableArray *results = [NSMutableArray new];

    [results addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]];
    [results addObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]];

    return results;
}

// Returns the default video device or nil if none found.
+ (AVCaptureDevice *)defaultVideoDevice {

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    if (device == nil) {
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed];
    }

    return device;
}

// Returns the named capture device or nil if not found.
+ (AVCaptureDevice *)deviceNamed:(NSString *)name {
    AVCaptureDevice *result;

    NSArray *devices = [ImageSnap videoDevices];
    for (AVCaptureDevice *device in devices) {
        if ([name isEqualToString:device.localizedName]) {
            result = device;
        }
    }

    return result;
}

+ (void)saveSingleSnapshotFrom:(AVCaptureDevice *)device
                        toPath:(NSString *)path
                    withWarmup:(NSNumber *)warmup
             withCallbackBlock:(void (^)(NSURL *imageURL, NSError *error))callbackBlock{

    verbose("Starting device...");

    NSError *error;
    __block AVCaptureSession *captureSession;
    __block AVCaptureDeviceInput *captureDeviceInput;
    __block AVCaptureStillImageOutput *captureStillImageOutput;
    AVCaptureConnection *videoConnection;

    // Create the capture session
    captureSession = [AVCaptureSession new];
    if ([captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    }

    // Create input object from the device
    captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!error && [captureSession canAddInput:captureDeviceInput]) {
        [captureSession addInput:captureDeviceInput];
    }

    captureStillImageOutput = [AVCaptureStillImageOutput new];
    captureStillImageOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG};

    if ([captureSession canAddOutput:captureStillImageOutput]) {
        [captureSession addOutput:captureStillImageOutput];
    }

    for (AVCaptureConnection *connection in captureStillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([port.mediaType isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }

    if ([captureSession canAddOutput:captureStillImageOutput]) {
        [captureSession addOutput:captureStillImageOutput];
    }

    [captureSession startRunning];

    verbose("Device started.\n");

    if (warmup == nil) {
        // Skip warmup
        verbose("Skipping warmup period.\n");
    } else {
        double delay = warmup.doubleValue;
        verbose("Delaying %.2lf seconds for warmup...\n", delay);
        [NSThread sleepForTimeInterval:[warmup floatValue]];
        verbose("Warmup complete.\n");
    }

    [captureStillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:
     ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {

         NSDateFormatter *dateFormatter;
         dateFormatter = [NSDateFormatter new];
         dateFormatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss.SSS";

         NSDate *now = [NSDate date];
         NSString *nowstr = [dateFormatter stringFromDate:now];

         NSString *pathAndFilename = [NSString stringWithFormat:@"%@%@%@", path, nowstr, @".jpg"];

         NSURL *imageURL = [NSURL fileURLWithPath:pathAndFilename isDirectory:NO];

         NSLog(@"Making exif data");
         ExifContainer *container = [[ExifContainer alloc] init];
         [container addCreationDate:now];
         [container addDigitizedDate:now];

         NSData *rawImageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];

         NSData *imageData = [NSImage getAppendedDataForImageData:rawImageData exif:container];

         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {

             [imageData writeToURL:imageURL atomically:YES];

             verbose("Stopping session...\n" );

             // Make sure we've stopped
             while (captureSession != nil) {
                 verbose("\tCaptureSession != nil\n");

                 verbose("\tStopping CaptureSession...");
                 [captureSession stopRunning];
                 verbose("Done.\n");

                 if ([captureSession isRunning]) {
                     verbose("[captureSession isRunning]");
                     [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                 } else {
                     verbose("\tShutting down 'stopSession(..)'" );

                     captureSession = nil;
                     captureDeviceInput = nil;
                     captureStillImageOutput = nil;
                 }
             }

         });

         verbose("Callback...\n" );
         callbackBlock(imageURL, error);
     }];
}

@end