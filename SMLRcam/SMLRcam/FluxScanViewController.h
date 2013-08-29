//
//  SMLRcamViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMDrawerBarButtonItem.h"
#import "FluxMapViewController.h"
#import "FluxClockSlidingControl.h"
#import "FluxAnnotationsTableViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "FluxLocationServicesSingleton.h"
#import "FluxNetworkServices.h"
#import <CoreMotion/CoreMotion.h>

#import <dispatch/dispatch.h>

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@class FluxRotatingCompassButton;

@interface FluxScanViewController : UIViewController<NetworkServicesDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,UIGestureRecognizerDelegate>{
    
    FluxAnnotationsTableViewController *annotationsFeedView;
    
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    
    AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
	dispatch_queue_t videoDataOutputQueue;
    AVCaptureStillImageOutput *stillImageOutput;
    AVCaptureDevice *device;
    
    UIImageView *gridView;
    NSNumber* camMode; //0 = off, 1 = on, 2 = confirm
    FluxScanImageObject *capturedImageObject;
    UIImage *capturedImage;
    UIView *blackView;
    UIImageView*blurView;
    dispatch_queue_t AVCaptureBackgroundQueue;
    
    UIInterfaceOrientation changeToOrientation;

    __weak IBOutlet UIButton *CameraButton;
    __weak IBOutlet UIView *headerView;
    __weak IBOutlet UILabel *locationLabel;
    __weak IBOutlet UILabel *dateRangeLabel;
    
    __weak IBOutlet FluxRotatingCompassButton *compassBtn;
    
    UIPanGestureRecognizer *panGesture;
    UILongPressGestureRecognizer *longPressGesture;
    NSDateFormatter *dateFormatter;
    float previousYCoord;
    float startXCoord;

    
    FluxLocationServicesSingleton *locationManager;
    CMMotionManager *motionManager;
    FluxNetworkServices * networkServices;
}

@property (nonatomic, strong) NSMutableDictionary * imageDict;
@property (nonatomic, weak) IBOutlet UIButton * leftDrawerButton;
@property (nonatomic, weak) IBOutlet UIButton * rightDriawerButton;
@property (strong, nonatomic) IBOutlet UIView *drawerContainerView;
@property (weak, nonatomic) IBOutlet UIView *cameraApproveContainerView;
@property (nonatomic, strong) FluxClockSlidingControl*thumbView;

- (void)didUpdatePlacemark:(NSNotification *)notification;
- (void)didUpdateHeading:(NSNotification *)notification;
- (void)didUpdateLocation:(NSNotification *)notification;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)showRightDrawer:(id)sender;
- (IBAction)showAnnotationsView:(id)sender;
- (IBAction)cameraButtonAction:(id)sender;
- (IBAction)approveImageAction:(id)sender;
- (IBAction)retakeImageAction:(id)sender;

- (void)setupAVCapture;
- (void)setupNetworkServices;
- (void)takePicture;
- (UIImage*)blurImage:(UIImage*)img;
-(void)restartAVCaptureWithBlur:(BOOL)blur;
-(void)pauseAVCapture;


- (void)setupCameraView;
- (void)setUIForCamMode:(NSNumber*)mode;
- (void)annotationsViewDidPop:(NSNotification *)notification;

- (void)setupLayer;
- (void)setupContext;

- (void)setupGestureHandlers;
- (void)handlePanGesture:(UIPanGestureRecognizer *) sender;
- (void)handleLongPress:(UILongPressGestureRecognizer *) sender;
- (void)setThumbViewDate:(float)yCoord;

@end
