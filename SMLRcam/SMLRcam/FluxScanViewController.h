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
#import "FPPopoverController.h"
#import "FluxClockSlidingControl.h"
#import "FluxOpenGLViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "FluxLocationServicesSingleton.h"
#import "FluxNetworkServices.h"

@class FluxRotatingCompassButton;



@interface FluxScanViewController : UIViewController<NetworkServicesDelegate,AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate,  OpenGLViewDelegate>{
    FPPopoverController *popover;
   
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureVideoDataOutput *videoDataOutput;
	dispatch_queue_t videoDataOutputQueue;
    AVCaptureDevice *device;
    
    UIInterfaceOrientation changeToOrientation;

    __weak IBOutlet UIButton *CameraButton;
    __weak IBOutlet UIView *headerView;
    __weak IBOutlet UILabel *locationLabel;
    __weak IBOutlet UILabel *dateRangeLabel;
    __weak IBOutlet FluxRotatingCompassButton *compassBtn;
    NSDateFormatter *dateFormatter;
    float previousYCoord;
    
    FluxOpenGLViewController*openGLController;
    
    FluxLocationServicesSingleton *locationManager;
    FluxNetworkServices *networkServices;
    
}

@property (nonatomic, strong) FluxClockSlidingControl*thumbView;
@property (nonatomic, strong)NSMutableDictionary*imageDict;
@property (nonatomic, weak) IBOutlet UIButton * leftDrawerButton;
@property (nonatomic, weak) IBOutlet UIButton * rightDriawerButton;
- (void)didUpdateHeading:(NSNotification *)notification;
- (void)didUpdateLocation:(NSNotification *)notification;

- (void)didUpdatePlacemark:(NSNotification *)notification;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)showRightDrawer:(id)sender;
- (IBAction)showAnnotationsView:(id)sender;

- (void)setupAVCapture;
- (void)setupNetworkServices;
- (void)setupOpenGLView;

- (void)setupGestureHandlers;
- (void)handlePanGesture:(UIPanGestureRecognizer *) sender;
- (void)handleLongPress:(UILongPressGestureRecognizer *) sender;
- (void)setThumbViewDate:(float)yCoord;

@end
