//
//  ImageViewerViewController.m
//  ImageViewer
//
//  Created by Arjun Chopra on 8/11/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//

#import "FluxOpenGLViewController.h"
#import "ImageViewerImageUtil.h"
#import "FluxMath.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#pragma mark - OpenGL globals and types

#define GetGLError()									\
{														\
GLenum err = glGetError();							\
while (err != GL_NO_ERROR) {						\
NSLog(@"GLError %s set in File:%s Line:%d\n",	\
GetGLErrorString(err),					\
__FILE__,								\
__LINE__);								\
err = glGetError();								\
}													\
}

const float MAX_IMAGE_RADIUS = 15.0;

const int number_textures = 5;

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    
    UNIFORM_TBIASMVP_MATRIX0,
    UNIFORM_TBIASMVP_MATRIX1,
    UNIFORM_TBIASMVP_MATRIX2,
    UNIFORM_TBIASMVP_MATRIX3,
    UNIFORM_TBIASMVP_MATRIX4,
    UNIFORM_TBIASMVP_MATRIX5,
    UNIFORM_TBIASMVP_MATRIX6,
    UNIFORM_TBIASMVP_MATRIX7,
    
    UNIFORM_MYTEXTURE_SAMPLER0,
    UNIFORM_MYTEXTURE_SAMPLER1,
    UNIFORM_MYTEXTURE_SAMPLER2,
    UNIFORM_MYTEXTURE_SAMPLER3,
    UNIFORM_MYTEXTURE_SAMPLER4,
    UNIFORM_MYTEXTURE_SAMPLER5,
    UNIFORM_MYTEXTURE_SAMPLER6,
    UNIFORM_MYTEXTURE_SAMPLER7,
    
    UNIFORM_RENDER_ENABLE0,
    UNIFORM_RENDER_ENABLE1,
    UNIFORM_RENDER_ENABLE2,
    UNIFORM_RENDER_ENABLE3,
    UNIFORM_RENDER_ENABLE4,
    UNIFORM_RENDER_ENABLE5,
    UNIFORM_RENDER_ENABLE6,
    UNIFORM_RENDER_ENABLE7,
    
    NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

GLfloat testvertexData[18] =
{
    
    1.0f, 1.0f, 0.0f,
    -1.0f, 1.0f, 0.0f,
    1.0f, -1.0f, 0.0f,
    1.0f, -1.0f, 0.0f,
    -1.0f, 1.0f, 0.0f,
    -1.0f, -1.0f, 0.0f
};

/*
 GLfloat textureCoord[12] =
 {
 
 1.0f, 1.0f,
 0.0f, 1.0f,
 1.0f, 0.0f,
 1.0f, 0.0f,
 0.0f, 1.0f,
 0.0f, 0.0f
 };
 */

GLfloat textureCoord[12] =
{
    
    0.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f
};


GLubyte indexdata[6]={0,1,2,3,4,5};

//iPhone5 model

float iPhone5_pixelsize = 0.0000014; //1.4 microns
int   iPhone5_ypixels = 3264;
int   iPhone5_xpixels = 2448;
float iPhone5_focalLength = 0.0041; //4.10 mm

GLuint texture[3];
GLKMatrix4 camera_perspective;


GLKMatrix4 tProjectionMatrix;
GLKMatrix4 tViewMatrix;
GLKMatrix4 tModelMatrix;
GLKMatrix4 tMVP;
GLKMatrix4 biasMatrix;

GLKMatrix4 InvViewMat;

GLKMatrix4 rotationMat;
GLKMatrix4 rotationMat1;
GLKMatrix4 rotationMat2;
GLKMatrix4 basenormalMat;

GLKVector3 centrevec;
GLKVector3 centrevec1;
GLKVector3 centrevec2;

GLKVector3 upvec;
GLKVector3 upvec1;
GLKVector3 upvec2;

GLKVector3 eye_up;
GLKVector3 eye_origin;
GLKVector3 eye_at;

GLKVector3 ray_origin;
GLKVector3 ray_origin1;
GLKVector3 ray_origin2;

demoImage *image;
demoImage *image1;
demoImage *image2;
GLfloat g_vertex_buffer_data[18];
GLKVector4 result[4];

#pragma mark - OpenGL Utility Routines

void init_pose()
{
    
}

void init_camera_model()
{
	float _fov = 2 * atan2(iPhone5_pixelsize*3264.0/2.0, iPhone5_focalLength); //radians
    fprintf(stderr,"FOV = %.4f degrees\n", _fov *180.0/3.14);
    float aspect = (float)iPhone5_xpixels/(float)iPhone5_ypixels;
    camera_perspective = 	GLKMatrix4MakePerspective(_fov, aspect, 0.001f, 50.0f);
    
}

#define PI 3.1415926535898
#define a_WGS84 6378137.0
#define b_WGS84 6356752.3142

GLKMatrix4 rotation_teM;

void WGS84_to_ECEF(sensorPose *sp){
    double normal;
    double eccentricity;
    double flatness;
    
    GLKVector3 lla_rad; //latitude, longitude, altitude
    
    lla_rad.x = sp->position.x*PI/180.0;
    lla_rad.y = sp->position.y*PI/180.0;
    lla_rad.z = sp->position.z;
    
    flatness = (a_WGS84 - b_WGS84) / a_WGS84;
    
    eccentricity = sqrt(flatness * (2 - flatness));
    normal = a_WGS84 / sqrt(1 - (eccentricity * eccentricity * sin(lla_rad.x) *sin(lla_rad.x)));
    
    sp->ecef.x = (lla_rad.z + normal)* cos(lla_rad.x) * cos(lla_rad.y);
    sp->ecef.y = (lla_rad.z + normal)* cos(lla_rad.x) * sin(lla_rad.y);
    sp->ecef.z = (lla_rad.z + (1- eccentricity* eccentricity)*normal)* sin(lla_rad.x);
    
    
}

