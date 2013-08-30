//
//  FluxAVCameraSingleton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-30.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <dispatch/dispatch.h>

@interface FluxAVCameraSingleton : NSObject{
    AVCaptureVideoPreviewLayer *previewLayer;
	
    
    AVCaptureDevice *device;
    
    UIImageView*blurView;
    //dispatch_queue_t AVCaptureBackgroundQueue;
    
    

}
@property (nonatomic, strong)AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong)AVCaptureSession *session;
@property (nonatomic, strong)dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong)AVCaptureStillImageOutput *stillImageOutput;


-(void)pauseAVCapture;
- (void)startAVCapture;
- (void)restartAVCapture;

- (void)setSampleBufferDelegate:(id < AVCaptureVideoDataOutputSampleBufferDelegate >)sampleBufferDelegate forViewController:(UIViewController*)VC;

+ (id)sharedCamera;


@end
