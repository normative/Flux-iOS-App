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
    int valid;
    double x;
    double y;
    double z;
}kfECEF;

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


#endif
