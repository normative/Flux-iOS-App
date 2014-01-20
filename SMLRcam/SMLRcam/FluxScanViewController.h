//
//  SMLRcamViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxTimeFilterControl.h"
#import "FluxCameraButton.h"
#import "FluxCompassButton.h"
#import "FluxDataManager.h"
#import "FluxDataRequest.h"
#import "FluxMapViewController.h"
#include "FluxOpenGLViewController.h"
#import "FluxImageAnnotationViewController.h"
#import "FluxImageCaptureViewController.h"
#import "FluxFiltersViewController.h"
#import "FluxLocationServicesSingleton.h"
#import "IDMPhotoBrowser.h"
#import "BBCyclingLabel.h"

#import "FluxSocialManager.h"
#import "FluxDisplayManager.h"


#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <dispatch/dispatch.h>

#import "GAITrackedViewController.h"


extern NSString* const FluxScanViewDidAcquireNewPicture;
extern NSString* const FluxScanViewDidAcquireNewPictureLocalIDKey;
//extern NSString* const FluxDidTapImage;
@class FluxRotatingCompassButton;


@interface FluxScanViewController : GAITrackedViewController<AVCaptureVideoDataOutputSampleBufferDelegate, FiltersTableViewDelegate, UITableViewDataSource, UITableViewDelegate, TimeFilterScrollViewTapDelegate, IDMPhotoBrowserDelegate, FluxSocialManagerDelegate>{
    
    //headerView
    __weak IBOutlet UIView *ScanUIContainerView;
    __weak IBOutlet FluxCompassButton *radarButton;
    UIImage *snapshotBGImage;
    
    UITableView*annotationsTableView;
    
    
    UIView *photoViewerPlacementView;


    
    BOOL imageCaptureIsActive;
    FluxScanImageObject *capturedImageObject;
    
    UIImage *capturedImage;
    UIImageView*blurView;
    __strong IBOutlet FluxCameraButton *CameraButton;
    IBOutlet UIButton *filterButton;
    IBOutlet BBCyclingLabel *dateRangeLabel;
    NSTimer *dateRangeLabelHideTimer;

    __weak IBOutlet UIProgressView *progressView;
    
    //Network + Motion
    CMMotionManager *motionManager;

    //time scrolling
    NSDateFormatter *dateFormatter;
    CGPoint _point;
    //openGL
    FluxOpenGLViewController*openGLController;
    //map
    FluxMapViewController *mapViewController;
    
    int uploadsCompleted;
    int totalUploads;
    
    FluxDataFilter *currentDataFilter;
    
    
}
@property (nonatomic, weak) IBOutlet UIButton * leftDrawerButton;
@property (nonatomic, weak) IBOutlet UIButton * rightDriawerButton;
@property (weak, nonatomic) IBOutlet UIView *photoApprovalView;
@property (nonatomic, strong) IBOutlet FluxTimeFilterControl*timeFilterControl;

@property (nonatomic, strong) FluxDisplayManager *fluxDisplayManager;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)cameraButtonAction:(id)sender;
- (IBAction)filterButtonAction:(id)sender;
- (void)setCameraButtonEnabled:(BOOL)enabled;
- (IBAction)snapshotButtonAction:(id)sender;

- (IBAction)stepper:(id)sender;

//imageCapture
- (void)setupOpenGLView;

- (UIImage*)blurImage:(UIImage*)img;
- (void)setupCameraView;

//timeScrolling
- (void)setupTimeFilterControl;
- (void) didTapImageFunc:(FluxScanImageObject*) fsio;
- (IBAction)toggleHomographyResult:(id)sender;
- (IBAction)toggleLocationCoordinate:(id)sender;

@end
