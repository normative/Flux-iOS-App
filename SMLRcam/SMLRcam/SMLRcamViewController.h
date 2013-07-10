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

@interface SMLRcamViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate>
{    
    IBOutlet UISegmentedControl *camerasControl;
    IBOutlet UIView *previewView;
    
	AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
	BOOL detectFaces;
	dispatch_queue_t videoDataOutputQueue;
	AVCaptureStillImageOutput *stillImageOutput;
	UIView *flashView;
	UIImage *square;
	BOOL isUsingFrontFacingCamera;
	CIDetector *faceDetector;
	CGFloat beginGestureScale;
	CGFloat effectiveScale;
    
    CLLocationManager *locationManager;
    NSMutableArray *locationMeasurements;
    CMMotionManager *motionManager;

}

- (IBAction)takePicture:(id)sender;
- (IBAction)switchCameras:(id)sender;
- (IBAction)toggleFaceDetection:(id)sender;
- (IBAction)handlePinchGesture:(UIGestureRecognizer *)sender;

- (void) stopUpdatingLocation;

@end
