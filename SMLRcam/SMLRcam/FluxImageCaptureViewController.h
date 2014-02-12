//
//  FluxImageCaptureViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-10-07.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "FluxMotionManagerSingleton.h"
#import <dispatch/dispatch.h>
#import <ImageIO/ImageIO.h>
#import "FluxLocationServicesSingleton.h"
#import "FluxAVCameraSingleton.h"
#import "FluxDisplayManager.h"
#import "FluxScanImageObject.h"
#import "FluxImageAnnotationViewController.h"

#import "GAITrackedViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

extern NSString* const FluxImageCaptureDidPop;
extern NSString* const FluxImageCaptureDidPush;
extern NSString* const FluxImageCaptureDidCaptureImage;
extern NSString* const FluxImageCaptureDidUndoCapture;

@interface FluxImageCaptureViewController : GAITrackedViewController<ImageAnnotationDelegate>{
    UIImageView *gridView;
    UIImage *capturedImage;
    UIView *blackView;
    UIImageView *historicalImageView;
    
    UIImage*snapshotImage;
    UIImage*bgImage;
    UIImageView*snapshotImageView;
    IBOutlet UIImageView *topGradientView;

    IBOutlet UIView *imageCaptureSquareView;
    IBOutlet UIButton *approveButton;
    IBOutlet UILabel *photosLabel;
    IBOutlet UIButton *undoButton;
    IBOutlet UIView *topContainerView;
    IBOutlet UIView *bottomContainerView;
    
    IBOutlet UIButton *snapshotShareButton;
    
    NSMutableArray *capturedImageObjects;
    NSMutableArray *capturedImages;
    
}
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (nonatomic) BOOL isSnapshot;

// TS: no longer needed - should get list(s) from DisplayManager directly
//@property (nonatomic, weak) NSMutableDictionary *fluxNearbyMetadata;
//@property (nonatomic, weak) NSMutableArray *nearbyList;

@property (nonatomic, weak) FluxDisplayManager *fluxDisplayManager;
@property (nonatomic, weak) FluxAVCameraSingleton *cameraManager;

@property (nonatomic, weak) FluxLocationServicesSingleton *locationManager;
@property (nonatomic, weak) FluxMotionManagerSingleton *motionManager;

- (IBAction)undoButtonAction:(id)sender;

- (IBAction)closeButtonAction:(id)sender;
- (IBAction)approveImageAction:(id)sender;

- (IBAction)shareButtonAction:(id)sender;

- (void) setHistoricalTransparentImage:(UIImage *)image;

- (void)setHidden:(BOOL)hidden;

- (void)takePicture;
- (void)presentSnapshot:(UIImage*)snapshot;
@end