void tangentplaneRotation(sensorPose *sp){
    
    float rotation_te[16];
    
    GLKVector3 lla_rad; //latitude, longitude, altitude
    
    lla_rad.x = sp->position.x*PI/180.0;
    lla_rad.y = sp->position.y*PI/180.0;
    lla_rad.z = sp->position.z;
    
    rotation_te[0] = -1.0 * sin(lla_rad.y);
    rotation_te[1] = cos(lla_rad.y);
    rotation_te[2] = 0.0;
    rotation_te[3]= 0.0;
    rotation_te[4] = -1.0 * cos(lla_rad.y)* sin(lla_rad.x);
    rotation_te[5] = -1.0 * sin(lla_rad.x) * sin(lla_rad.y);
    rotation_te[6] = cos(lla_rad.x);
    rotation_te[7]= 0.0;
    rotation_te[8] = cos(lla_rad.x) * cos(lla_rad.y);
    rotation_te[9] = cos(lla_rad.x) * sin(lla_rad.y);
    rotation_te[10] = sin(lla_rad.x);
    rotation_te[11]= 0.0;
    rotation_te[12]= 0.0;
    rotation_te[13]= 0.0;
    rotation_te[14]= 0.0;
    rotation_te[15]= 1.0;
    
    rotation_teM = GLKMatrix4Transpose(GLKMatrix4MakeWithArray(rotation_te));
    
}

void setParametersTP(GLKVector3 location)
{
    
}

void setupRenderingPlane(GLKVector3 position, GLKMatrix4 rotationMatrix, float distance)
{
    GLKVector4 pts[4];
    int i;
 
    if(distance <0.0)
    {
        NSLog(@"Distance is scalar should not be negative ... converting to positive");
    }
    
    pts[0] = GLKVector4Make(-250.0, -250.0, -1.0 *distance, 1.0);
    pts[1] = GLKVector4Make( 250.0, -250.0, -1.0 *distance, 1.0);
    pts[2] = GLKVector4Make( 250.0, 250.0, -1.0 * distance, 1.0);
    pts[3] = GLKVector4Make(-250.0, 250.0, -1.0 *distance, 1.0);
    
    // fprintf(stderr, "NEW VECTORS\n");
    for(i=0;i<4;i++)
    {
        result[i] = GLKMatrix4MultiplyVector4( (rotationMatrix), pts[i]);
    
    }
}
void calculateCoordinatesTP(GLKVector3 originposition, GLKVector3 position, GLKVector3 *positionTP)
{
    
}

