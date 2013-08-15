//
//  SMLRcamCameraViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-29.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import "FluxLocationServicesSingleton.h"
#import "FluxScanImageObject.h"

#import "FluxImageAnnotationViewController.h"

@interface FluxCameraViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, LocationServicesSingletonDelegate>{
    
    //AV Capture
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
    
    //location + motion
    FluxLocationServicesSingleton *locationManager;
    CMMotionManager *motionManager;
    
    //captured Data
    FluxScanImageObject *capturedImageObject;
    UIImage *capturedImage;
    NSMutableDictionary *imgMetadata;
    NSMutableData *imgData;
    NSString *timestampString;
    NSDate*theDate;
    
    UIImageView *gridView;
    
    //Test
    __weak IBOutlet UILabel *latitudeLabel;
    __weak IBOutlet UILabel *longitudeLabel;
    __weak IBOutlet UILabel *xLabel;
    __weak IBOutlet UILabel *yLabel;
    __weak IBOutlet UILabel *zLabel;
    NSTimer *testTimer;
    
    __weak IBOutlet UIButton *retakeButton;
    __weak IBOutlet UIButton *useButton;
    
    __weak IBOutlet UIButton *cameraButton;
}
- (IBAction)CloseCamera:(id)sender;
- (IBAction)TakePicture:(id)sender;
- (IBAction)RetakePictureAction:(id)sender;
- (IBAction)ConfirmImage:(id)sender;

- (void)setupAVCapture;
- (void)pauseAVCapture;
- (void)restartAVCapture;
- (void)AddGridlinesToView;

- (void)setupLocationManager;
- (void)startUpdatingLocationAndHeading;
- (void)stopUpdatingLocationAndHeading;

- (void)startDeviceMotion;
- (void)stopDeviceMotion;

- (void)UpdateMotionLabels:(NSTimer*)timer;

//utilities
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message;
static inline NSString *NSStringFromUIInterfaceOrientation(UIInterfaceOrientation orientation);





@end
