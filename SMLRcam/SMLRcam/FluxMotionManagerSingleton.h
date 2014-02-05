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
}

@property (nonatomic) CMQuaternion attitude;
@property int pedometerCount;

+ (id)sharedManager;
- (void)startDeviceMotion;
- (void)stopDeviceMotion;

@end