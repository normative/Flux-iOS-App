//
//  FluxPedometer.h
//  Flux
//
//  Created by Denis Delorme on 10/18/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

#define MAXSAMPLES  120

typedef enum _trenddir {
    FALLING = -1,
    FLAT = 0,
    RISING = 1
} trendDir;

typedef enum _walkdir {
    BACKWARDS = -1,
    UNKNOWN = 0,
    FORWARDS = 1
} walkDir;

@interface FluxPedometer : NSObject<CLLocationManagerDelegate>{
//    BOOL isPaused;
//    CMMotionManager *motionManager;
//    NSTimer* motionUpdateTimer;
    
    NSTimer*walkingTimer;
//    NSTimer*firstStepTimer;
    
//    NSTimer*gpsTimer;
//    float oldCourse;
    
//    CLLocationManager * locationManager;
    int countState;
    int stepCount;
    BOOL isWalking;
    walkDir walkingDirection;
    
    double samples[3][MAXSAMPLES];
    int samplecount;
    double lpf[3][MAXSAMPLES];
    double delta[3][MAXSAMPLES];
    
    trendDir vertAccelTrend;
    trendDir vertAccelTrendPrev;
    
    NSDateFormatter *dateFormat;
    
//    NSLock *motionFileLock;
    NSString *motionFilename;
    NSFileHandle *motionFile;
    
}


//labels
//@property (weak, nonatomic) IBOutlet UILabel *countLabel;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
//@property (weak, nonatomic) IBOutlet GraphView *accelGraph;
//@property (weak, nonatomic) IBOutlet GraphView *motionGraph;


//graphs
//@property (weak, nonatomic) IBOutlet UILabel *accelGraphXLabel;
//@property (weak, nonatomic) IBOutlet UILabel *accelGraphYLabel;
//@property (weak, nonatomic) IBOutlet UILabel *accelGraphZLabel;
//
//@property (weak, nonatomic) IBOutlet UILabel *MotionGraphYawLabel;
//@property (weak, nonatomic) IBOutlet UILabel *MotionGraphPitchLabel;
//@property (weak, nonatomic) IBOutlet UILabel *MotionGraphRollLabel;

//location
//@property (weak, nonatomic) IBOutlet UILabel *locarionCoordLabel;
//@property (weak, nonatomic) IBOutlet UILabel *locationSpeedLabel;
//@property (weak, nonatomic) IBOutlet UILabel *locarionAccuracyLabel;
//@property (weak, nonatomic) IBOutlet UILabel *locarionHeadingLabel;
//@property (weak, nonatomic) IBOutlet UILabel *locationCourseLabel;
//@property (weak, nonatomic) IBOutlet UILabel *locationCourseStringLabel;

//lights
//@property (weak, nonatomic) IBOutlet UIImageView *walkingLight;
//@property (weak, nonatomic) IBOutlet UIImageView *firstStepLight;
//@property (weak, nonatomic) IBOutlet UIImageView *walkLight;

@property (nonatomic) CLLocation* location;
@property (nonatomic) CLLocationDirection heading;

//- (IBAction)pauseButtonTaped:(id)sender;
//- (void)turnWalkingOff;
- (void)processMotion:(CMDeviceMotion *)devMotion;


@end
