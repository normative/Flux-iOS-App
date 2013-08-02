//
//  SMLRcamCameraViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-29.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#import "FLuxImageAnnotationViewController.h"

@interface SMLRcamCameraViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate>{
    AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
	dispatch_queue_t videoDataOutputQueue;
	AVCaptureStillImageOutput *stillImageOutput;
	UIView *flashView;
	BOOL isUsingFrontFacingCamera;
	CGFloat beginGestureScale;
	CGFloat effectiveScale;
    
    AVCaptureDevice *device;
    NSTimer         *updateTimer;
    
    CLLocationManager *locationManager;
    NSMutableArray *locationMeasurements;
    CMMotionManager *motionManager;
    
    UIImage *capturedImage;
    
    
    __weak IBOutlet UIToolbar *imageToolbar;
    __weak IBOutlet UIButton *cameraButton;
}
- (IBAction)CloseCamera:(id)sender;
- (IBAction)TakePicture:(id)sender;
- (IBAction)RetakePictureAction:(id)sender;
- (IBAction)AcceptPictureAction:(id)sender;

-(void)pauseAVCapture;
-(void)restartAVCapture;

@end