int computeProjectionParametersUser(sensorPose *usp, GLKVector3 *planeNormal, float distance, viewParameters *vp)
{
    viewParameters viewP;
	GLKVector3 positionTP;
    positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    //sp->rotation = Matrix4MakeFromYawPitchRoll(sp->.x, sp->position.y, sp->position.z);
    if(distance <0.0)
    {
        NSLog(@"distance is a scalar, setting to positive");
        distance =  -1.0 *distance;
    }
    
    setParametersTP(usp->position);
    
    WGS84_to_ECEF(usp);
    
    tangentplaneRotation(usp);
    // rotationMat = rotationMat_t;
    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(usp->rotationMatrix, zRay);
    
    //NSLog(@"Projection vector: [%f, %f, %f]", v.x, v.y, v.z);
    
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3((usp->rotationMatrix), planeNormalI);
    //intersection with plane
    GLKVector3 N = planeNormalRotated;
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
    float vd = GLKVector3DotProduct(N,V);
    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
    float t = v0/vd;
    
    if(vd==0)
    {
       // NSLog(@"UserPose :Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
        return -1;
    }
    if(t < 0)
    {
        
       // NSLog(@"UserPose: Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
        return -1;
    }
    
    viewP.at = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
    viewP.up = GLKMatrix4MultiplyVector3(usp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    //viewP.up = GLKVector3Normalize(viewP.up);
    
    (*vp).origin = GLKVector3Add(positionTP, P0);
    //(*vp).at = GLKVector3Add(positionTP, viewP.at);
    
    (*vp).at =V;
    (*vp).up = viewP.up;
    
    //setupRenderingPlane(positionTP, usp->rotationMatrix, distance);
    
    return 0;
}

//distance - distance of plane
int computeProjectionParametersImage(sensorPose *sp, GLKVector3 *planeNormal, float distance, sensorPose userPose, viewParameters *vp)
{
    
    viewParameters viewP;
	GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    
    if(distance <0.0)
    {
        NSLog(@"distance is a scalar, setting to positive");
        distance =  -1.0 *distance;
    }
    
    
    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(sp->rotationMatrix, zRay);
    
    
    //    NSLog(@"Projection vector: [%f, %f, %f]", v.x, v.y, v.z);
    
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3((userPose.rotationMatrix), planeNormalI);
    
    //intersection with plane
    GLKVector3 N = planeNormalRotated;
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
//    
//    float vd = GLKVector3DotProduct(N,V);
//    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
//    float t = v0/vd;
//    
//    if(vd==0)
//    {
//        NSLog(@"Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
//        return -1;
//    }
//    if(t < 0)
//    {
//        
//        NSLog(@"Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
//        return -1;
//    }
    
    WGS84_to_ECEF(sp);
    
    
    positionTP.x = sp->ecef.x -userPose.ecef.x;
    positionTP.y = sp->ecef.y -userPose.ecef.y;
    positionTP.z = 0;
    //sp->ecef.z -userPose.ecef.z;
    /*
     positionTP.x = 0;
     positionTP.y = 0;
     positionTP.z = 0;
     */
    
    //    positionTP.z = sp->ecef.z -userPose.ecef.z;
    //    NSLog(@"Position delta [%f %f %f]",positionTP.x, positionTP.y, positionTP.z);
    
    positionTP = GLKMatrix4MultiplyVector3(rotation_teM, positionTP);
    //  NSLog(@"Position rotated [%f %f %f]",positionTP.x, positionTP.y, positionTP.z);
    
   // viewP.at = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
   // viewP.up = GLKMatrix4MultiplyVector3(sp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    //    viewP.up = GLKVector3Normalize(viewP.up);
    
    
   // (*vp).origin = GLKVector3Add(positionTP, P0);
    //    (*vp).at = GLKVector3Add(positionTP, viewP.at);
    
   // (*vp).at =GLKVector3Add(positionTP, viewP.at);
    //(*vp).up = viewP.up;
    
    //    setupRenderingPlane(positionTP, sp->rotationMatrix, distance);
    
    
    
    P0 = positionTP;
    V = GLKVector3Normalize(v);
  //  V = v;
    
    float vd = GLKVector3DotProduct(N,V);
    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
    float t = v0/vd;
    
    if(vd==0)
    {
   //    NSLog(@"ImagePose: Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
        return 0;
    }
    if(t < 0)
    {
        
     // NSLog(@"ImagePose: Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
        return 0;
    }
    
    
//    if(distancetoPlane > (distance + 3))
    float _distanceToUser = GLKVector3Length(P0);
    
    if(_distanceToUser > MAX_IMAGE_RADIUS)
    {
        
        //NSLog(@"too far to render %f -> %f", distancetoPlane, distance);
        return 0;
    }

    
    viewP.at = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
    viewP.up = GLKMatrix4MultiplyVector3(sp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    //    viewP.up = GLKVector3Normalize(viewP.up);
    
    
    (*vp).origin =  P0;
    //    (*vp).at = GLKVector3Add(positionTP, viewP.at);
    
    (*vp).at =viewP.at;
    (*vp).up = viewP.up;
    

    
    return 1;
    
    
    
    

}

GLKMatrix4 zMatrix;

void compute_new_intersection()
{
    bool isinvertible;
	
    GLKMatrix4 rotationMat_t= GLKMatrix4Make(
                                             -0.694398, -0.469567, 0.54527, 0, 0.577056, 0.0893289, 0.811804, 0, -0.429905, 0.878366, 0.208937, 0, 0, 0, 0, 1);
    zMatrix = rotationMat_t;
    // rotationMat = GLKMatrix4Invert(rotationMat_t, &isinvertible );
    
    rotationMat = rotationMat_t;
    GLKVector4 _z_ray = GLKVector4Make(0.0, 0.0, -1.0, 1.0);
    GLKVector4 _ray = GLKMatrix4MultiplyVector4(rotationMat, _z_ray);
    GLKVector3 _v = GLKVector3Make(_ray.x, _ray.y, _ray.z);
    
    // NSLog(@"_ray.x = %f, _ray.y = %f, _ray.z = %f", _v.x, _v.y, _v.z);
    //float angle_with_y_deg =  180.0/PI* atan2(sqrt((_v.x*_v.x+_v.z*_v.z)),_v.y);
    float angle_with_y_rad =atan2(sqrt((_v.x*_v.x+_v.z*_v.z)),_v.y);
    // fprintf(stderr,"angle_with_y_deg = %.5f \n", angle_with_y_deg);
    // NSLog(@"angle with y in degrees is %f", angle_with_y_rad* 180.0/3.142);
    
    //normal plane
    
    GLKVector4 _plane_normal = GLKVector4Make(0.0, 0.0, 1.0, 1.0);
    basenormalMat = GLKMatrix4Identity;
    
    basenormalMat = GLKMatrix4RotateWithVector3(basenormalMat, angle_with_y_rad, GLKVector3Make(0.0,0.0, 1.0));
    
    
    GLKVector4 _plane_normal_rotated = GLKMatrix4MultiplyVector4(basenormalMat, _plane_normal);
    float distance = 40.0;
    
    //intersection with plane
    GLKVector3 N = GLKVector3Make(_plane_normal_rotated.x, _plane_normal_rotated.y, _plane_normal_rotated.z);
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(_v);
    //fprintf(stderr,"Ray direction is  = [%.2f, %.2f, %.2f]\n",V.x, V.y, V.z);
    
    float vd = GLKVector3DotProduct(N,V);
    
    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) +distance);
    float t = v0/vd;
    //   fprintf(stderr," t = %.4f\n",t);
    centrevec = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
    
    
    
    GLKVector4 up = GLKMatrix4MultiplyVector4(rotationMat, GLKVector4Make(0.0, 1.0, 0.0, 1.0));
    upvec = GLKVector3Normalize(GLKVector3Make(up.x, up.y, up.z));
    
    
    //set eye
    GLKVector4 _eye_at = GLKMatrix4MultiplyVector4(GLKMatrix4Invert(basenormalMat, &isinvertible) ,GLKVector4Make(0.0, 14.0, 0.0, 1.0));
    eye_at = GLKVector3Make(_eye_at.x, _eye_at.y, _eye_at.z);
    eye_origin = GLKVector3Make(0.0, 0.0, 0.0);
    eye_up = GLKVector3Make(0.0, 0.0, 1.0);
    
    //  NSLog(@"eye_at: %f %f %f", eye_at.x, eye_at.y, eye_at.z);
    //  NSLog(@"eye_origin: %f %f %f", eye_origin.x, eye_origin.y, eye_origin.z);
    // NSLog(@"eye_up: %f, %f %f", eye_up.x, eye_up.y, eye_up.z);
    
}

