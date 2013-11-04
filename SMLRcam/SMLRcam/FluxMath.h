//
//  FluxMath.h
//  Flux
//
//  Created by Arjun Chopra on 8/29/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#ifndef Flux_FluxMath_h
#define Flux_FluxMath_h


static __inline__ GLKMatrix4 Matrix4MakeFromYawPitchRoll(float yaw, float pitch, float roll);

// Creates a new quaternion from specified yaw, pitch and roll angles
static __inline__ GLKQuaternion QuaternionMakeFromYawPitchRoll(float yaw, float pitch, float roll);


static __inline__ GLKMatrix4 Matrix4MakeFromYawPitchRoll(float yaw, float pitch, float roll)
{
    //GLKMatrix4 matrix;
    GLKQuaternion quaternion;
    
    quaternion = QuaternionMakeFromYawPitchRoll(yaw, pitch, roll);
    
    return GLKMatrix4MakeWithQuaternion(quaternion);
}


static __inline__ GLKQuaternion QuaternionMakeFromYawPitchRoll(float yaw, float pitch, float roll)
{
    GLKQuaternion quaternion;
    
    
    quaternion.x = (((float)cos((double)(yaw * 0.5f)) * (float)sin((double)(pitch * 0.5f))) * (float)cos((double)(roll * 0.5f)))  - (((float)sin((double)(yaw * 0.5f)) * (float)cos((double)(pitch * 0.5f))) * (float)sin((double)(roll * 0.5f)));

    quaternion.y = (((float)sin((double)(yaw * 0.5f)) * (float)cos((double)(pitch * 0.5f))) * (float)cos((double)(roll * 0.5f))) - (((float)cos((double)(yaw * 0.5f)) * (float)sin((double)(pitch * 0.5f))) * (float)sin((double)(roll * 0.5f)));

    quaternion.z = (((float)cos((double)(yaw * 0.5f)) * (float)cos((double)(pitch * 0.5f))) * (float)sin((double)(roll * 0.5f))) - (((float)sin((double)(yaw * 0.5f)) * (float)sin((double)(pitch * 0.5f))) * (float)cos((double)(roll * 0.5f)));

    quaternion.w = (((float)cos((double)(yaw * 0.5f)) * (float)cos((double)(pitch * 0.5f))) * (float)cos((double)(roll * 0.5f))) -  (((float)sin((double)(yaw * 0.5f)) * (float)sin((double)(pitch * 0.5f))) * (float)sin((double)(roll * 0.5f)));
  
    return quaternion;
}

#endif
