//
//  FluxTransformUtilities.h
//  Flux
//
//  Created by Denis Delorme on 4/4/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxOpenGLCommon.h"
#import <Foundation/Foundation.h>

typedef struct
{
    GLKVector3 normal;
    GLKVector3 translation;
    double rotation[9];
} rntTransforms;



@interface FluxTransformUtilities : NSObject

+ (void) computeImagePoseInECEF:(sensorPose*)iPose
                       userPose:(sensorPose)upose
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
