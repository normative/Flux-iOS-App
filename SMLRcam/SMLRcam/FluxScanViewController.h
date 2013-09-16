//
//  SMLRcamViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMDrawerBarButtonItem.h"
#import "KTPlaceholderTextView.h"
#import "KTSegmentedButtonControl.h"
#import "FluxClockSlidingControl.h"
#import "FluxCameraButton.h"
#import "FluxCompassView.h"

#import "FluxMapViewController.h"
#include "FluxOpenGLViewController.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxNetworkServices.h"
#import "FluxAVCameraSingleton.h"

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <dispatch/dispatch.h>

#import "GAITrackedViewController.h"


extern NSString* const FluxScanViewDidAcquireNewPicture;
extern NSString* const FluxScanViewDidAcquireNewPictureLocalIDKey;

@class FluxRotatingCompassButton;



@interface FluxScanViewController : GAITrackedViewController<NetworkServicesDelegate,AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, KTPlaceholderTextViewDelegate, KTSegmentedControlDelegate>{
    
    //headerView
    __weak IBOutlet UIView *headerView;
    __weak IBOutlet UILabel *locationLabel;
    __weak IBOutlet UILabel *dateRangeLabel;
    __weak IBOutlet FluxCompassView *radarView;
    
    UITableView*annotationsTableView;
    UIImageView*fakeGalleryView;
    
    //Camera
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureDevice *device;
    dispatch_queue_t AVCaptureBackgroundQueue;
    FluxAVCameraSingleton *cameraManager;
    UIImageView *gridView;
    NSNumber* camMode; //0 = off, 1 = on, 2 = confirm
    FluxScanImageObject *capturedImageObject;
    UIImage *capturedImage;
    UIView *blackView;
    UIImageView*blurView;
    __strong IBOutlet FluxCameraButton *CameraButton;
    __weak IBOutlet KTPlaceholderTextView *ImageAnnotationTextView;
    __weak IBOutlet KTSegmentedButtonControl *categorySegmentedControl;
    __weak IBOutlet UIProgressView *progressView;
    
    //Network + Motion
    FluxLocationServicesSingleton *locationManager;
    CMMotionManager *motionManager;
    FluxNetworkServices *networkServices;

    //time scrolling
    UIPanGestureRecognizer *panGesture;
    UILongPressGestureRecognizer *longPressGesture;
    UITapGestureRecognizer *tapGesture;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *thumbDateFormatter;
    float previousYCoord;
    float startXCoord;
    
    //openGL
    FluxOpenGLViewController*openGLController;
    
    UIInterfaceOrientation changeToOrientation;
    FluxMapViewController *mapViewController;
    
    UIImageView* launchView;
}

@property (strong) NSCache *fluxImageCache;
@property (nonatomic, strong) NSMutableDictionary *fluxMetadata;
@property (nonatomic, weak) IBOutlet UIButton * leftDrawerButton;
@property (nonatomic, weak) IBOutlet UIButton * rightDriawerButton;
@property (strong, nonatomic) IBOutlet UIView *drawerContainerView;
@property (weak, nonatomic) IBOutlet UIView *photoApprovalView;
@property (nonatomic, strong) FluxClockSlidingControl*thumbView;


- (void)didUpdatePlacemark:(NSNotification *)notification;
- (void)didUpdateHeading:(NSNotification *)notification;
- (void)didUpdateLocation:(NSNotification *)notification;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)showRightDrawer:(id)sender;
- (IBAction)annotationsButtonAction:(id)sender;
- (IBAction)cameraButtonAction:(id)sender;
- (IBAction)approveImageAction:(id)sender;
- (IBAction)retakeImageAction:(id)sender;
- (IBAction)showFakeGallery:(id)sender;


//imageCapture
- (void)setupAVCapture;
- (void)setupNetworkServices;
- (void)setupOpenGLView;
- (void)takePicture;
- (UIImage*)blurImage:(UIImage*)img;
-(void)restartAVCaptureWithBlur:(BOOL)blur;
-(void)pauseAVCapture;
- (void)saveImageObject;


- (void)setupCameraView;
- (void)setUIForCamMode:(NSNumber*)mode;
- (void)showPhotoAnnotationView;
- (void)hidePhotoAnnotationView;


- (void)setupAnnotationsTableView;

//timeScrolling
- (void)setupGestureHandlers;
- (void)handlePanGesture:(UIPanGestureRecognizer *) sender;
- (void)handleLongPress:(UILongPressGestureRecognizer *) sender;
- (void)setThumbViewDate:(float)yCoord;

@end
