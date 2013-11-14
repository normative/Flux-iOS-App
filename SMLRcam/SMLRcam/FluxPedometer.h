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

extern NSString* const FluxPedometerDidTakeStep;

@interface FluxPedometer : NSObject<CLLocationManagerDelegate>{
    CMMotionManager *motionManager;
    NSTimer* motionUpdateTimer;
    
    NSTimer*walkingTimer;

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
    
    NSString *motionFilename;
    NSFileHandle *motionFile;
    
    NSMutableArray *motionData;
    int nextDataIdx;
    
    NSDate *timeOfLastFootFall;
    NSDate *timeOfLastStep;
    NSDate *timeSinceLastCheck;
    
    double currentSpeed;

//    double velocity[3];
    
    CMAcceleration accelAccumZ;
    int accelCount;
    CMAcceleration accelStepAvg;
    
    bool firstStep;
    
    bool horizAccelThresholdReached;
    bool vertAccelThresholdReached;
}

@property (nonatomic, setter = setIsPaused:) bool isPaused;

//- (void)pauseButtonTaped;
- (void)processMotion:(CMDeviceMotion *)devMotion;
- (void) resetCount;
- (void) setViewController:(UIViewController *)vc;

@end
