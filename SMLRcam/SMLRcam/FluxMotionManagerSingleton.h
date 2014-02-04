//
//  FluxMotionManagerSingleton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

#import "FluxPedometer.h"

@interface FluxMotionManagerSingleton : NSObject
{
    CMMotionManager * motionManager;
    NSTimer *motionUpdateTimer;
    FluxPedometer *pedometer;
}

@property (nonatomic) CMAttitude* attitude;
@property int pedometerCount;

+ (id)sharedManager;
- (void)startDeviceMotion;
- (void)stopDeviceMotion;

@end