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

#import <QuartzCore/QuartzCore.h>
#import "FluxLocationServicesSingleton.h"

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@class FluxRotatingCompassButton;

@interface FluxScanViewController : UIViewController{
    
    FPPopoverController *popover;
    
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    
    UIInterfaceOrientation changeToOrientation;

    __weak IBOutlet UIButton *CameraButton;
    __weak IBOutlet UIView *headerView;
    __weak IBOutlet UILabel *locationLabel;
    __weak IBOutlet UILabel *dateRangeLabel;
    
    __weak IBOutlet FluxRotatingCompassButton *compassBtn;
    
    FluxLocationServicesSingleton *locationManager;
}

@property (nonatomic, weak) IBOutlet UIButton * leftDrawerButton;
@property (nonatomic, weak) IBOutlet UIButton * rightDriawerButton;

- (void)setupLocationManager;
- (void)updatePlacemark:(NSNotification *)notification;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)showRightDrawer:(id)sender;
- (IBAction)showAnnotationsView:(id)sender;

@end