void compute_new_intersectionZ()
{
    GLKMatrix4 rotationMat_t= GLKMatrix4Make(
                                             -0.694398, -0.469567, 0.54527, 0, 0.577056, 0.0893289, 0.811804, 0, -0.429905, 0.878366, 0.208937, 0, 0, 0, 0, 1);
    zMatrix = rotationMat_t;
    // rotationMat = GLKMatrix4Invert(rotationMat_t, &isinvertible );
    
    rotationMat = rotationMat_t;
    GLKVector4 _z_ray = GLKVector4Make(0.0, 0.0, -1.0, 1.0);
    GLKVector4 _ray = GLKMatrix4MultiplyVector4(rotationMat, _z_ray);
    GLKVector3 _v = GLKVector3Make(_ray.x, _ray.y, _ray.z);
    
    NSLog(@"_ray.x = %f, _ray.y = %f, _ray.z = %f", _v.x, _v.y, _v.z);
    //float angle_with_y_deg =  180.0/PI* atan2(sqrt((_v.x*_v.x+_v.z*_v.z)),_v.y);
    float angle_with_y_rad =atan2(sqrt((_v.x*_v.x+_v.z*_v.z)),_v.y);
    // fprintf(stderr,"angle_with_y_deg = %.5f \n", angle_with_y_deg);
    NSLog(@"angle with y in degrees is %f", angle_with_y_rad* 180.0/3.142);
    
    //normal plane
    /*
     GLKVector4 _plane_normal = GLKVector4Make(0.0, 0.0, 1.0, 1.0);
     basenormalMat = GLKMatrix4Identity;
     
     basenormalMat = GLKMatrix4RotateWithVector3(basenormalMat, angle_with_y_rad, GLKVector3Make(0.0,0.0, 1.0));
     
     
     GLKVector4 _plane_normal_rotated = GLKMatrix4MultiplyVector4(basenormalMat, _plane_normal);
     float distance = 14.0;
     
     //intersection with plane
     GLKVector3 N = GLKVector3Make(_plane_normal_rotated.x, _plane_normal_rotated.y, _plane_normal_rotated.z);
     GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
     GLKVector3 V = GLKVector3Normalize(_v);
     //fprintf(stderr,"Ray direction is  = [%.2f, %.2f, %.2f]\n",V.x, V.y, V.z);
     
     float vd = GLKVector3DotProduct(N,V);
     
     float v0 = -1.0 * (GLKVector3DotProduct(N,P0) +distance);
     float t = v0/vd;
     //   fprintf(stderr," t = %.4f\n",t);
     
     
     centrevec = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
     */
    
    
    GLKVector4 up = GLKMatrix4MultiplyVector4(rotationMat, GLKVector4Make(0.0, 1.0, 0.0, 1.0));
    upvec = GLKVector3Normalize(GLKVector3Make(up.x, up.y, up.z));
    centrevec = _v;
    
    //set eye
    //GLKVector4 _eye_at = GLKMatrix4MultiplyVector4(GLKMatrix4Invert(basenormalMat, &isinvertible) ,GLKVector4Make(0.0, 14.0, 0.0, 1.0));
    //eye_at = GLKVector3Make(_eye_at.x, _eye_at.y, _eye_at.z);
    eye_origin = GLKVector3Make(0.0, 0.0, 0.0);
    //eye_up = GLKVector3Make(0.0, 0.0, 1.0);
    eye_at = centrevec;
    eye_up = upvec;
    NSLog(@"eye_at: %f %f %f", eye_at.x, eye_at.y, eye_at.z);
    NSLog(@"eye_origin: %f %f %f", eye_origin.x, eye_origin.y, eye_origin.z);
    NSLog(@"eye_up: %f, %f %f", eye_up.x, eye_up.y, eye_up.z);
    
}

void multiply_vertices()
{
    GLKVector4 pts[4];
    int i;
    
    pts[0] = GLKVector4Make(-250.0, 14.0, -250.0, 1.0);
    pts[1] = GLKVector4Make(250.0, 14.0, -250.0, 1.0);
    pts[2] = GLKVector4Make(250.0,  14.0, 250.0, 1.0);
    pts[3] = GLKVector4Make(-250.0, 14.0, 250.0, 1.0);
    
    // fprintf(stderr, "NEW VECTORS\n");
    for(i=0;i<4;i++)
    {
        result[i] = GLKMatrix4MultiplyVector4( GLKMatrix4Transpose(basenormalMat), pts[i]);
        //   fprintf(stderr, "i: x=%.4f y=%.4f z = %.4f \n",result[i].x, result[i].y, result[i].z);
    }
}

