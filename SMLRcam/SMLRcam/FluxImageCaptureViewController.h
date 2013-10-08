//
//  FluxImageCaptureViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-10-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <dispatch/dispatch.h>
#import <ImageIO/ImageIO.h>
#import "FluxLocationServicesSingleton.h"
#import "FluxAVCameraSingleton.h"
#import "FluxDisplayManager.h"
#import "FluxScanImageObject.h"

#import "GAITrackedViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

extern NSString* const FluxImageCaptureDidPop;
extern NSString* const FluxImageCaptureDidCaptureImage;

@interface FluxImageCaptureViewController : GAITrackedViewController{
    UIImageView *gridView;
    UIImage *capturedImage;
    UIView *blackView;
    IBOutlet UIView *imageCaptureSquareView;
    IBOutlet UILabel *imageCountLabel;
    IBOutlet UIButton *approveButton;
    
    //Camera
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureDevice *device;
    dispatch_queue_t AVCaptureBackgroundQueue;
    
    
    FluxLocationServicesSingleton *locationManager;
    CMMotionManager *motionManager;
    FluxAVCameraSingleton *cameraManager;
    NSMutableArray *capturedImageObjects;
    NSMutableArray *capturedImages;
    
}
@property (strong, nonatomic) IBOutlet UIButton *closeButton;

@property (nonatomic, weak) NSMutableDictionary *fluxNearbyMetadata;
@property (nonatomic, weak) NSMutableArray *nearbyList;

@property (nonatomic, strong) FluxDisplayManager *fluxDisplayManager;


- (IBAction)closeButtonAction:(id)sender;
- (IBAction)approveImageAction:(id)sender;



- (void)setHidden:(BOOL)hidden;

- (void)takePicture;
@end
