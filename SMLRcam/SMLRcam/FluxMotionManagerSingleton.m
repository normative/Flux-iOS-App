//
//  FluxMotionManagerSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxMotionManagerSingleton.h"

typedef struct{
    double theta1;
    double theta2;
    double theta3;
} euler_angles;

const float quaternion_slerp_interpolation_factor = 0.25;
const float pitch_heading_flip_limit = 135.0 * M_PI / 180.0;

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
        
        motionEnabled = NO;
        enableHeadingCorrectedMotionMode = YES;
    }
    
    return self;
}

- (void)startDeviceMotion
{
    if (motionManager && !motionEnabled)
    {
        // New in iOS 5.0: Attitude that is referenced to true north
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:(enableHeadingCorrectedMotionMode ? CMAttitudeReferenceFrameXArbitraryZVertical : CMAttitudeReferenceFrameXTrueNorthZVertical)];
        
        motionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(UpdateDeviceMotion:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:motionUpdateTimer forMode:NSRunLoopCommonModes];
        
        [pedometer startPedometer];
        
        motionEnabled = YES;
    }
}

- (void)stopDeviceMotion
{
    if (motionManager && motionEnabled)
    {
        [motionManager stopDeviceMotionUpdates];
        [motionUpdateTimer invalidate];
        
        [pedometer stopPedometer];
        
        motionEnabled = NO;
    }
}

- (void)UpdateDeviceMotion:(NSTimer*)timer
{
    if ((motionManager) && ([motionManager isDeviceMotionActive]))
    {
        if (enableHeadingCorrectedMotionMode)
        {
            CMQuaternion updatedAttitude = self.attitude;
            [self calcAttitudeFromDeviceMotion:motionManager.deviceMotion andHeading:locationManager.locationManager.heading intoQuaternion:&updatedAttitude];
            self.attitude = updatedAttitude;
        }
        else
        {
            self.attitude = motionManager.deviceMotion.attitude.quaternion;
        }
        
        [pedometer processMotion:motionManager.deviceMotion];
    }
}

