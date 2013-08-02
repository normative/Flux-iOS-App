//
//  SMLRcamViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>



@interface FluxScanViewController : UIViewController<CLLocationManagerDelegate>{
    
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;

    __weak IBOutlet UIButton *CameraButton;
    __weak IBOutlet UIView *headerView;
    __weak IBOutlet UILabel *locationLabel;
    
    __weak IBOutlet UIButton *leftDrawerButton;
    
    CLLocationManager *locationManager;
    CLGeocoder *theGeocoder;
    CLLocation *location;
}

- (void)setupLocationManager;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (IBAction)showLeftDrawer:(id)sender;
- (IBAction)showRightDrawer:(id)sender;


@end
