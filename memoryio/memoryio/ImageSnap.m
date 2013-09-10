#import <Foundation/Foundation.h>
#import "ImageSnap.h"
#import <ApplicationServices/ApplicationServices.h>

//
//  ImageSnap.m
//  ImageSnap
//
//  Created by Robert Harder on 9/10/09.
//  Extended by Jacob Rosenthal on 8/22/13.
//
@implementation ImageSnap

- (void)dealloc{
	
    CVBufferRelease(mCurrentImageBuffer);
    
}

- (instancetype)init {
    self = [super init]; // or call the designated initalizer
    if (self) {
        mCaptureSession = nil;
        mCaptureDeviceInput = nil;
        mCaptureDecompressedVideoOutput = nil;
        mCurrentImageBuffer = nil;
    }
    
    return self;
}

// Returns an array of video devices attached to this computer.
+ (NSArray *)videoDevices{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:3];
    [results addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
    [results addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
    return results;
}

// Returns the default video device or nil if none found.
+ (QTCaptureDevice *)defaultVideoDevice{
	QTCaptureDevice *device = nil;
    
	device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
	if( device == nil ){
        device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
	}
    return device;
}

// Returns the named capture device or nil if not found.
+ (QTCaptureDevice *)deviceNamed:(NSString *)name{
    QTCaptureDevice *result = nil;
    
    NSArray *devices = [ImageSnap videoDevices];
	for( QTCaptureDevice *device in devices ){
        if ( [name isEqualToString:[device description]] ){
            result = device;
        }   // end if: match
    }   // end for: each device
    
    return result;
}   // end



+ (NSURL *)saveSingleSnapshotFrom:(QTCaptureDevice *)device
                        toFile:(NSString *)path
                    withWarmup:(NSNumber *)warmup{
    
    ImageSnap *snap;
    NSImage *rawImage = nil;
    
    snap = [[ImageSnap alloc] init];            // Instance of this ImageSnap class
    NSLog(@"Starting device...");
    if( [snap startSession:device] ){           // Try starting session
        NSLog(@"Device started.\n");
        
        if( warmup == nil ){
            // Skip warmup
            NSLog(@"Skipping warmup period.\n");
        } else {
            double delay = [warmup doubleValue];
            NSLog(@"Delaying %.2lf seconds for warmup...",delay);
            [NSThread sleepForTimeInterval:[warmup floatValue]];
            NSLog(@"Warmup complete.\n");
        }
        
        rawImage = [snap snapshot];                // Capture a frame
        NSLog(@"Stopping...");
        [snap stopSession];                     // Stop session
        NSLog(@"Stopped.");
    }   // end if: able to start session
    
    NSMutableData *photoDataWithExif = [[NSMutableData alloc] init];
    
    // create the image somehow, load from file, draw into it...
    CGImageSourceRef source;
    
    source = CGImageSourceCreateWithData((__bridge CFDataRef)[rawImage TIFFRepresentation], NULL);
    
    //get all the metadata in the image
    NSDictionary *metadata = (__bridge NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
    
    //make the metadata dictionary mutable so we can add properties to it
    NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
    
    //get existing exif data dictionary
    NSMutableDictionary *EXIFDictionary = [[metadataAsMutable objectForKey:(NSString *)kCGImagePropertyExifDictionary]mutableCopy];
    
    if(!EXIFDictionary) {
        //if the image does not have an EXIF dictionary (not all images do), then create one for us to use
        EXIFDictionary = [NSMutableDictionary dictionary];
    }
    
    NSDate *today = [NSDate date];
    
    NSString *dateString = [today descriptionWithCalendarFormat:nil timeZone:nil locale:nil];
    
    NSArray *chunks = [dateString componentsSeparatedByString: @" "];
    NSString *filename = [chunks componentsJoinedByString:@"_"];
    
    //set DateTimeOriginal exif data
    [EXIFDictionary setValue:dateString forKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
    
    //set DateCreated exif data
    [EXIFDictionary setValue:dateString forKey:(NSString *)kCGImagePropertyExifDateTimeDigitized];
    
    //add our modified EXIF data back into the image’s metadata
    [metadataAsMutable setObject:EXIFDictionary forKey:(NSString *)kCGImagePropertyExifDictionary];
    
    //add compression in
    [metadataAsMutable setObject:[NSNumber numberWithFloat:.9] forKey:(NSString *)kCGImageDestinationLossyCompressionQuality];
    
    CFStringRef UTI = kUTTypeJPEG; //this is the type of image (e.g., public.jpeg)
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)photoDataWithExif,UTI,1,NULL);
    
    if(!destination) {
        NSLog(@"***Could not create image destination ***");
        return NULL;
    }
    
    //add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
    CGImageDestinationAddImageFromSource(destination,source,0, (__bridge CFDictionaryRef) metadataAsMutable);
    
    //tell the destination to write the image data and metadata into our data object.
    if(!CGImageDestinationFinalize(destination)) {
        NSLog(@"***Could not create data from image destination ***");
        return NULL;
    }
    
    //cleanup
    CFRelease(destination);
    CFRelease(source);
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSLog(@"Creating folder");
    [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *pathAndFilename = [NSString stringWithFormat:@"%@%@%@", path, filename, @".jpg"];

    NSURL *imageURL = [NSURL fileURLWithPath:pathAndFilename isDirectory:NO];
    
    Boolean result = [photoDataWithExif writeToURL:imageURL atomically:NO];
    
    if(result){
        return imageURL;
    }else{
        return NULL;
    }
    
}   // end

/**
 * Returns current snapshot or nil if there is a problem
 * or session is not started.
 */
- (NSImage *)snapshot{
    NSLog(@"Taking snapshot...\n");
	
    CVImageBufferRef frame = nil;               // Hold frame we find
    while( frame == nil ){                      // While waiting for a frame
		
		NSLog(@"\tEntering synchronized block to see if frame is captured yet...");
        @synchronized(self){                    // Lock since capture is on another thread
            frame = mCurrentImageBuffer;        // Hold current frame
            CVBufferRetain(frame);              // Retain it (OK if nil)
        }   // end sync: self
		NSLog(@"Done.\n" );
		
        if( frame == nil ){                     // Still no frame? Wait a little while.
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 0.1]];
        }   // end if: still nothing, wait
		
    }   // end while: no frame yet
    
    // Convert frame to an NSImage
    NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:frame]];
    NSImage *image = [[NSImage alloc] initWithSize:[imageRep size]];
    [image addRepresentation:imageRep];
	NSLog(@"Snapshot taken.\n" );
    
    return image;
}

