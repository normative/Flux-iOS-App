//
//  FluxAVCameraSingleton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-30.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMBufferQueue.h>
@protocol FluxCameraDelegate;

@interface FluxAVCameraSingleton : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    int _dataPreview;
    CMBufferQueueRef previewBufferQueue;
}

@property (nonatomic, strong)AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong)AVCaptureSession *session;
@property (nonatomic, strong)dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong)AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong)AVCaptureDevice *device;
@property (nonatomic, assign) id <FluxCameraDelegate> delegate;

- (void)pauseAVCapture;
- (void)startAVCapture;
- (void)stopAVCapture;
+ (id)sharedCamera;

@end

@protocol FluxCameraDelegate <NSObject>
@required
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer;	// This method is always called on the main thread.
@end