- (void)calcAttitudeFromDeviceMotion:(CMDeviceMotion *)devMotion andHeading:(CLHeading *)heading intoQuaternion:(CMQuaternion *)outquat
{
    // Phone reference frame: x right, y top, z up from screen
    // Earth reference frame: x north, y west, z up
    // Earth to phone (using attitude): Yaw (z) - Pitch (x) - Roll (y)
    
    // Euler angle extraction from quaternions, using formula for Euler Angle Sequence
    // "Representing Attitude: Euler Angles, Unit Quaternions, and Rotation Vectors"
    // James Diebel, Stanford University, 20 October, 2006
    
    CMQuaternion q_cmquat = devMotion.attitude.quaternion;
    GLKQuaternion quat_orig = GLKQuaternionMake(q_cmquat.x, q_cmquat.y, q_cmquat.z, q_cmquat.w);
    
    GLKVector3 x_device = GLKVector3Make(1.0, 0.0, 0.0);
    GLKVector3 x_device_earth = GLKVector3Normalize(GLKQuaternionRotateVector3(quat_orig, x_device));
    GLKVector3 y_device = GLKVector3Make(0.0, 1.0, 0.0);
    GLKVector3 y_device_earth = GLKVector3Normalize(GLKQuaternionRotateVector3(quat_orig, y_device));
    GLKVector3 los_device = GLKVector3Make(0.0, 0.0, -1.0); // LOS of the device is -ve z-axis
    GLKVector3 los_device_earth = GLKVector3Normalize(GLKQuaternionRotateVector3(quat_orig, los_device));
    GLKVector3 z_axis_earth = GLKVector3Make(0.0, 0.0, 1.0);
    
    GLKVector3 los_device_earth_projected_orig = [self projectVector:los_device_earth ontoPlaneWithNormal:z_axis_earth];

    // Roll is calculated from the angle between x_device and z_axis in Earth frame
    // (true in Yaw-Pitch-Roll rotation, since in first two rotations, yaw-pitch, x-axis remains perpendicular to z)
    double theta_x = [self calculateAngleBetweenVector:x_device_earth andVector:z_axis_earth];
    double roll =  (y_device_earth.z >= 0.0 ? -(M_PI_2 - theta_x) : -(M_PI_2 + theta_x));
    
    // Pitch is calculated from the angle between the LOS axis and the -z Earth axis (straight down)
    double pitch = [self calculateAngleBetweenVector:los_device_earth andVector:GLKVector3MultiplyScalar(z_axis_earth, -1.0)];

    double corrected_heading = heading.trueHeading;
    
    if (pitch > pitch_heading_flip_limit)
    {
        if (heading.trueHeading < 180.0)
        {
            corrected_heading += 180.0;
        }
        else
        {
            corrected_heading -= 180.0;
        }
    }
    
    // Yaw is calculated from the heading
    double yaw_temp = -(90.0 + corrected_heading);
    yaw_temp = yaw_temp + (yaw_temp < -180.0 ? 360.0 : (yaw_temp > 180.0 ? -360.0 : 0.0));
    double yaw = yaw_temp * M_PI/180.0;
    
//    NSLog(@"YPR: %f, %f, %f, theta_x: %f", yaw * 180.0/M_PI, pitch * 180.0/M_PI, roll * 180.0/M_PI, theta_x * 180.0/M_PI);

    // Form a new reference frame corrected by the heading
    GLKQuaternion quat_angle1 = GLKQuaternionMakeWithAngleAndAxis(-yaw, 0.0, 0.0, 1.0);
    GLKQuaternion quat_angle2 = GLKQuaternionMakeWithAngleAndAxis(-pitch, 1.0, 0.0, 0.0);
    GLKQuaternion quat_angle3 = GLKQuaternionMakeWithAngleAndAxis(-roll, 0.0, 1.0, 0.0);
    
    GLKQuaternion quat_first_sequence = GLKQuaternionNormalize(GLKQuaternionMultiply(quat_angle2, quat_angle1));
    GLKQuaternion quat_from_heading = GLKQuaternionNormalize(GLKQuaternionInvert(GLKQuaternionNormalize(GLKQuaternionMultiply(quat_angle3, quat_first_sequence))));
    
    // Now calculate the angle between the LOS axis projected onto the Earth frame using the original quaternion and the corrected quaternion
    // This step does not work if the LOS approaches either pole (phone looking straight up or straight down)
    GLKVector3 los_device_earth_from_heading = GLKVector3Normalize(GLKQuaternionRotateVector3(quat_from_heading, los_device));
    GLKVector3 los_device_earth_projected_from_heading = [self projectVector:los_device_earth_from_heading ontoPlaneWithNormal:z_axis_earth];
    double theta_yaw = [self calculateSignedAngleBetween2DVector:GLKVector2Make(los_device_earth_projected_orig.x, los_device_earth_projected_orig.y)
                                                       andVector:GLKVector2Make(los_device_earth_projected_from_heading.x, los_device_earth_projected_from_heading.y)];
    
    // Rotate the original quaternion by this correction factor which takes into account heading delta (this prevents choppiness from weird angle combinations)
    GLKQuaternion quat_yaw_delta = GLKQuaternionMakeWithAngleAndAxis(theta_yaw, 0.0, 0.0, 1.0);
    GLKQuaternion quat_final = GLKQuaternionNormalize(GLKQuaternionMultiply(quat_yaw_delta, quat_orig));
    
    // Slerp (spherical quaternion interpolation) performed to trend towards corrected attitude without introducing jitter
    if (!isnan(quat_prev.x) && !isnan(quat_prev.y) && !isnan(quat_prev.z) && !isnan(quat_prev.w))
    {
        quat_final = GLKQuaternionSlerp(quat_prev, quat_final, quaternion_slerp_interpolation_factor);
    }
    
    // Store for Slerping on next cycle
    quat_prev = quat_final;
    
    outquat->x = quat_final.x;
    outquat->y = quat_final.y;
    outquat->z = quat_final.z;
    outquat->w = quat_final.w;
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

- (double) calculateSignedAngleBetween2DVector:(GLKVector2)a andVector:(GLKVector2)b
{
    // Uses the 2D Perp Dot Product to find the signed angle
    // http://mathworld.wolfram.com/PerpDotProduct.html
    return atan2(a.x*b.y - a.y*b.x, GLKVector2DotProduct(a, b));
}

- (euler_angles) calculateAngleSequence313FromQuaterion:(GLKQuaternion *)q
{
    euler_angles angleSequence;
    
    angleSequence.theta3 = atan2(2.0*q->x*q->z - 2.0*q->w*q->y, 2.0*q->y*q->z + 2.0*q->w*q->x);
    angleSequence.theta2 = acos(q->z*q->z - q->y*q->y - q->x*q->x + q->w*q->w);
    angleSequence.theta1 = atan2(2.0*q->x*q->z + 2.0*q->w*q->y, -2.0*q->y*q->z + 2.0*q->w*q->x);
    
    return angleSequence;
}

- (euler_angles) calculateAngleSequence213FromQuaterion:(GLKQuaternion *)q
{
    euler_angles angleSequence;
    
    angleSequence.theta3 = atan2(-2.0*q->x*q->z + 2.0*q->w*q->y, q->z*q->z - q->y*q->y - q->x*q->x + q->w*q->w);
    angleSequence.theta2 = asin(2.0*q->y*q->z + 2.0*q->w*q->x);
    angleSequence.theta1 = atan2(-2.0*q->x*q->y + 2.0*q->w*q->z, q->y*q->y - q->z*q->z + q->w*q->w - q->x*q->x);
    
    return angleSequence;
}

- (void)changeHeadingCorrectedMotionMode:(bool)enableMode
{
    enableHeadingCorrectedMotionMode = enableMode;
    
    if (motionEnabled)
    {
        // Force a restart to change reference frame
        [self stopDeviceMotion];
        [self startDeviceMotion];
    }
}

@end
