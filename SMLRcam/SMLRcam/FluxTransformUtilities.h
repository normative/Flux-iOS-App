//
//  FluxTransformUtilities.h
//  Flux
//
//  Created by Denis Delorme on 4/4/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxOpenGLCommon.h"
#import <Foundation/Foundation.h>

#define M_PI_180    (double)(M_PI / 180.0)

#define a_WGS84 6378137.0
#define b_WGS84 6356752.3142

typedef struct
{
    GLKVector3 normal;
    GLKVector3 translation;
    double rotation[9];
} rntTransforms;


@interface FluxTransformUtilities : NSObject

+(void)WGS84toECEFWithPose:(sensorPose *)sp;
+(void)setupRotationMatrix:(float *)rotation fromPose:(sensorPose *)sp;
+(void)tangentplaneRotation:(GLKMatrix4 *)rot_M fromPose:(sensorPose *)sp;

+ (void) computeImagePoseInECEF:(sensorPose*)iPose
                       userPose:(sensorPose*)upose
                  hTranslation1:(double*)translation1
                     hRotation1:(double *)rotation1
                       hNormal1:(double *)normal1
                  hTranslation2:(double*)translation2
                     hRotation2:(double *)rotation2
                       hNormal2:(double *)normal2;

+(void)convertVector3:(GLKVector3)vec toDoubleArray:(double *)a;
+(void)convertMatrix3:(GLKMatrix3)mat toDoubleArray:(double *)a;
+(void)convertDoubleArray:(double *)a toMatrix3:(GLKMatrix3 *)mat;
+(void)convertDoubleArray:(double *)a toVector3:(GLKVector3 *)vec;
+(void)deepCopyDoubleTo:(double *)dest fromDoubleArray:(double *)src withSize:(int)size;

@end
