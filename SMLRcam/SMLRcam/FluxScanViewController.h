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
#import "FluxMapViewController.h"
#import "FluxOpenGLViewController.h"
#import "FluxImageAnnotationViewController.h"
#import "FluxFiltersViewController.h"
#import "IDMPhotoBrowser.h"
#import "BBCyclingLabel.h"

#import "FluxSocialManager.h"
#import "FluxDisplayManager.h"

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>

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
    __strong IBOutlet FluxCameraButton *imageCaptureButton;
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
@property (strong, nonatomic) IBOutlet UIView *bottomToolbarView;
@property (nonatomic, weak) IBOutlet UIButton * leftDrawerButton;
@property (strong, nonatomic) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton * rightDriawerButton;
@property (weak, nonatomic) IBOutlet UIView *photoApprovalView;
@property (nonatomic, strong) IBOutlet FluxTimeFilterControl*timeFilterControl;

@property (nonatomic, strong) FluxDisplayManager *fluxDisplayManager;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)cameraButtonAction:(id)sender;
- (IBAction)filterButtonAction:(id)sender;
- (void)setCameraButtonEnabled:(BOOL)enabled;
- (IBAction)snapshotButtonAction:(id)sender;
- (IBAction)imageCaptureButtonAction:(id)sender;

//imageCapture
- (void)setupOpenGLView;

- (UIImage*)blurImage:(UIImage*)img;
- (void)setupCameraView;

//timeScrolling
- (void)setupTimeFilterControl;
- (void) didTapImageFunc:(FluxScanImageObject*) fsio;
- (IBAction)toggleLocationCoordinate:(id)sender;

@end
