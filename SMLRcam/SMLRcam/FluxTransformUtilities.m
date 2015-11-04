//
//  FluxTransformUtilities.m
//  Flux
//
//  Created by Denis Delorme on 4/4/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//
#import "FluxOpenGLCommon.h"
#import "FluxTransformUtilities.h"

enum {SOLUTION1 = 0, SOLUTION2, SOLUTION1Neg, SOLUTION2Neg};

@implementation FluxTransformUtilities

+(void)WGS84toECEFWithPose:(sensorPose *)sp
{
    double normal;
    double eccentricity;
    double flatness;
    
    GLKVector3 lla_rad; //latitude, longitude, altitude
    
    lla_rad.x = sp->position.x * M_PI_180;
    lla_rad.y = sp->position.y * M_PI_180;
    lla_rad.z = sp->position.z;
    
    flatness = (a_WGS84 - b_WGS84) / a_WGS84;
    
    eccentricity = sqrt(flatness * (2 - flatness));
    normal = a_WGS84 / sqrt(1 - (eccentricity * eccentricity * sin(lla_rad.x) * sin(lla_rad.x)));
    
    sp->ecef.x = (lla_rad.z + normal) * cos(lla_rad.x) * cos(lla_rad.y);
    sp->ecef.y = (lla_rad.z + normal) * cos(lla_rad.x) * sin(lla_rad.y);
    sp->ecef.z = (lla_rad.z + (1 - eccentricity * eccentricity) * normal) * sin(lla_rad.x);
}

+(void)setupRotationMatrix:(float *)rotation fromPose:(sensorPose *)sp
{
    GLKVector3 lla_rad; //latitude, longitude, altitude
    
    lla_rad.x = sp->position.x * M_PI_180;
    lla_rad.y = sp->position.y * M_PI_180;
    lla_rad.z = sp->position.z;
    
    rotation[0]  = -1.0 * sin(lla_rad.y);
    rotation[1]  = cos(lla_rad.y);
    rotation[2]  = 0.0;
    rotation[3]  = 0.0;
    rotation[4]  = -1.0 * cos(lla_rad.y) * sin(lla_rad.x);
    rotation[5]  = -1.0 * sin(lla_rad.x) * sin(lla_rad.y);
    rotation[6]  = cos(lla_rad.x);
    rotation[7]  = 0.0;
    rotation[8]  = cos(lla_rad.x) * cos(lla_rad.y);
    rotation[9]  = cos(lla_rad.x) * sin(lla_rad.y);
    rotation[10] = sin(lla_rad.x);
    rotation[11] = 0.0;
    rotation[12] = 0.0;
    rotation[13] = 0.0;
    rotation[14] = 0.0;
    rotation[15] = 1.0;
}

+(void)tangentplaneRotation:(GLKMatrix4 *)rot_M fromPose:(sensorPose *)sp
{
    float rotation_te[16];

    [FluxTransformUtilities setupRotationMatrix:rotation_te fromPose:sp];

    *rot_M = GLKMatrix4Transpose(GLKMatrix4MakeWithArray(rotation_te));
}


#pragma -- WGS84 tranforms

+(GLKMatrix4)computeInverseRotationMatrixFromPose:(sensorPose*) sp
{
    
    float rotation_te[16];
    
    [FluxTransformUtilities setupRotationMatrix:rotation_te fromPose:sp];

    return GLKMatrix4MakeWithArray(rotation_te);
    
}

+ (int) solutionBasedOnNormalWithNormal1:(double *) normal1 withNormal2:(double*)normal2 withPlaneNormal:(GLKVector3) planeNormal
{
    int solution1 = SOLUTION1;
    int solution2 = SOLUTION2;
    
    GLKVector3 normal1V = GLKVector3Make(normal1[0], normal1[1], normal1[2]);
    GLKVector3 normal2V = GLKVector3Make(normal2[0], normal2[1], normal2[2]);
    normal1V    = GLKVector3Normalize(normal1V);
    normal2V    = GLKVector3Normalize(normal2V);
    planeNormal = GLKVector3Normalize(planeNormal);

    double dotProduct1 = GLKVector3DotProduct(normal1V, planeNormal);
    double dotProduct2 = GLKVector3DotProduct(normal2V, planeNormal);
    if(dotProduct1 <0)
    {
        normal1V = GLKVector3Make(-1.0 * normal1V.x, -1.0* normal1V.y, -1.0*normal1V.z);
        dotProduct1 = GLKVector3DotProduct(normal1V, planeNormal);
        solution1 = SOLUTION1Neg;
    }
    if(dotProduct2 <0)
    {
        normal2V = GLKVector3Make(-1.0 * normal2V.x, -1.0* normal2V.y, -1.0*normal2V.z);
        dotProduct2 = GLKVector3DotProduct(normal2V, planeNormal);
        solution2 = SOLUTION2Neg;
    }
    
    
    return (dotProduct1 > dotProduct2) ? solution1:solution2;
}

