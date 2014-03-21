//
//  FluxMotionManagerSingleton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

#import "FluxLocationServicesSingleton.h"
#import "FluxPedometer.h"

@class FluxPedometer;
@class FluxLocationServicesSingleton;

@interface FluxMotionManagerSingleton : NSObject
{
    FluxLocationServicesSingleton *locationManager;
    CMMotionManager * motionManager;
    NSTimer *motionUpdateTimer;
    FluxPedometer *pedometer;
    bool motionEnabled;
    bool enableHeadingCorrectedMotionMode;
    
    GLKQuaternion quat_prev;                // Previous quaternion (pose) to interpolate to smooth response
    double yaw_delta;                       // Current state of delta to apply to correct for yaw drift
    double yaw_offset_t0;                   // Offset to apply to align base reference frame with true-North at t=0
    bool calculatedInitialMagnetometer;     // Flag to indicate initial reading of magnetometer is valid at t=0
    GLKVector2 mag_field_t0;                // Vector of magnetic field projected on Earth at t=0
}

@property (nonatomic) CMQuaternion attitude;
@property int pedometerCount;

+ (id)sharedManager;
- (void)startDeviceMotion;
- (void)stopDeviceMotion;
- (void)changeHeadingCorrectedMotionMode:(bool)enableMode;

@end