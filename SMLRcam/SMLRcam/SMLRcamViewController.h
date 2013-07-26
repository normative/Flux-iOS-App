//
//  SMLRcamViewController.h
//  SMLRcam
//
//  Created by Denis Delorme on 7/4/13.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#import "PassthroughView.h"

@interface SMLRcamViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate, PassthroughViewDelegate>
{    
    IBOutlet UISegmentedControl *camerasControl;
    IBOutlet UIView *cameraView;
    PassthroughView * passthroughView;
    
	AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
//	BOOL detectFaces;
	dispatch_queue_t videoDataOutputQueue;
	AVCaptureStillImageOutput *stillImageOutput;
	UIView *flashView;
//	UIImage *square;
	BOOL isUsingFrontFacingCamera;
//	CIDetector *faceDetector;
	CGFloat beginGestureScale;
	CGFloat effectiveScale;
    
    CLLocationManager *locationManager;
    NSMutableArray *locationMeasurements;
    CMMotionManager *motionManager;

    __weak IBOutlet UIButton *CameraButton;
}

- (IBAction)handlePinchGesture:(UIGestureRecognizer *)sender;
- (IBAction)closeCameraAction:(id)sender;

- (void)stopUpdatingLocation;
- (void)setFocusMode:(AVCaptureFocusMode)mode;
- (void)setupAVCapture;
- (void)captureImage;

@end