+ (void) arrayDataCopyWithLeft:(double*)left andRight:(double*)right withSize:(int)size withFactor :(double)factor
{
    int i;
    for (i =0; i< size; i++)
    {
        left[i] = factor* right[i];
    }
}



+ (void) computeImagePoseInECEF:(sensorPose*)iPose userPose:(sensorPose*)upose hTranslation1:(double*)translation1 hRotation1:(double *)rotation1 hNormal1:(double *)normal1 hTranslation2:(double*)translation2 hRotation2:(double *)rotation2 hNormal2:(double *)normal2
{
    float rotation44[16];
    
    double rotation[9];
    double translation[3];
    double normal[3];
    GLKVector3 cameraNormal = GLKVector3Make(0.0, 0.0, 1.0);
    
    GLKMatrix4 transformMat = GLKMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);
    
    
//    //DEBUG code
//    rntTransforms transforms[4];
//
//    transforms[0].translation.x = translation1[0];
//    transforms[0].translation.y = translation1[1];
//    transforms[0].translation.z = translation1[2];
//    
//    transforms[1].translation.x = translation2[0];
//    transforms[1].translation.y = translation2[1];
//    transforms[1].translation.z = translation2[2];
//    
//    transforms[2].translation.x = -1.0*translation1[0];
//    transforms[2].translation.y = -1.0*translation1[1];
//    transforms[2].translation.z = -1.0*translation1[2];
//    
//    transforms[3].translation.x = -1.0*translation2[0];
//    transforms[3].translation.y = -1.0*translation2[1];
//    transforms[3].translation.z = -1.0*translation2[2];
//    
//    
//    transforms[0].normal.x =  normal1[0];
//    transforms[0].normal.y =  normal1[1];
//    transforms[0].normal.z =  normal1[2];
//    
//    transforms[1].normal.x =  normal2[0];
//    transforms[1].normal.y =  normal2[1];
//    transforms[1].normal.z =  normal2[2];
//    
//    transforms[2].normal.x =  -1.0 * normal1[0];
//    transforms[2].normal.y =  -1.0 * normal1[1];
//    transforms[2].normal.z =  -1.0 * normal1[2];
//    
//    transforms[3].normal.x =  -1.0 * normal2[0];
//    transforms[3].normal.y =  -1.0 * normal2[1];
//    transforms[3].normal.z =  -1.0 * normal2[2];
//    
//    for(int i=0;i<4;i++)
//    {
//        transforms[i].translation =GLKMatrix4MultiplyVector3(transformMat, transforms[i].translation);
//        transforms[i].normal =GLKMatrix4MultiplyVector3(transformMat, transforms[i].normal);
//    }
//    
//    //DEBUG ends
    
    int solution = 0;
    
    solution = [self solutionBasedOnNormalWithNormal1:normal1
                                          withNormal2:normal2
                                      withPlaneNormal:cameraNormal];
    switch(solution)
    {
        case SOLUTION1:
            [self arrayDataCopyWithLeft:rotation andRight:rotation1 withSize:9 withFactor:1.0];
            [self arrayDataCopyWithLeft:translation andRight:translation1 withSize:3 withFactor:1.0];
            [self arrayDataCopyWithLeft:normal andRight:normal1 withSize:3 withFactor:1.0];
            break;
        case SOLUTION1Neg:
            [self arrayDataCopyWithLeft:rotation andRight:rotation1 withSize:9 withFactor:1.0];
            [self arrayDataCopyWithLeft:translation andRight:translation1 withSize:3 withFactor:-1.0];
            [self arrayDataCopyWithLeft:normal andRight:normal1 withSize:3 withFactor:-1.0];
            break;
        case SOLUTION2:
            [self arrayDataCopyWithLeft:rotation andRight:rotation2 withSize:9 withFactor:1.0];
            [self arrayDataCopyWithLeft:translation andRight:translation2 withSize:3 withFactor:1.0];
            [self arrayDataCopyWithLeft:normal andRight:normal2 withSize:3 withFactor:1.0];
            break;
        case SOLUTION2Neg:
            [self arrayDataCopyWithLeft:rotation andRight:rotation2 withSize:9 withFactor:1.0];
            [self arrayDataCopyWithLeft:translation andRight:translation2 withSize:3 withFactor:-1.0];
            [self arrayDataCopyWithLeft:normal andRight:normal2 withSize:3 withFactor:-1.0];
            break;
            
            
    }
    
    //rotation
    rotation44[0] = rotation[0];
    rotation44[1] = rotation[1];
    rotation44[2] = rotation[2];
    rotation44[3]= 0.0;
    rotation44[4] = rotation[3];
    rotation44[5] = rotation[4];
    rotation44[6] = rotation[5];
    rotation44[7]= 0.0;
    rotation44[8] = rotation[6];
    rotation44[9] = rotation[7];
    rotation44[10] = rotation[8];
    rotation44[11]= 0.0;
    rotation44[12]= 0.0;
    rotation44[13]= 0.0;
    rotation44[14]= 0.0;
    rotation44[15]= 1.0;
    
    
    GLKMatrix4 rotationMatrix = GLKMatrix4MakeWithArray(rotation44);
    
    GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    
    positionTP.x = 15.0*translation[0];
    positionTP.y = 15.0*translation[1];
    positionTP.z = 15.0 *translation[2];
    
    positionTP = GLKMatrix4MultiplyVector3(transformMat, positionTP);
    
    iPose->position = positionTP;
    
    GLKMatrix4 rotationMatrixT = GLKMatrix4Multiply(transformMat, rotationMatrix);
    
    iPose->rotationMatrix = rotationMatrixT;
    
    //User pose matrix in tangent plane
    GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    matrixTP = GLKMatrix4Identity;
    GLKMatrix4 planeRMatrix = GLKMatrix4Multiply(matrixTP, upose->rotationMatrix);
    
    iPose->rotationMatrix =GLKMatrix4Multiply(planeRMatrix, rotationMatrixT);
    
    iPose->position = GLKMatrix4MultiplyVector3(planeRMatrix, iPose->position);

    //ecef
    iPose->position = GLKMatrix4MultiplyVector3([self computeInverseRotationMatrixFromPose:upose], iPose->position);
    iPose->ecef = GLKVector3Add(upose->ecef, iPose->position);
    
}

