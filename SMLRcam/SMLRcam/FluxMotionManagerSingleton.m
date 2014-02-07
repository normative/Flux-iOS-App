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
    
    // YPR extraction from quaternions, using formula for Euler Angle Sequence
    // "Representing Attitude: Euler Angles, Unit Quaternions, and Rotation Vectors"
    // James Diebel, Stanford University, 20 October, 2006

    // 3-1-3 (ideal for attitude 90 degrees)
    CMQuaternion q = devMotion.attitude.quaternion;
    double rot3 = atan2(2.0*q.x*q.z - 2.0*q.w*q.y, 2.0*q.y*q.z + 2.0*q.w*q.x);
    double rot2 = acos(q.z*q.z - q.y*q.y - q.x*q.x + q.w*q.w);
    double rot1 = atan2(2.0*q.x*q.z + 2.0*q.w*q.y, -2.0*q.y*q.z + 2.0*q.w*q.x);

    // 2-1-3 (ideal for attitude of 0 or 180 degrees)
//    CMQuaternion q = devMotion.attitude.quaternion;
//    double roll1 = atan2(-2.0*q.x*q.z + 2.0*q.w*q.y, q.z*q.z - q.y*q.y - q.x*q.x + q.w*q.w);
//    double pitch1 = asin(2.0*q.y*q.z + 2.0*q.w*q.x);
//    double yaw1 = atan2(-2.0*q.x*q.y + 2.0*q.w*q.z, q.y*q.y - q.z*q.z + q.w*q.w - q.x*q.x);
    
    // Apply correction to heading for any additional yaw applied after a pitch.
    // The net effect of this rotation is that the y-vector of the device (out the top) will
    // have a different heading than the z-vector of the device (line of sight) which is the
    // component we care about for an AR-type app. Heading is measured in the Earth plane,
    // so we are taking projections of these vectors down onto the Earth plane to measure heading.
    // Therefore the correction is the angle between the heading of the y-axis vector and the
    // heading of the z-axis vector, with the y-axis vector being the reported heading, and the
    // z-axis vector being the desired yaw component.
    
    // v for each vector is obtained by taking a unit vector (in device frame) and applying the
    // attitude rotation to get the vector in the Earth frame.
    
    GLKQuaternion device_to_earth = (GLKQuaternionMake(q.x, q.y, q.z, q.w));
    GLKVector3 y_device = GLKVector3Make(0.0, 1.0, 0.0);
    GLKVector3 los_device = GLKVector3Make(0.0, 0.0, -1.0); // LOS of the device is -ve z-axis
    GLKVector3 y_device_earth = GLKVector3Normalize(GLKQuaternionRotateVector3(device_to_earth, y_device));
    GLKVector3 los_device_earth = GLKVector3Normalize(GLKQuaternionRotateVector3(device_to_earth, los_device));
    GLKVector3 n_earth = GLKVector3Make(0.0, 0.0, 1.0);
    
    GLKVector3 y_projection_earth = [self projectVector:y_device_earth ontoPlaneWithNormal:n_earth];
    GLKVector3 los_projection_earth = [self projectVector:los_device_earth ontoPlaneWithNormal:n_earth];
    
//    NSLog(@"y_device: (%f, %f, %f) los_device: (%f, %f, %f)", y_projection_earth.x, y_projection_earth.y, y_projection_earth.z, los_projection_earth.x, los_projection_earth.y, los_projection_earth.z);

    // Then we can get the angle between the two projection vectors as our correction
    double heading_delta = [self calculateAngleBetweenVector:y_projection_earth andVector:los_projection_earth];
    
//    NSLog(@"Angle correction: %f, Heading: %f", heading_delta * 180.0/M_PI, heading.trueHeading);

    // Re-create quaternion using heading as the new yaw component. Note that heading needs correction to match earth axes.
    // Heading is top of phone (y-axis) wrt North. At attitude YPR (0,0,0) y-axis points due West.

    // Using 3-1-3 rotation sequence
    GLKQuaternion quatyaw = GLKQuaternionMakeWithAngleAndAxis(((heading.trueHeading + 90.0)*M_PI/180.0 - heading_delta), 0.0, 0.0, 1.0);
    GLKQuaternion quatpitch = GLKQuaternionMakeWithAngleAndAxis(-rot2, 1.0, 0.0, 0.0);
    GLKQuaternion quatroll = GLKQuaternionMakeWithAngleAndAxis(-rot3, 0.0, 0.0, 1.0);
    GLKQuaternion quatnew = GLKQuaternionNormalize(GLKQuaternionInvert(GLKQuaternionNormalize(GLKQuaternionMultiply(quatroll, GLKQuaternionNormalize(GLKQuaternionMultiply(quatpitch, quatyaw))))));

//    // Using 2-1-3 rotation sequence
//    GLKQuaternion quatyaw = GLKQuaternionMakeWithAngleAndAxis(((heading.trueHeading + 90.0)*M_PI/180.0 - heading_delta), 0.0, 0.0, 1.0);
//    GLKQuaternion quatpitch = GLKQuaternionMakeWithAngleAndAxis(-pitch1, 1.0, 0.0, 0.0);
//    GLKQuaternion quatroll = GLKQuaternionMakeWithAngleAndAxis(-roll1, 0.0, 1.0, 0.0);
//    GLKQuaternion quatnew = GLKQuaternionNormalize(GLKQuaternionInvert(GLKQuaternionNormalize(GLKQuaternionMultiply(quatroll, GLKQuaternionNormalize(GLKQuaternionMultiply(quatpitch, quatyaw))))));
    
//    // Calculate Yaw-Pitch-Roll for logging
//    double rollnew = atan2(-2.0*quatnew.x*quatnew.z + 2.0*quatnew.w*quatnew.y, quatnew.z*quatnew.z - quatnew.y*quatnew.y - quatnew.x*quatnew.x + quatnew.w*quatnew.w);
//    double pitchnew = asin(2.0*quatnew.y*quatnew.z + 2.0*quatnew.w*quatnew.x);
//    double yawnew = atan2(-2.0*quatnew.x*quatnew.y + 2.0*quatnew.w*quatnew.z, quatnew.y*quatnew.y - quatnew.z*quatnew.z + quatnew.w*quatnew.w - quatnew.x*quatnew.x);
//    
//    NSLog(@"YPR (updated): %f, %f, %f", yawnew * 180.0/M_PI, pitchnew * 180.0/M_PI, rollnew * 180.0/M_PI);

    outquat->x = quatnew.x;
    outquat->y = quatnew.y;
    outquat->z = quatnew.z;
    outquat->w = quatnew.w;
}

- (GLKVector3) projectVector:(GLKVector3)v ontoPlaneWithNormal:(GLKVector3)n
{
    // A projection of a vector v onto a plane P (with normal n) is u:
    // u = v - <v dot n>n
    // where <v dot n>n is orthogonal to P.
    
    GLKVector3 projection;
    
    // Calculate w = <v dot n>n
    GLKVector3 w = GLKVector3MultiplyScalar(n, GLKVector3DotProduct(v, n));
    
    projection = GLKVector3Subtract(v, w);
    
    return projection;
}

- (double) calculateAngleBetweenVector:(GLKVector3)u andVector:(GLKVector3)v
{
    return acos(GLKVector3DotProduct(u, v) / (GLKVector3Length(u) * GLKVector3Length(v)));
}

@end
