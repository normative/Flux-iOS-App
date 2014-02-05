//
//  FluxMotionManagerSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxMotionManagerSingleton.h"

@implementation FluxMotionManagerSingleton


+ (id)sharedManager
{
    static FluxMotionManagerSingleton *sharedFluxMotionManagerSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFluxMotionManagerSingleton = [[self alloc] init];
    });
    return sharedFluxMotionManagerSingleton;
}

- (id)init
{
    if (self = [super init])
    {
        locationManager = [FluxLocationServicesSingleton sharedManager];
        motionManager = [[CMMotionManager alloc] init];
        
        if (motionManager == nil)
        {
            return nil;
        }
        
        pedometer = [[FluxPedometer alloc] init];
        
        // Tell CoreMotion to show the compass calibration HUD when required to provide true north-referenced attitude
        //ths is the ugly figure 8 on the screen. We might scrap this doen the road.
        motionManager.showsDeviceMovementDisplay = YES;
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    }
    
    return self;
}

- (void)startDeviceMotion
{
    if (motionManager)
    {
        // New in iOS 5.0: Attitude that is referenced to true north
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
        
        motionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(UpdateDeviceMotion:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:motionUpdateTimer forMode:NSRunLoopCommonModes];
        
        [pedometer startPedometer];
    }
}

- (void)stopDeviceMotion
{
    if (motionManager)
    {
        [motionManager stopDeviceMotionUpdates];
        [motionUpdateTimer invalidate];
        
        [pedometer stopPedometer];
    }
}

- (void)UpdateDeviceMotion:(NSTimer*)timer
{
    if ((motionManager) && ([motionManager isDeviceMotionActive]))
    {
        CMQuaternion updatedAttitude = self.attitude;
        [self calcAttitudeFromDeviceMotion:motionManager.deviceMotion andHeading:locationManager.locationManager.heading intoQuaternion:&updatedAttitude];
        self.attitude = updatedAttitude;
        
        [pedometer processMotion:motionManager.deviceMotion];
    }
}

- (void)calcAttitudeFromDeviceMotion:(CMDeviceMotion *)devMotion andHeading:(CLHeading *)heading intoQuaternion:(CMQuaternion *)outquat
{
    // Phone reference frame: x right, y top, z up from screen
    // Earth reference frame: x north, y west, z up
    // Earth to phone (using attitude): Yaw (z) - Pitch (x) - Roll (y)
    
    CMQuaternion q = devMotion.attitude.quaternion;
//    double yaw1 = atan2(2.0*(q.x*q.y + q.w*q.z), q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z);
    double pitch1 = atan2(2.0*(q.y*q.z + q.w*q.x), q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z);
    double roll1 = asin(-2.0*(q.x*q.z - q.w*q.y));
    
    // Re-create quaternion using heading as the new yaw component. Note that heading needs correction to match earth axes.
    // Heading is top of phone (y-axis) wrt North. At attitude YPR (0,0,0) y-axis points due West.
    GLKQuaternion quatyaw = GLKQuaternionMakeWithAngleAndAxis((-heading.trueHeading - 90.0)*M_PI/180.0, 0.0, 0.0, 1.0);
    GLKQuaternion quatpitch = GLKQuaternionMakeWithAngleAndAxis(pitch1, 1.0, 0.0, 0.0);
    GLKQuaternion quatroll = GLKQuaternionMakeWithAngleAndAxis(roll1, 0.0, 1.0, 0.0);
    GLKQuaternion quatnew = GLKQuaternionNormalize(GLKQuaternionMultiply(quatyaw, GLKQuaternionNormalize(GLKQuaternionMultiply(quatroll, quatpitch))));
    
    outquat->x = quatnew.x;
    outquat->y = quatnew.y;
    outquat->z = quatnew.z;
    outquat->w = quatnew.w;
}

@end
