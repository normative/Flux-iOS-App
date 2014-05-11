//
//  FluxOpenGLCommon.h
//  Flux
//
//  Created by Denis Delorme on 10/27/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#ifndef Flux_FluxOpenGLCommon_h
#define Flux_FluxOpenGLCommon_h

#import <GLKit/GLKit.h>

typedef struct{
    double rotation[9];
    double translation[3];
    double normal[3];
} transformRtn;

typedef struct{
    int valid;
    double x;
    double y;
    double z;
}kfECEF;




typedef struct{
    double latitude;
    double longitude;
    double altitude;
}Geolocation;




typedef struct{
    
    float gpsx;
    float gpsy;
    float filterx;
    float filtery;
}kfDEBUG;

typedef struct{
    GLKVector3 origin;
    GLKVector3 at;
    GLKVector3 up;
} viewParameters;

typedef struct {
    int validECEFEstimate;
    GLKMatrix4 rotationMatrix;
    GLKVector3 rotation_ypr;
    GLKVector3 position;
    GLKVector3 ecef;
} sensorPose;

typedef struct {
    float pixelSize;
    float yPixels;
    float xPixels;
    float focalLength;
} fluxCameraParameters;

typedef struct {
    GLKVector3 origin;
    GLKVector3 at;
    float fov;
} tapParameters;
#endif