/**
 * Blocks until session is stopped.
 */
- (void)stopSession{
	NSLog(@"Stopping session...\n" );
    
    // Make sure we've stopped
    while( mCaptureSession != nil ){
		NSLog(@"\tCaptureSession != nil\n");
        
		NSLog(@"\tStopping CaptureSession...");
        [mCaptureSession stopRunning];
		NSLog(@"Done.\n");
        
        if( [mCaptureSession isRunning] ){
			NSLog(@"[mCaptureSession isRunning]");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 0.1]];
        }else {
            NSLog(@"\tShutting down 'stopSession(..)'" );
            
            mCaptureSession = nil;
            mCaptureDeviceInput = nil;
            mCaptureDecompressedVideoOutput = nil;
        }   // end if: stopped
        
    }   // end while: not stopped
}

/**
 * Begins the capture session. Frames begin coming in.
 */
- (BOOL)startSession:(QTCaptureDevice *)device{
	
	NSLog(@"Starting capture session...\n" );
	
    if( device == nil ) {
		NSLog(@"\tCannot start session: no device provided.\n" );
		return NO;
	}
    
    NSError *error = nil;
    
    // If we've already started with this device, return
    if( [device isEqual:[mCaptureDeviceInput device]] &&
       mCaptureSession != nil &&
       [mCaptureSession isRunning] ){
        return YES;
    }   // end if: already running
	
    else if( mCaptureSession != nil ){
		NSLog(@"\tStopping previous session.\n" );
        [self stopSession];
    }   // end if: else stop session
    
	
	// Create the capture session
	NSLog(@"\tCreating QTCaptureSession..." );
    mCaptureSession = [[QTCaptureSession alloc] init];
	NSLog(@"Done.\n");
	if( ![device open:&error] ){
		NSLog( @"\tCould not create capture session.\n" );
        mCaptureSession = nil;
		return NO;
	}
    
	
	// Create input object from the device
	NSLog(@"\tCreating QTCaptureDeviceInput with %s...", [[device description] UTF8String] );
	mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
	NSLog(@"Done.\n");
	if (![mCaptureSession addInput:mCaptureDeviceInput error:&error]) {
		NSLog( @"\tCould not convert device to input device.\n");
        mCaptureSession = nil;
        mCaptureDeviceInput = nil;
		return NO;
	}
    
	
	// Decompressed video output
	NSLog(@"\tCreating QTCaptureDecompressedVideoOutput...");
	mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
	[mCaptureDecompressedVideoOutput setDelegate:self];
	NSLog(@"Done.\n" );
	if (![mCaptureSession addOutput:mCaptureDecompressedVideoOutput error:&error]) {
		NSLog( @"\tCould not create decompressed output.\n");
        mCaptureSession = nil;
        mCaptureDeviceInput = nil;
        mCaptureDecompressedVideoOutput = nil;
		return NO;
	}
    
    // Clear old image?
	NSLog(@"\tEntering synchronized block to clear memory...");
    @synchronized(self){
        if( mCurrentImageBuffer != nil ){
            CVBufferRelease(mCurrentImageBuffer);
            mCurrentImageBuffer = nil;
        }   // end if: clear old image
    }   // end sync: self
	NSLog(@"Done.\n");
    
	[mCaptureSession startRunning];
	NSLog(@"Session started.\n");
    
    return YES;
}   // end startSession

// This delegate method is called whenever the QTCaptureDecompressedVideoOutput receives a frame
- (void)captureOutput:(QTCaptureOutput *)captureOutput
  didOutputVideoFrame:(CVImageBufferRef)videoFrame
     withSampleBuffer:(QTSampleBuffer *)sampleBuffer
       fromConnection:(QTCaptureConnection *)connection
{
	NSLog(@"." );
    if (videoFrame == nil ) {
		NSLog(@"'nil' Frame captured.\n" );
        return;
    }
    
    // Swap out old frame for new one
    CVImageBufferRef imageBufferToRelease;
    CVBufferRetain(videoFrame);
	
    @synchronized(self){
        imageBufferToRelease = mCurrentImageBuffer;
        mCurrentImageBuffer = videoFrame;
    }   // end sync
    CVBufferRelease(imageBufferToRelease);
    
}

@end