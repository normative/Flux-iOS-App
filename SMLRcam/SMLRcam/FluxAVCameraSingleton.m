//
//  FluxAVCameraSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-30.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxAVCameraSingleton.h"
#import <GLKit/GLKit.h>

@implementation FluxAVCameraSingleton

static FluxAVCameraSingleton *sharedFluxAVCameraSingleton = nil;
static dispatch_once_t sharedFluxAVCameraSingleton_onceToken = 0;

+ (id)sharedCamera {
    dispatch_once(&sharedFluxAVCameraSingleton_onceToken, ^{
        sharedFluxAVCameraSingleton = [[FluxAVCameraSingleton alloc] init];
    });
    return sharedFluxAVCameraSingleton;
}

- (id)init {
    if (self = [super init]) {
        
        NSError *error = nil;
        
        _dataPreview = 0;
        self.session = [AVCaptureSession new];
        [self.session setSessionPreset:AVCaptureSessionPresetHigh]; // full resolution photo...
        
        // Select a video device, make an input
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        //set autofocus
        BOOL locked = [self.device lockForConfiguration:nil];
        if (locked)
        {
            if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            }
            [self.device unlockForConfiguration];
        }
        
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        
        if (error == nil)
        {
            if ( [self.session canAddInput:deviceInput] )
                [self.session addInput:deviceInput];
            
            // Make a still image output
            self.stillImageOutput = [AVCaptureStillImageOutput new];
            if ( [self.session canAddOutput:self.stillImageOutput] )
                [self.session addOutput:self.stillImageOutput];
            
            // Make a video data output
            self.videoDataOutput = [AVCaptureVideoDataOutput new];
            
            // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
            NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                               [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
            [self.videoDataOutput setVideoSettings:rgbOutputSettings];
            [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
            
            // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
            // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
            // see the header doc for setSampleBufferDelegate:queue: for more information
            self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
            [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
            
            if ([self.session canAddOutput:self.videoDataOutput]){
                [self.session addOutput:self.videoDataOutput];
            }
            [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
            
            [self startAVCapture];
        }
        
        //[session release];
        
        if (error)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
            [alertView show];
            //[alertView release];
            [self pauseAVCapture];
        }
        
    }
    return self;
    
}

- (void)dealloc
{
    [self stopAVCapture];
}

-(void)pauseAVCapture
{
    if (self.session !=nil && [self.session isRunning])
    {
        [self.session stopRunning];
    }
}

- (void)startAVCapture
{
    if (self.session !=nil  && ![self.session isRunning])
    {
        [self.session startRunning];
    }
}

-(void)stopAVCapture
{
    for(AVCaptureInput *input in self.session.inputs)
    {
        [self.session removeInput:input];
    }
    
    for(AVCaptureOutput *output in self.session.outputs)
    {
        [self.session removeOutput:output];
    }
    
    if (self.session !=nil && [self.session isRunning])
    {
        [self.session stopRunning];
    }
    
    self.session = nil;
    
    sharedFluxAVCameraSingleton = nil;
    sharedFluxAVCameraSingleton_onceToken = 0;
}

#pragma mark Capture



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    if (!_dataPreview) {
//       return;
//    }
//
//    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
//
//    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    // Enqueue it for preview.  This is a shallow queue, so if image processing is taking too long,
    // we'll drop this frame for preview (this keeps preview latency low).
    OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, sampleBuffer);
    if ( !err ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
            if (sbuf) {
                CVImageBufferRef pixBuf = CMSampleBufferGetImageBuffer(sbuf);
                [self.delegate pixelBufferReadyForDisplay:pixBuf];
                CFRelease(sbuf);
            }
        });
	}
}


- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
{
	// Don't make OpenGLES calls while in the background.
	if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
		//[oglView displayPixelBuffer:pixelBuffer];
        NSLog(@"buffer");
}

//- (void)setSampleBufferDelegate:(id < AVCaptureVideoDataOutputSampleBufferDelegate >)sampleBufferDelegate forViewController:(UIViewController *)VC {
//    if ([sampleBufferDelegate isKindOfClass:[GLKViewController class]]) {
//        [self.videoDataOutput setSampleBufferDelegate:sampleBufferDelegate queue:dispatch_get_main_queue()];
//    }
//    else{
//        [self.videoDataOutput setSampleBufferDelegate:sampleBufferDelegate queue:self.videoDataOutputQueue];
//    }    
//}

@end
