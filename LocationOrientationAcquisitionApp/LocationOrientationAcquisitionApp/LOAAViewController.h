//
//  LOAAViewController.h
//  LocationOrientationAcquisitionApp
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface LOAAViewController : UIViewController <CLLocationManagerDelegate, UITextFieldDelegate>
{
    CLLocationManager *locationManager;
    CMMotionManager *motionManager;
    NSTimer *motionUpdateTimer;
    NSDateFormatter *dateFormat;
    
    NSLock *locationFileLock;
    NSLock *motionFileLock;
    NSString *locationFilename;
    NSString *motionFilename;
    NSFileHandle *locationFile;
    NSFileHandle *motionFile;
    
    __weak IBOutlet UILabel *Latitude;
    __weak IBOutlet UILabel *Longitude;
    __weak IBOutlet UILabel *Altitude;
    __weak IBOutlet UILabel *HorizontalAcc;
    __weak IBOutlet UILabel *VerticalAcc;
    __weak IBOutlet UILabel *Course;
    __weak IBOutlet UILabel *Speed;
    __weak IBOutlet UILabel *Heading;
    __weak IBOutlet UILabel *HeadingAcc;
    __weak IBOutlet UILabel *Pitch;
    __weak IBOutlet UILabel *Yaw;
    __weak IBOutlet UILabel *Roll;
    
    __weak IBOutlet UITextField *Annotation;
}

- (IBAction)StartNewButton:(id)sender;
- (IBAction)ClearOldButton:(id)sender;
- (IBAction)AnnotateButton:(id)sender;

@end
