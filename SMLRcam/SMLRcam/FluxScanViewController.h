//
//  SMLRcamViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMDrawerBarButtonItem.h"
#import "FluxTimeFilterControl.h"
#import "FluxCameraButton.h"
#import "FluxCompassButton.h"
#import "FluxDataManager.h"
#import "FluxDataRequest.h"
#import "FluxMapViewController.h"
#include "FluxOpenGLViewController.h"
#import "FluxImageAnnotationViewController.h"
#import "FluxImageCaptureViewController.h"
#import "FluxFiltersTableViewController.h"
#import "FluxLocationServicesSingleton.h"

#import "FluxDisplayManager.h"


#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <dispatch/dispatch.h>

#import "GAITrackedViewController.h"


extern NSString* const FluxScanViewDidAcquireNewPicture;
extern NSString* const FluxScanViewDidAcquireNewPictureLocalIDKey;

@class FluxRotatingCompassButton;


@interface FluxScanViewController : GAITrackedViewController<AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, FiltersTableViewDelegate>{
    
    //headerView
    __weak IBOutlet UIView *ScanUIContainerView;
    __weak IBOutlet FluxCompassButton *radarButton;
    
    UITableView*annotationsTableView;
    


    
    BOOL imageCaptureIsActive;
    FluxScanImageObject *capturedImageObject;
    
    UIImage *capturedImage;
    UIImageView*blurView;
    __strong IBOutlet FluxCameraButton *CameraButton;
    IBOutlet UIButton *filterButton;
    IBOutlet UILabel *locationLabel;

    __weak IBOutlet UIProgressView *progressView;
    
    //Network + Motion
    FluxLocationServicesSingleton *locationManager;
    CMMotionManager *motionManager;

    //time scrolling
    NSDateFormatter *dateFormatter;
    
    //openGL
    FluxOpenGLViewController*openGLController;
    //map
    FluxMapViewController *mapViewController;

    
    FluxImageAnnotationViewController*imageAnnotationViewController;
    
    FluxDataFilter *currentDataFilter;
    
    UIImageView* launchView;
}

@property (nonatomic, strong) NSMutableDictionary *fluxNearbyMetadata;
@property (nonatomic, weak) IBOutlet UIButton * leftDrawerButton;
@property (nonatomic, weak) IBOutlet UIButton * rightDriawerButton;
@property (weak, nonatomic) IBOutlet UIView *photoApprovalView;
@property (nonatomic, strong) IBOutlet FluxTimeFilterControl*timeFilterControl;

@property (nonatomic, strong) FluxDisplayManager *fluxDisplayManager;


- (void)didUpdatePlacemark:(NSNotification *)notification;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)showRightDrawer:(id)sender;
- (IBAction)annotationsButtonAction:(id)sender;
- (IBAction)cameraButtonAction:(id)sender;
- (IBAction)approveImageAction:(id)sender;
- (IBAction)retakeImageAction:(id)sender;
- (IBAction)filterButtonAction:(id)sender;


//imageCapture
- (void)setupAVCapture;
- (void)setupOpenGLView;
- (void)takePicture;
- (UIImage*)blurImage:(UIImage*)img;
-(void)restartAVCaptureWithBlur:(BOOL)blur;
-(void)pauseAVCapture;
- (void)saveImageObject;


- (void)setupCameraView;


- (void)setupAnnotationsTableView;

//timeScrolling
- (void)setupTimeFilterControl;
- (void)setupGestureHandlers;

@end