void multiply_vertices_Zaxis()
{
    GLKVector4 pts[4];
    int i;
    
    pts[0] = GLKVector4Make(-250.0,  -250.0, -14.0,1.0);
    pts[1] = GLKVector4Make( 250.0,  -250.0, -14.0, 1.0);
    pts[2] = GLKVector4Make( 250.0,   250.0,-14.0, 1.0);
    pts[3] = GLKVector4Make(-250.0,  250.0, -14.0, 1.0);
    
    // fprintf(stderr, "NEW VECTORS\n");
    for(i=0;i<4;i++)
    {
        result[i] = GLKMatrix4MultiplyVector4( zMatrix, pts[i]);
        //   fprintf(stderr, "i: x=%.4f y=%.4f z = %.4f \n",result[i].x, result[i].y, result[i].z);
    }
    
}

void init(){
    
    
    biasMatrix= GLKMatrix4Make(
                               0.5, 0.0, 0.0, 0.0,
                               0.0, 0.5, 0.0, 0.0,
                               0.0, 0.0, 0.5, 0.0,
                               0.5, 0.5, 0.5, 1.0
                               );
    init_camera_model();
    
    
};

#pragma mark - FluxOpenGLViewController


@implementation FluxOpenGLViewController

@synthesize fluxNearbyMetadata;

#pragma mark - Display Manager Notifications

- (void)didUpdateImageList:(NSNotification *)notification{
    // Clear out anything that is no longer rendered
    self.fluxNearbyMetadata = self.fluxDisplayManager.fluxNearbyMetadata;
    
    [_renderListLock lock];

    NSMutableArray *toDelete = [[NSMutableArray alloc] init];

    for (id localID in self.renderedTextures)
    {
        if ((![localID isEqualToString:@""]) && ![self.nearbyList containsObject:localID])
        {
            [toDelete addObject:localID];
        }
    }

    for (id localID in toDelete)
    {
        [self deleteImageTextureIdx:[self.renderedTextures indexOfObject:localID]];
    }
    
    [_renderListLock unlock];
}

- (void)updateImageTexture:(NSNotification *)notification{
    if ([[notification userInfo]allKeys].count == 0) {
        return;
    }
    NSString *localID = [[[notification userInfo]allKeys]objectAtIndex:0];
    [self updateImageTextureWithLocalID:localID withImage:[[notification userInfo]objectForKey:localID]];
}




#pragma mark - Motion Manager

//starts the motion manager and sets an update interval
- (void)setupMotionManager
{
    motionManager = [FluxMotionManagerSingleton sharedManager];
}

- (void)startDeviceMotion
{
    if (motionManager)
    {
        [motionManager startDeviceMotion];
    }
}

- (void)stopDeviceMotion
{
    if (motionManager)
    {
        [motionManager stopDeviceMotion];
    }
}

#pragma mark - AV Capture
- (void)cleanUpTextures
{
    if (_videotexture)
    {
        CFRelease(_videotexture);
        _videotexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVReturn err;
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    _videoTextureWidth = CVPixelBufferGetWidth(pixelBuffer);
    _videoTextureHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    if (!_videoTextureCache)
    {
        NSLog(@"No video texture cache");
        return;
    }
    
    [self cleanUpTextures];
    
    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
    // optimally from CVImageBufferRef.
    
    glActiveTexture(GL_TEXTURE7);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       _videoTextureWidth,
                                                       _videoTextureHeight,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_videotexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_videotexture), CVOpenGLESTextureGetName(_videotexture));
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
}

- (void)setupAVCapture
{
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
    
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
    //
    //    //-- Setup Capture Session.
    //    _session = [[AVCaptureSession alloc] init];
    //    [_session beginConfiguration];
    //
    //    //-- Set preset session size.
    //    [_session setSessionPreset:_sessionPreset];
    //
    //    //-- Creata a video device and input from that Device.  Add the input to the capture session.
    //    AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //    if(videoDevice == nil)
    //        assert(0);
    //
    //    //-- Add the device to the session.
    //    NSError *error;
    //    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    //    if(error)
    //        assert(0);
    //
    //    [_session addInput:input];
    //
    //    //-- Create the output for the capture session.
    //    AVCaptureVideoDataOutput * dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    //    [dataOutput setAlwaysDiscardsLateVideoFrames:YES]; // Probably want to set this to NO when recording
    //
    
    //
    //    // Set dispatch to be on the main thread so OpenGL can do things with the data
    
    //
    //    [_session addOutput:dataOutput];
    //    [_session commitConfiguration];
    //
    //    [_session startRunning];
    cameraManager = [FluxAVCameraSingleton sharedCamera];
    [cameraManager.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    //[cameraManager setSampleBufferDelegate:self forViewController:self];
    
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateImageList:) name:FluxDisplayManagerDidUpdateOpenGLDisplayList object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateImageTexture:) name:FluxDisplayManagerDidUpdateImageTexture object:nil];
    
    [super viewDidLoad];
    _opengltexturesset = 0;
    self.nearbyList = [[NSMutableArray alloc] init];
    self.renderedTextures = [[NSMutableArray alloc] initWithCapacity:number_textures];
    for (int i = 0; i < number_textures; i++)
    {
        [self.renderedTextures addObject:@""];
    }
    
    _nearbyListLock = [[NSLock alloc] init];
    _renderListLock = [[NSLock alloc] init];
    
    [self setupMotionManager];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    _screenWidth = [UIScreen mainScreen].bounds.size.width;
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    view.contentScaleFactor = [UIScreen mainScreen].scale;
    
    _sessionPreset = AVCaptureSessionPreset640x480;
    
    [self setupGL];
    [self setupAVCapture];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Call these immediately since location is not always updated frequently (use current value)
    
    [self startDeviceMotion];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopDeviceMotion];
    //[self pauseAVCapture];
}

- (void)dealloc
{
    motionManager = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FluxScanViewDidAcquireNewPicture" object:nil];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
    
    // Dispose of any resources that can be recreated.
}


