//
//  FluxMotionManagerSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMotionManagerSingleton.h"

@implementation FluxMotionManagerSingleton


+ (id)sharedManager {
    static FluxMotionManagerSingleton *sharedFluxMotionManagerSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFluxMotionManagerSingleton = [[self alloc] init];
    });
    return sharedFluxMotionManagerSingleton;
}

- (id)init {
    if (self = [super init]) {
        
        motionManager = [[CMMotionManager alloc] init];
        
        if (motionManager == nil)
        {
            return nil;
        }
        
        // Tell CoreMotion to show the compass calibration HUD when required to provide true north-referenced attitude
        //ths is the ugly figure 8 on the screen. We might scrap this doen the road.
        motionManager.showsDeviceMovementDisplay = YES;
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    }
    return self;
}

- (void)startDeviceMotion{
    if (motionManager) {
        // New in iOS 5.0: Attitude that is referenced to true north
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
        
        motionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1/60.0 target:self selector:@selector(UpdateDeviceMotion:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:motionUpdateTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)stopDeviceMotion{
    if (motionManager) {
        [motionManager stopDeviceMotionUpdates];
        [motionUpdateTimer invalidate];
    }
}

- (void)UpdateDeviceMotion:(NSTimer*)timer{
    if ((motionManager) && ([motionManager isDeviceMotionActive])) {
        self.attitude = motionManager.deviceMotion.attitude;
    }
    
}

@end
