/*
     File: AVRecorderDocument.m
 Abstract: n/a
  Version: 2.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "AVRecorderDocument.h"
#import <AVFoundation/AVFoundation.h>

@interface AVRecorderDocument () <AVCaptureFileOutputDelegate, AVCaptureFileOutputRecordingDelegate>

// Properties for internal use
@property (retain) AVCaptureDeviceInput *videoDeviceInput;
@property (retain) AVCaptureDeviceInput *audioDeviceInput;
@property (readonly) BOOL selectedVideoDeviceProvidesAudio;
@property (retain) AVCaptureAudioPreviewOutput *audioPreviewOutput;
@property (retain) AVCaptureMovieFileOutput *movieFileOutput;
@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (assign) NSTimer *audioLevelTimer;
@property (retain) NSArray *observers;

// Methods for internal use
- (void)refreshDevices;

@end

@implementation AVRecorderDocument

@synthesize videoDeviceInput;
@synthesize audioDeviceInput;
@synthesize videoDevices;
@synthesize audioDevices;
@synthesize session;
@synthesize audioPreviewOutput;
@synthesize movieFileOutput;
@synthesize previewLayer;
@synthesize audioLevelTimer;
@synthesize observers;
@synthesize recordingDoneBlock;
@synthesize time;
@synthesize timer;

- (id)init
{
	self = [super init];
	if (self) {
		__weak AVRecorderDocument *weakSelf = self;

		// Capture Notification Observers
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		id runtimeErrorObserver = [notificationCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
																  object:session
																   queue:[NSOperationQueue mainQueue]
															  usingBlock:^(NSNotification *note) {
																  dispatch_async(dispatch_get_main_queue(), ^(void) {
																	  [weakSelf presentError:[[note userInfo] objectForKey:AVCaptureSessionErrorKey]];
																  });
															  }];
		id didStartRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStartRunningNotification
																	 object:session
																	  queue:[NSOperationQueue mainQueue]
																 usingBlock:^(NSNotification *note) {
																	 // NSLog(@"did start running");
																 }];
		id didStopRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStopRunningNotification
																	object:session
																	 queue:[NSOperationQueue mainQueue]
																usingBlock:^(NSNotification *note) {
																	// NSLog(@"did stop running");
																}];
		id deviceWasConnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification
																		object:nil
																		 queue:[NSOperationQueue mainQueue]
																	usingBlock:^(NSNotification *note) {
																		[weakSelf refreshDevices];
																	}];
		id deviceWasDisconnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification
																		   object:nil
																			queue:[NSOperationQueue mainQueue]
																	   usingBlock:^(NSNotification *note) {
																		   [weakSelf refreshDevices];
																	   }];
		observers = [[NSArray alloc] initWithObjects:runtimeErrorObserver, didStartRunningObserver, didStopRunningObserver, deviceWasConnectedObserver, deviceWasDisconnectedObserver, nil];
		
	}
	return self;
}

- (void)dealloc
{
    [timer invalidate];
    
    // Stop the session
    [[self session] stopRunning];
    
    // Set movie file output delegate to nil to avoid a dangling pointer
    [[self movieFileOutput] setDelegate:nil];
    
    // Remove Observers
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    for (id observer in [self observers])
        [notificationCenter removeObserver:observer];
}

- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void  *)contextInfo
{
	// Do nothing
}

#pragma mark - Device selection
- (void)refreshDevices
{
	[self setVideoDevices:[[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] arrayByAddingObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]]];
	[self setAudioDevices:[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]];
	
	[[self session] beginConfiguration];
	
	if (![[self videoDevices] containsObject:[self selectedVideoDevice]])
		[self setSelectedVideoDevice:nil];
	
	if (![[self audioDevices] containsObject:[self selectedAudioDevice]])
		[self setSelectedAudioDevice:nil];
	
	[[self session] commitConfiguration];
}

- (AVCaptureDevice *)selectedVideoDevice
{
	return [videoDeviceInput device];
}

- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
	[[self session] beginConfiguration];
	
	if ([self videoDeviceInput]) {
		// Remove the old device input from the session
		[session removeInput:[self videoDeviceInput]];
		[self setVideoDeviceInput:nil];
	}
	
	if (selectedVideoDevice) {
		NSError *error = nil;
		
		// Create a device input for the device and add it to the session
		AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedVideoDevice error:&error];
		if (newVideoDeviceInput == nil) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[self presentError:error];
			});
		} else {
			if (![selectedVideoDevice supportsAVCaptureSessionPreset:[session sessionPreset]])
				[[self session] setSessionPreset:AVCaptureSessionPresetHigh];
			
			[[self session] addInput:newVideoDeviceInput];
			[self setVideoDeviceInput:newVideoDeviceInput];
		}
	}
	
	// If this video device also provides audio, don't use another audio device
	if ([self selectedVideoDeviceProvidesAudio])
		[self setSelectedAudioDevice:nil];
	
	[[self session] commitConfiguration];
}

- (AVCaptureDevice *)selectedAudioDevice
{
	return [audioDeviceInput device];
}

- (void)setSelectedAudioDevice:(AVCaptureDevice *)selectedAudioDevice
{
	[[self session] beginConfiguration];
	
	if ([self audioDeviceInput]) {
		// Remove the old device input from the session
		[session removeInput:[self audioDeviceInput]];
		[self setAudioDeviceInput:nil];
	}
	
	if (selectedAudioDevice && ![self selectedVideoDeviceProvidesAudio]) {
		NSError *error = nil;
		
		// Create a device input for the device and add it to the session
		AVCaptureDeviceInput *newAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedAudioDevice error:&error];
		if (newAudioDeviceInput == nil) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[self presentError:error];
			});
		} else {
			if (![selectedAudioDevice supportsAVCaptureSessionPreset:[session sessionPreset]])
				[[self session] setSessionPreset:AVCaptureSessionPresetHigh];
			
			[[self session] addInput:newAudioDeviceInput];
			[self setAudioDeviceInput:newAudioDeviceInput];
		}
	}
	
	[[self session] commitConfiguration];
}

#pragma mark - Device Properties


- (BOOL)selectedVideoDeviceProvidesAudio
{
	return ([[self selectedVideoDevice] hasMediaType:AVMediaTypeMuxed] || [[self selectedVideoDevice] hasMediaType:AVMediaTypeAudio]);
}

- (AVCaptureDeviceFormat *)videoDeviceFormat
{
	return [[self selectedVideoDevice] activeFormat];
}

- (void)setVideoDeviceFormat:(AVCaptureDeviceFormat *)deviceFormat
{
	NSError *error = nil;
	AVCaptureDevice *videoDevice = [self selectedVideoDevice];
	if ([videoDevice lockForConfiguration:&error]) {
		[videoDevice setActiveFormat:deviceFormat];
		[videoDevice unlockForConfiguration];
	} else {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[self presentError:error];
		});
	}
}


- (AVCaptureDeviceFormat *)audioDeviceFormat
{
	return [[self selectedAudioDevice] activeFormat];
}

- (void)setAudioDeviceFormat:(AVCaptureDeviceFormat *)deviceFormat
{
	NSError *error = nil;
	AVCaptureDevice *audioDevice = [self selectedAudioDevice];
	if ([audioDevice lockForConfiguration:&error]) {
		[audioDevice setActiveFormat:deviceFormat];
		[audioDevice unlockForConfiguration];
	} else {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[self presentError:error];
		});
	}
}

#pragma mark - Recording

- (void)stopRecording
{
    // NSLog(@"stopping recording");
    [[self movieFileOutput] stopRecording];
}

- (void)recordToURL:(NSURL *)fileURL
         withLength:(NSNumber *) length
  withCallbackBlock:(void (^)(NSError *))callbackBlock{

    if([timer isValid]){
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Recording unsucessful.", nil),
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Only one recording session possible at a time.", nil),
                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Wait for previous recording request to finish.", nil)
                                   };
        NSError *error = [NSError errorWithDomain:@"com.mycompany.myapp"
                                             code:-57
                                         userInfo:userInfo];

        callbackBlock(error);
        return;
    }
    
    recordingDoneBlock = callbackBlock;
    time = length;
    session = [[AVCaptureSession alloc] init];
    
    // Attach outputs to session
    movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [movieFileOutput setDelegate:self];
    [session addOutput:movieFileOutput];
    
    audioPreviewOutput = [[AVCaptureAudioPreviewOutput alloc] init];
    [audioPreviewOutput setVolume:0.f];
    [session addOutput:audioPreviewOutput];
    
    // Select devices if any exist
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (videoDevice) {
        [self setSelectedVideoDevice:videoDevice];
        [self setSelectedAudioDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio]];
    } else {
        [self setSelectedVideoDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed]];
    }
    
    [[self session] startRunning];
    
    if(((videoDeviceInput != nil) || (audioDeviceInput != nil))){
        
        [[self movieFileOutput] startRecordingToOutputFileURL:fileURL
                                            recordingDelegate:self];
    }
}

#pragma mark - Delegate methods

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
	// NSLog(@"Did start recording to %f %@", time.doubleValue, [fileURL description]);
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:time.intValue
                                                      target:self
                                                    selector:@selector(stopRecording)
                                                    userInfo:nil repeats:NO];
    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
	// NSLog(@"Did pause recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
	// NSLog(@"Did resume recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections dueToError:(NSError *)error
{
  // NSLog(@"willFinishRecordingToOutputFileAtURL");

	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self presentError:error];
	});
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)recordError
{
    // NSLog(@"didFinishRecordingToOutputFileAtURL");
    // Stop the session
    [[self session] stopRunning];

    // Set movie file output delegate to nil to avoid a dangling pointer
    [[self movieFileOutput] setDelegate:nil];

    recordingDoneBlock(recordError);
}

- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput
{
    // We don't require frame accurate start when we start a recording. If we answer YES, the capture output
    // applies outputSettings immediately when the session starts previewing, resulting in higher CPU usage
    // and shorter battery life.
    return NO;
}

@end