- (void)pauseOpenGLRender
{
    self.paused = YES;
}

- (void)restartOpenGLRender
{
    self.paused = NO;
}

- (BOOL)openGLRenderIsActive
{
    return [self isPaused];
}



#pragma mark - OpenGL Texture & Metadata Manipulation
- (void) updateImageTextureWithLocalID:(NSString *)localID withImage:(UIImage *)image
{
    NSError *error;
    
    [_renderListLock lock];
    
    // Check if texture is already being rendered
    if ([self.renderedTextures containsObject:localID])
    {
        // Update the metadata in case it changed
        [self updateImageMetadataKey:localID index:[self.renderedTextures indexOfObject:localID]];
        [_renderListLock unlock];
        return;
    }
    
    // Find a usable slot to put the texture
    NSUInteger i = [self.renderedTextures indexOfObject:@""];
    if (i == NSNotFound)
    {
        NSLog(@"%s: Render list is full! Not rendering image with ID %@", __func__, localID);
        [_renderListLock unlock];
        return;
    }

    // Note: This should never actually do anything (since _texture[i] should be nil), but just to be safe...
    [self deleteImageTextureIdx:i];
    
    // Load the new texture
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    NSData *imgData = UIImageJPEGRepresentation(image,1); // 1 is compression quality
    _texture[i] = [GLKTextureLoader textureWithContentsOfData:imgData options:options error:&error];
    
    if (error)
    {
        NSLog(@"Image texture error %@", error);
    }
    else
    {
        NSLog(@"Added Image texture to render list in slot %d", (i));
        self.renderedTextures[i] = localID;
        [self updateImageMetadataKey:localID index:i];
        _opengltexturesset++;
        if (_opengltexturesset >= number_textures) _opengltexturesset = number_textures;
    }
    [_renderListLock unlock];
}

- (void) deleteImageTextureIdx:(int)i
{
    if (_texture[i] != nil)
    {
        GLKTextureInfo *curTexture = _texture[i];
        GLuint textureName = curTexture.name;
        glDeleteTextures(1, &textureName);
        _texture[i] = nil;
        self.renderedTextures[i] = @"";
    }
}

-(void) updateImageMetadataKey:(id)key index:(int)idx
{
//    NSLog(@"Adding metadata for key %@ (dictionary count is %d)", key, [fluxNearbyMetadata count]);
    GLKQuaternion quaternion;
    
    FluxScanImageObject *locationObject = [fluxNearbyMetadata objectForKey:key];
    
    _imagePose[idx].position.x =  locationObject.latitude;
    _imagePose[idx].position.y =  locationObject.longitude;
    _imagePose[idx].position.z =  locationObject.altitude;
    
    quaternion.x = locationObject.qx;
    quaternion.y = locationObject.qy;
    quaternion.z = locationObject.qz;
    quaternion.w = locationObject.qw;
    
    //_imagePose[idx].rotationMatrix =  GLKMatrix4MakeWithQuaternion(quaternion);
    GLKMatrix4 quatMatrix =  GLKMatrix4MakeWithQuaternion(quaternion);
    GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(PI/2, 0.0,0.0, 1.0);
    _imagePose[idx].rotationMatrix =  GLKMatrix4Multiply(matrixTP, quatMatrix);
//    NSLog(@"Loaded metadata for image %d quaternion [%f %f %f %f]", idx, quaternion.x, quaternion.y, quaternion.z, quaternion.w);
}

-(void)updateImageMetaData
{
    viewParameters vpimage;
    GLKVector3 planeNormal;
    GLKMatrix4 tMVP;
    float distance = _projectionDistance;
    int i;
    
    for(i =0; i < 5; i++)
    {
        _validMetaData[i] =0;
        _validMetaData[i] = (computeProjectionParametersImage(&_imagePose[i], &planeNormal, distance, _userPose, &vpimage) *
                             self.fluxDisplayManager.locationManager.notMoving);
        
      
        
        tViewMatrix = GLKMatrix4MakeLookAt(vpimage.origin.x, vpimage.origin.y, vpimage.origin.z,
                                           vpimage.at.x, vpimage.at.y, vpimage.at.z,
                                           vpimage.up.x, vpimage.up.y, vpimage.up.z);
        tMVP = GLKMatrix4Multiply(camera_perspective,tViewMatrix);
        
        _tBiasMVP[i] = GLKMatrix4Multiply(biasMatrix,tMVP);
    }
}

- (void)updateBuffers
{
    g_vertex_buffer_data[0] = result[0].x;
    g_vertex_buffer_data[1] = result[0].y;
    g_vertex_buffer_data[2] = result[0].z;       //0
    g_vertex_buffer_data[3] = result[1].x;
    g_vertex_buffer_data[4] = result[1].y;
    g_vertex_buffer_data[5] = result[1].z;  //1
    g_vertex_buffer_data[6] = result[2].x;
    g_vertex_buffer_data[7] = result[2].y;
    g_vertex_buffer_data[8] = result[2].z;  //2
    g_vertex_buffer_data[9]	= result[2].x;
    g_vertex_buffer_data[10] = result[2].y;
    g_vertex_buffer_data[11] = result[2].z;   //2
    g_vertex_buffer_data[12] = result[0].x;
    g_vertex_buffer_data[13] = result[0].y;
    g_vertex_buffer_data[14] = result[0].z; //0
    g_vertex_buffer_data[15] = result[3].x;
    g_vertex_buffer_data[16] = result[3].y;
    g_vertex_buffer_data[17] = result[3].z;   //3
    
    glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_DYNAMIC_DRAW);
    //glBufferData(GL_ARRAY_BUFFER, sizeof(testvertexData), testvertexData, GL_DYNAMIC_DRAW);
}