+ (GLKMatrix4) computeNormalTransformMatrix:(double*)normal
{
    
    //rotate camera onto plane
    GLKVector3 cameraNormal = GLKVector3Make(0.0,0.0, 1.0);
    GLKVector3 planeNormal = GLKVector3Make (normal[0], normal[1], normal[2]);
    
    planeNormal = GLKVector3Normalize(planeNormal);
    
    
    GLKVector3 axis = GLKVector3CrossProduct(cameraNormal, planeNormal);
    axis = GLKVector3Normalize(axis);
    float dotP = GLKVector3DotProduct(cameraNormal, planeNormal);
    
    float l1 = 1.0;
    float l2 = sqrtf(planeNormal.x *planeNormal.x + planeNormal.y * planeNormal.y + planeNormal.z*planeNormal.z);
    
    float angle = acosf(dotP/l1 * l2);
    
    bool invertible;
    
    GLKMatrix4 result =  GLKMatrix4MakeRotation(angle, axis.x,axis.y, axis.z);
    result = GLKMatrix4Invert(result, &invertible);
    
    return result;
}

+(void)convertVector3:(GLKVector3)vec toDoubleArray:(double *)a
{
    a[0] = vec.v[0];
    a[1] = vec.v[1];
    a[2] = vec.v[2];
}

+(void)convertMatrix3:(GLKMatrix3)mat toDoubleArray:(double *)a
{
    for (int i = 0; i < 9; i++)
    {
        a[i] = mat.m[i];
    }
}

+(void)convertDoubleArray:(double *)a toMatrix3:(GLKMatrix3 *)mat
{
    for (int i = 0; i < 9; i++)
    {
         mat->m[i] = a[i];
    }
    
}

+(void)convertDoubleArray:(double *)a toVector3:(GLKVector3 *)vec
{
    for (int i = 0; i < 3; i++)
    {
        vec->v[i] = a[i];
    }
}

+(void)deepCopyDoubleTo:(double *)dest fromDoubleArray:(double *)src withSize:(int)size
{
//    for (int i = 0; i < size; i++)
//    {
//        dest[i] = src[i];
//    }
    memcpy(dest, src, size * sizeof(double));
}


@end