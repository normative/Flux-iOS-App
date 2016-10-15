//
//  SMLRcamViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxTimeFilterControl.h"
#import "FluxImageCaptureButton.h"

#import "FluxTutorialView.h"
#import "FluxCompassButton.h"
#import "FluxLoggerService.h"
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

#import "GAITrackedViewController.h"

#import "FluxDebugViewController.h"
#import "FluxFlickrImageSelectViewController.h"
#import "CustomBadge.h"


extern NSString* const FluxScanViewDidAcquireNewPicture;
extern NSString* const FluxScanViewDidAcquireNewPictureLocalIDKey;
//extern NSString* const FluxDidTapImage;

typedef enum {
    historicalPhotoModeTypeDefault = 1,
    historicalPhotoModeTypePhotoRoll,
    historicalPhotoModeTypeFlickr
} historicalPhotoModeTypes;

@class FluxRotatingCompassButton;

@interface FluxScanViewController : GAITrackedViewController<FluxTutorialDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, FiltersTableViewDelegate, UITableViewDataSource, UITableViewDelegate, TimeFilterControlDelegate, IDMPhotoBrowserDelegate, FluxSocialManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, FluxFlickrImageSelectProtocol>{
    
    //tutorialView
    FluxTutorialView *tutorialView;
    
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
    __strong IBOutlet FluxImageCaptureButton *imageCaptureButton;
    IBOutlet BBCyclingLabel *dateRangeLabel;
    NSTimer *dateRangeLabelHideTimer;

    __weak IBOutlet UIProgressView *progressView;
    
    //time scrolling
    NSDateFormatter *dateFormatter;
    CGPoint _point;
    BOOL firstContent;
    
    //openGL
    FluxOpenGLViewController*openGLController;
    
    int uploadsCompleted;
    int totalUploads;
    
    
    CustomBadge *friendRequestsBadge;
    
    //debugMenu
    int debugPressCount;
    IBOutlet UIButton *debugButton1;
    IBOutlet UIButton *debugButton2;
    IBOutlet UIButton *debugButton3;
    IBOutlet UIButton *debugButton4;
    
    IBOutlet UILabel *pedometerLabel;
    
    historicalPhotoModeTypes historicalPhotoPickerMode;
    
    // Dictionary containing a mapping from flickrID to imageID for indicating which flickrID's have been imported
    NSMutableDictionary *flickrIDToImageIDMap;
    
    // Dictionary containing all localIDs awaiting an imageID, with the value storing the flickrID
    NSMutableDictionary *outstandingLocalIDsToFlickrID;

    NSCondition *updateUserImageIDListLock;
    NSArray *userImageIDList;
}

@property (strong, nonatomic) IBOutlet UIView *bottomToolbarView;
@property (strong, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIView *photoApprovalView;
@property (nonatomic, strong) IBOutlet FluxTimeFilterControl*timeFilterControl;
@property (nonatomic, strong) FluxDisplayManager *fluxDisplayManager;

@property (nonatomic, strong) FluxDebugViewController *debugViewController;
@property (nonatomic, strong) FluxLoggerService *fluxLoggerService;
@property (nonatomic, strong) FluxDataFilter *currentDataFilter;

- (void)hideDebugMenu;
- (void)showTutorial;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)cameraButtonAction:(id)sender;
- (IBAction)filterButtonAction:(id)sender;
- (void)setCameraButtonEnabled:(BOOL)enabled;
- (IBAction)snapshotButtonAction:(id)sender;
- (IBAction)imageCaptureButtonAction:(id)sender;

- (void)setProfileBadgeCount:(int)badgeValue;

//imageCapture
- (void)setupOpenGLView;

- (UIImage*)blurImage:(UIImage*)img;
- (void)setupCameraView;

//timeScrolling
- (void)setupTimeFilterControl;
- (void) didTapImageFunc:(FluxScanImageObject*) fsio withBGImage:(UIImage*)bgImage;

//debugMenu
- (IBAction)debugButton1Pressed:(id)sender;
- (IBAction)debugButton1Cancelled:(id)sender;
- (IBAction)debugButton2Pressed:(id)sender;
- (IBAction)debugButton2Cancelled:(id)sender;
- (IBAction)debugButton3Pressed:(id)sender;
- (IBAction)debugButton3Cancelled:(id)sender;
- (IBAction)debugButton4Pressed:(id)sender;
- (IBAction)debugButton4Cancelled:(id)sender;


@end