#pragma mark - OpenGL Setup

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    [self checkShaderLimitations];
    
    init();
    
    _projectionDistance = 20.0;
    glEnable(GL_DEPTH_TEST);
    
    
    
    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    
    
    /*
     _texture[7] = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"background" ofType:@"png"] options:options error:&error];
     if (error) NSLog(@"Image texture error %@", error);
     
     
     glActiveTexture(GL_TEXTURE7);
     glBindTexture(_texture[7].target, _texture[7].name);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     
     */
    
    
    
    
    [self setupBuffers];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)setupBuffers
{
    glGenBuffers(1, &_indexVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexdata), indexdata, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_positionVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), 0);
    
    glGenBuffers(1, &_texcoordVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(textureCoord), textureCoord, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    CMAttitude *att = motionManager.attitude;
    
//    _userPose.rotationMatrix.m00 = att.rotationMatrix.m11;
//    _userPose.rotationMatrix.m01 = att.rotationMatrix.m12;
//    _userPose.rotationMatrix.m02 = att.rotationMatrix.m13;
//    _userPose.rotationMatrix.m03 = 0.0;
//    
//    _userPose.rotationMatrix.m10 = att.rotationMatrix.m21;
//    _userPose.rotationMatrix.m11 = att.rotationMatrix.m22;
//    _userPose.rotationMatrix.m12 = att.rotationMatrix.m23;
//    _userPose.rotationMatrix.m13 = 0.0;
//    
//    _userPose.rotationMatrix.m20 = att.rotationMatrix.m31;
//    _userPose.rotationMatrix.m21 = att.rotationMatrix.m32;
//    _userPose.rotationMatrix.m22 = att.rotationMatrix.m33;
//    _userPose.rotationMatrix.m23 = 0.0;
//    
//    _userPose.rotationMatrix.m30 = 0.0;
//    _userPose.rotationMatrix.m31 = 0.0;
//    _userPose.rotationMatrix.m32 = 0.0;
//    _userPose.rotationMatrix.m33 = 1.0;
    GLKQuaternion quat = GLKQuaternionMake(att.quaternion.x, att.quaternion.y, att.quaternion.z, att.quaternion.w);
   _userPose.rotationMatrix =  GLKMatrix4MakeWithQuaternion(quat);
    
    //_userPose.rotationMatrix = att.rotationMatrix;
  GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(PI/2, 0.0,0.0, 1.0);
    _userPose.rotationMatrix =  GLKMatrix4Multiply(matrixTP, _userPose.rotationMatrix);
    
    _userPose.position.x =self.fluxDisplayManager.locationManager.location.coordinate.latitude;
    _userPose.position.y =self.fluxDisplayManager.locationManager.location.coordinate.longitude;
    _userPose.position.z =self.fluxDisplayManager.locationManager.location.altitude;
    
    GLKVector3 planeNormal;
    float distance = _projectionDistance;
    viewParameters vpuser;
    
    setupRenderingPlane(planeNormal, _userPose.rotationMatrix, distance);
    
    computeProjectionParametersUser(&_userPose, &planeNormal, distance, &vpuser);
    
    //    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    //    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(vpuser.origin.x, vpuser.origin.y, vpuser.origin.z,
                                                 vpuser.at.x, vpuser.at.y, vpuser.at.z ,
                                                 vpuser.up.x, vpuser.up.y, vpuser.up.z);
    
    //    NSLog(@"eye origin:x=%f y=%f z=%f", vpuser.origin.x, vpuser.origin.y, vpuser.origin.z);
    //    NSLog(@"eye at    :x=%f y=%f z=%f", vpuser.at.x, vpuser.at.y, vpuser.at.z);
    //    NSLog(@"eye up    :x=%f y=%f z=%f", vpuser.up.x, vpuser.up.y, vpuser.up.z);
    //    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(eye_origin.x, eye_origin.y, eye_origin.z, eye_at.x, eye_at.y, eye_at.z , eye_up.x, eye_up.y, eye_up.z);
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelViewMatrix);
    
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(camera_perspective, modelViewMatrix);
    
    [self updateImageMetaData];
    
    //    GLKMatrix4 texrotate = GLKMatrix4MakeRotation(PI, 0.0, 1.0, 0.0);
    //    GLKMatrix4 textranslate = GLKMatrix4MakeTranslation(1.0f, 0.0f, 0.0f);
    
    _imagePose[7].position.x =0.0;
    _imagePose[7].position.y =0.0;
    _imagePose[7].position.z =0.0;
    
    tViewMatrix = viewMatrix;
    
    GLKMatrix4 texrotate = GLKMatrix4MakeRotation(-1.0*PI/2.0, 0.0, 0.0, 1.0);
    tMVP = GLKMatrix4Multiply(camera_perspective,tViewMatrix);
    _tBiasMVP[6] = texrotate;
    _tBiasMVP[7] = GLKMatrix4Multiply(biasMatrix,tMVP);
    
    [self updateBuffers];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX0], 1, 0, _tBiasMVP[0].m);
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX1], 1, 0, _tBiasMVP[1].m);
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX2], 1, 0, _tBiasMVP[2].m);
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX3], 1, 0, _tBiasMVP[3].m);
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX4], 1, 0, _tBiasMVP[4].m);
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX7], 1, 0, _tBiasMVP[7].m);
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX6], 1, 0, _tBiasMVP[6].m);
    //glActiveTexture(GL_TEXTURE0);
    //glBindTexture(GL_TEXTURE_2D, texture[0]);
    
    // Set our "myTextureSampler" sampler to user Texture Unit 0

    // draw background first...
    if(_videotexture != NULL)
    {
        glActiveTexture(GL_TEXTURE7);
        glBindTexture(CVOpenGLESTextureGetTarget(_videotexture), CVOpenGLESTextureGetName(_videotexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER7], 7);
    }
    
    // then spin through the images...
    if(_opengltexturesset >= 1)
    {
        for(int i = 0; i < _opengltexturesset; i++)
        {
#warning fix this to only bind on texture change
            if ((_texture[i] != nil) && (_validMetaData[i]==1))
            {
                          //  NSLog(@"rendering texture%d", i);
                glUniform1i(uniforms[UNIFORM_RENDER_ENABLE0+i],1);
                glActiveTexture(GL_TEXTURE0 + i);
                glBindTexture(_texture[i].target, _texture[i].name);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER0 + i], i);
            }
            else
            {
                glActiveTexture(GL_TEXTURE0 + i);
                glBindTexture(GL_TEXTURE_2D, 0);
                glUniform1i(uniforms[UNIFORM_RENDER_ENABLE0+i],0);
            }
        }
    }
    /*
     glActiveTexture(GL_TEXTURE7);
     glBindTexture(_texture[7].target, _texture[7].name);
     
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER7], 7);*/
    
    /*
    if(_videotexture != NULL)
    {
        glActiveTexture(GL_TEXTURE7);
        glBindTexture(CVOpenGLESTextureGetTarget(_videotexture), CVOpenGLESTextureGetName(_videotexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER7], 7);
    }
    */
    glDrawElements(GL_TRIANGLES, 6,GL_UNSIGNED_BYTE,0);
    
}

