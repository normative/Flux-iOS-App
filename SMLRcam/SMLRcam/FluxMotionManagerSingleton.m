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
        [self calcAttitudeFromDeviceMotion:motionManager.deviceMotion andHeading:self.locationHeading intoQuaternion:&updatedAttitude];
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
    GLKQuaternion quatnew = GLKQuaternionNormalize(GLKQuaternionMultiply(quatyaw, GLKQuaternionNormalize(GLKQuaternionMultiply(quatpitch, quatroll))));
    
//    // Create a GLKQuaternion for quaternion math to zero out the yaw (about the earth z-axis)
//    // (this approach did not work - would get a roll component as yaw increased)
//    CMQuaternion quat = devMotion.attitude.quaternion;
//    GLKQuaternion quatnew = GLKQuaternionMake(quat.x, quat.y, quat.z, quat.w);
//    quatnew.z = 0.0;
//    quatnew = GLKQuaternionNormalize(quatnew);
//    GLKQuaternion quatHeadingRotate = GLKQuaternionMakeWithAngleAndAxis((-heading.trueHeading)*M_PI/180.0, 0.0, 0.0, 1.0);
//    quatHeadingRotate = GLKQuaternionNormalize(quatHeadingRotate);
//    
//    quatnew = GLKQuaternionNormalize(GLKQuaternionMultiply(quatHeadingRotate, quatnew));
    
    // Calculate Yaw-Pitch-Roll for logging
    double pitchnew = atan2(2.0*(quatnew.y*quatnew.z + quatnew.w*quatnew.x), quatnew.w*quatnew.w - quatnew.x*quatnew.x - quatnew.y*quatnew.y + quatnew.z*quatnew.z);
    double rollnew = asin(-2.0*(quatnew.x*quatnew.z - quatnew.w*quatnew.y));
    double yawnew = atan2(2.0*(quatnew.x*quatnew.y + quatnew.w*quatnew.z), quatnew.w*quatnew.w + quatnew.x*quatnew.x - quatnew.y*quatnew.y - quatnew.z*quatnew.z);

//    NSLog(@"Gravity x: %f, y: %f: z: %f, Heading: %f", devMotion.gravity.x, devMotion.gravity.y, devMotion.gravity.z, heading.trueHeading);
//    NSLog(@"Yaw: %f, Pitch: %f, Roll: %f, Calc yaw: %f", devMotion.attitude.yaw*180.0/M_PI, devMotion.attitude.pitch*180.0/M_PI, devMotion.attitude.roll*180.0/M_PI, yaw*180.0/M_PI);
//    NSLog(@"Yaw1: %f, Pitch1: %f, Roll1: %f", yaw1*180.0/M_PI, pitch1*180.0/M_PI, roll1*180.0/M_PI);
//    NSLog(@"Yaw2: %f, Pitch2: %f, Roll2: %f, Heading: %f", yawnew*180.0/M_PI, pitchnew*180.0/M_PI, rollnew*180.0/M_PI, heading.trueHeading);
    
    outquat->x = quatnew.x;
    outquat->y = quatnew.y;
    outquat->z = quatnew.z;
    outquat->w = quatnew.w;
}

@end
