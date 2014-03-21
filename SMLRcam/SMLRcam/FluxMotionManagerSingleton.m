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
const float yaw_drift_correction_gain = 0.05;

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
        calculatedInitialMagnetometer = NO;
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

# pragma mark - Heading-Corrected Orientation

- (void)calcAttitudeFromDeviceMotion:(CMDeviceMotion *)devMotion andHeading:(CLHeading *)heading intoQuaternion:(CMQuaternion *)outquat
{
    // Phone reference frame: x right, y top, z up from screen
    // Earth reference frame: x north, y west, z up
    // Earth to phone (using attitude): Yaw (z) - Pitch (x) - Roll (y)
    
    CMQuaternion q_cmquat = devMotion.attitude.quaternion;
    GLKQuaternion quat_orig = GLKQuaternionMake(q_cmquat.x, q_cmquat.y, q_cmquat.z, q_cmquat.w);
    
    double delta_yaw_temp = 0.0;
    
    if (!calculatedInitialMagnetometer)
    {
//        GLKVector3 m_vector = GLKVector3Make(devMotion.magneticField.field.x, devMotion.magneticField.field.y, devMotion.magneticField.field.z);
        GLKVector3 m_vector = GLKVector3Make(heading.x, heading.y, heading.z);
        m_t0 = [self calcVectorProjectionInEarthFrameWithPose:&quat_orig andVector:&m_vector];
        
        if (!isnan(m_t0.x) && !isnan(m_t0.y))
        {
            calculatedInitialMagnetometer = YES;
        }
    }
    else
    {
//        GLKVector3 m_vector = GLKVector3Make(devMotion.magneticField.field.x, devMotion.magneticField.field.y, devMotion.magneticField.field.z);
        GLKVector3 m_vector = GLKVector3Make(heading.x, heading.y, heading.z);
        GLKVector2 m_earth = [self calcVectorProjectionInEarthFrameWithPose:&quat_orig andVector:&m_vector];
        
        delta_yaw_temp = [self calculateSignedAngleBetween2DVector:m_earth andVector:m_t0];
        
        // Filter delta_yaw to remove noise. This is just to correct drift, so it can be very slow response to filter heavily
        delta_yaw = delta_yaw + yaw_drift_correction_gain * [self angleDiffWithAngleA:delta_yaw andAngleB:delta_yaw_temp];
        delta_yaw = [self constrainAngle:delta_yaw];

        NSLog(@"delta_yaw: %f, delta_yaw_temp: %f, m_earth: (%.2f, %.2f)", delta_yaw * 180.0/M_PI, delta_yaw_temp * 180.0/M_PI, m_earth.x, m_earth.y);
    }
    
    // Rotate the original quaternion by this correction factor which corrects for heading drift
    GLKQuaternion quat_yaw_delta = GLKQuaternionMakeWithAngleAndAxis(delta_yaw, 0.0, 0.0, 1.0);
    GLKQuaternion quat_final = GLKQuaternionNormalize(GLKQuaternionMultiply(quat_yaw_delta, quat_orig));
    
    // Slerp (spherical quaternion interpolation) performed to smooth overall pose response (makes it feel heavier, which I prefer)
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

# pragma mark - Math Helper Methods

// Calculate 2D earth-plane projection of input vector (in device frame) in the base reference frame specified by device pose
- (GLKVector2)calcVectorProjectionInEarthFrameWithPose:(GLKQuaternion *)quat andVector:(GLKVector3 *)v_vector
{
    GLKVector3 z_axis_earth = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 v_earth = GLKVector3Normalize(GLKQuaternionRotateVector3(*quat, *v_vector));
    GLKVector3 v_projected_earth = [self projectVector:v_earth ontoPlaneWithNormal:z_axis_earth];
    return GLKVector2Make(v_projected_earth.x, v_projected_earth.y);
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

// Calculates the difference (B-A) between two angles, taking into account wrap-around
- (double)angleDiffWithAngleA:(double)a andAngleB:(double)b
{
    double dif = fmod(b - a + M_PI, 2.0 * M_PI);
    if (dif < 0.0)
        dif += 2.0 * M_PI;
    return dif - M_PI;
}

// Constrains an input angle (in radians) to +/-180 degrees
- (double)constrainAngle:(double)x
{
    x = fmod(x + M_PI, 2.0 * M_PI);
    if (x < 0.0)
        x += 2.0 * M_PI;
    return x - M_PI;
}

// Euler angle extraction from quaternions, using formula for Euler Angle Sequence
// "Representing Attitude: Euler Angles, Unit Quaternions, and Rotation Vectors"
// James Diebel, Stanford University, 20 October, 2006

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

# pragma mark - Debug Utilities

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