#pragma mark -  OpenGL ES 2 shader compilation

- (void) checkShaderLimitations{
    GLint maxtextureunits;
    GLint maxvertextureunits;
    
    glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxtextureunits);
    NSLog(@"Maximum texture image units = %d",maxtextureunits);
    
    glGetIntegerv(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, &maxvertextureunits);
    NSLog(@"Maximum vertex texture image unit = %d",maxvertextureunits);
    
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shaders/Shader" ofType:@"vsh"];
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shaders/Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_TBIASMVP_MATRIX0] = glGetUniformLocation(_program, "tBiasMVP[0]");
    uniforms[UNIFORM_TBIASMVP_MATRIX1] = glGetUniformLocation(_program, "tBiasMVP[1]");
    uniforms[UNIFORM_TBIASMVP_MATRIX2] = glGetUniformLocation(_program, "tBiasMVP[2]");
    uniforms[UNIFORM_TBIASMVP_MATRIX3] = glGetUniformLocation(_program, "tBiasMVP[3]");
    uniforms[UNIFORM_TBIASMVP_MATRIX4] = glGetUniformLocation(_program, "tBiasMVP[4]");
    uniforms[UNIFORM_TBIASMVP_MATRIX7] = glGetUniformLocation(_program, "tBiasMVP[7]");
    uniforms[UNIFORM_TBIASMVP_MATRIX6] = glGetUniformLocation(_program, "textureModelMatrix");
    
    uniforms[UNIFORM_MYTEXTURE_SAMPLER0] = glGetUniformLocation(_program, "textureSampler[0]");
    uniforms[UNIFORM_MYTEXTURE_SAMPLER1] = glGetUniformLocation(_program, "textureSampler[1]");
    uniforms[UNIFORM_MYTEXTURE_SAMPLER2] = glGetUniformLocation(_program, "textureSampler[2]");
    uniforms[UNIFORM_MYTEXTURE_SAMPLER3] = glGetUniformLocation(_program, "textureSampler[3]");
    uniforms[UNIFORM_MYTEXTURE_SAMPLER4] = glGetUniformLocation(_program, "textureSampler[4]");
    uniforms[UNIFORM_MYTEXTURE_SAMPLER7] = glGetUniformLocation(_program, "textureSampler[7]");
    
    uniforms[UNIFORM_RENDER_ENABLE0] = glGetUniformLocation(_program, "renderEnable[0]");
    uniforms[UNIFORM_RENDER_ENABLE1] = glGetUniformLocation(_program, "renderEnable[1]");
    uniforms[UNIFORM_RENDER_ENABLE2] = glGetUniformLocation(_program, "renderEnable[2]");
    uniforms[UNIFORM_RENDER_ENABLE3] = glGetUniformLocation(_program, "renderEnable[3]");
    uniforms[UNIFORM_RENDER_ENABLE4] = glGetUniformLocation(_program, "renderEnable[4]");
    uniforms[UNIFORM_RENDER_ENABLE5] = glGetUniformLocation(_program, "renderEnable[5]");
    uniforms[UNIFORM_RENDER_ENABLE6] = glGetUniformLocation(_program, "renderEnable[6]");
    uniforms[UNIFORM_RENDER_ENABLE7] = glGetUniformLocation(_program, "renderEnable[7]");

    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Debugging UI Elements

- (IBAction)onDistanceSliderValueChanged:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    NSLog(@"Slider Value: %f", slider.value);
}

- (IBAction)onPositionStepperValueChanged:(id)sender
{
    UIStepper *stepper = (UIStepper *) sender;
    NSLog(@"Stepper Value: %f", stepper.value);
}

@end
