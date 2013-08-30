//
//  FluxAVCameraSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-30.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxAVCameraSingleton.h"
#import <GLKit/GLKit.h>

@implementation FluxAVCameraSingleton

+ (id)sharedCamera {
    static FluxAVCameraSingleton *sharedFluxAVCameraSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFluxAVCameraSingleton = [[self alloc] init];
    });
    return sharedFluxAVCameraSingleton;
}

- (id)init {
    if (self = [super init]) {
        
        NSError *error = nil;
        
        self.session = [AVCaptureSession new];
        [self.session setSessionPreset:AVCaptureSessionPresetHigh]; // full resolution photo...
        
        // Select a video device, make an input
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        //set autofocus
        BOOL locked = [device lockForConfiguration:nil];
        if (locked)
        {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [device unlockForConfiguration];
        }
        
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        
        if (error == nil)
        {
            if ( [self.session canAddInput:deviceInput] )
                [self.session addInput:deviceInput];
            
            // Make a still image output
            self.stillImageOutput = [AVCaptureStillImageOutput new];
            //[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
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
            
            if ([self.session canAddOutput:self.videoDataOutput]){
                [self.session addOutput:self.videoDataOutput];
            }
            [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
            [self.session startRunning];
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


-(void)pauseAVCapture
{
    AVCaptureSession * currentSession  = previewLayer.session;
    if (currentSession !=nil && [currentSession isRunning])
    {
        [currentSession stopRunning];
    }
}

- (void)restartAVCapture{
//    dispatch_async(AVCaptureBackgroundQueue, ^{
//        //start AVCapture
//        AVCaptureSession * currentSession  = previewLayer.session;
//        if (currentSession !=nil  && ![currentSession isRunning])
//        {
//            [currentSession startRunning];
//        }
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            //completion callback
//                [UIView animateWithDuration:0.2 animations:^{
//                    [blurView setAlpha:0.0];
//                    //[gridView setAlpha:1.0];
//                    //[CameraButton setAlpha:1.0];
//                }completion:^(BOOL finished){
//                    [blurView setHidden:YES];
//                }];
//        });
//    });
    AVCaptureSession * currentSession  = previewLayer.session;
    if (currentSession !=nil  && ![currentSession isRunning])
    {
        [currentSession startRunning];
    }
}

- (void)setSampleBufferDelegate:(id < AVCaptureVideoDataOutputSampleBufferDelegate >)sampleBufferDelegate forViewController:(UIViewController *)VC {
    if ([sampleBufferDelegate isKindOfClass:[GLKViewController class]]) {
        [self.videoDataOutput setSampleBufferDelegate:sampleBufferDelegate queue:dispatch_get_main_queue()];
    }
    else{
        [self.videoDataOutput setSampleBufferDelegate:sampleBufferDelegate queue:self.videoDataOutputQueue];
    }    
}


@end
