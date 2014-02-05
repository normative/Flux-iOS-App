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

#import "FluxPedometer.h"

@class FluxPedometer;

@interface FluxMotionManagerSingleton : NSObject
{
    CMMotionManager * motionManager;
    NSTimer *motionUpdateTimer;
    FluxPedometer *pedometer;
}

@property (nonatomic) CMQuaternion attitude;
@property int pedometerCount;
@property (nonatomic) CLHeading *locationHeading;

+ (id)sharedManager;
- (void)startDeviceMotion;
- (void)stopDeviceMotion;

@end