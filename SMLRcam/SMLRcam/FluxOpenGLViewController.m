//
//  ImageViewerViewController.m
//  ImageViewer
//
//  Created by Arjun Chopra on 8/11/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//

#import "FluxOpenGLViewController.h"
#import "FluxScanViewController.h"
#import "ImageViewerImageUtil.h"
#import "FluxMath.h"
#import <Accelerate/Accelerate.h>
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
    
    UNIFORM_CROP_TOPIMAGE,
    UNIFORM_CROP_BOTTOMIMAGE,
    
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

//square images
int iPhone5_topcrop;
int iPhone5_bottomcrop;

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
void init_camera_model()
{
	float _fov = 2 * atan2(iPhone5_pixelsize*3264.0/2.0, iPhone5_focalLength); //radians
    fprintf(stderr,"FOV = %.4f degrees\n", _fov *180.0/3.14);
    float aspect = (float)iPhone5_xpixels/(float)iPhone5_ypixels;
    camera_perspective = 	GLKMatrix4MakePerspective(_fov, aspect, 0.001f, 50.0f);
    
    
    //Assume symmetric cropping for now
    iPhone5_bottomcrop = (iPhone5_ypixels - iPhone5_xpixels)/2;
    iPhone5_topcrop = iPhone5_bottomcrop;
}

#define PI M_PI
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

int computeTangentParametersUser(sensorPose *usp, viewParameters *vp)
{
//    viewParameters viewP;
	GLKVector3 positionTP;
    positionTP = GLKVector3Make(0.0, 0.0, 0.0);

    setParametersTP(usp->position);
    
    WGS84_to_ECEF(usp);
    
    tangentplaneRotation(usp);

    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(usp->rotationMatrix, zRay);
    
    //NSLog(@"Projection vector: [%f, %f, %f]", v.x, v.y, v.z);
    
    //normal plane
//    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
//    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3((usp->rotationMatrix), planeNormalI);
    //intersection with plane
//    GLKVector3 N = planeNormalRotated;
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
//    float vd = GLKVector3DotProduct(N,V);
//    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
//    float t = v0/vd;
//    
//    if(vd==0)
//    {
//        // NSLog(@"UserPose :Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
//        return -1;
//    }
//    if(t < 0)
//    {
//        
//        // NSLog(@"UserPose: Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
//        return -1;
//    }
    
//    viewP.at = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
//    viewP.at = V;
//    viewP.up = GLKMatrix4MultiplyVector3(usp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    
    (*vp).origin = GLKVector3Add(positionTP, P0);
    (*vp).at = V;
    (*vp).up = GLKMatrix4MultiplyVector3(usp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    
    //setupRenderingPlane(positionTP, usp->rotationMatrix, distance);
    
    return 0;
}


// compute the tangent plane location and direction vector for an image
bool computeTangentPlaneParametersImage(sensorPose *sp, sensorPose userPose, viewParameters *vp)
{
    bool retval = true;
    
//    viewParameters viewP;
	GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    
    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(sp->rotationMatrix, zRay);
    
    //normal plane
//    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
//    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3((userPose.rotationMatrix), planeNormalI);
    
    //intersection with plane
//    GLKVector3 N = planeNormalRotated;
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
    //assumption that the point of image acquisition and the user lie in the same plane.
    sp->position.z = userPose.position.z;
    
    if (sp->validECEFEstimate != 1)
    {
        WGS84_to_ECEF(sp);
    }
    
    positionTP.x = sp->ecef.x -userPose.ecef.x;
    positionTP.y = sp->ecef.y -userPose.ecef.y;
    positionTP.z = sp->ecef.z -userPose.ecef.z;
    
    positionTP = GLKMatrix4MultiplyVector3(rotation_teM, positionTP);
    
    P0 = positionTP;
    
//    float vd = GLKVector3DotProduct(N,V);
//    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
//    float t = v0/vd;
//    
//    if (vd == 0)
//    {
//        //    NSLog(@"ImagePose: Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
//        return 0;
//    }
//
//    if (t < 0)
//    {
//        
//        // NSLog(@"ImagePose: Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
//        retval = 0;
//    }
    
    float _distanceToUser = GLKVector3Length(P0);
    
    if (_distanceToUser > MAX_IMAGE_RADIUS)
    {
        //NSLog(@"too far to render %f -> %f", distancetoPlane, distance);
        retval = false;
    }
    
//    viewP.at = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));  // viewP.at would be the point of intersection of image camera LOS with projection plane
//    viewP.at = GLKVector3Add(P0, V);  // at would = point

//    viewP.at = V;       // viewP.at = raw directional vector of image camera LOS
//    viewP.up = GLKMatrix4MultiplyVector3(sp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    
    (*vp).origin = P0;
    (*vp).at = V;
    (*vp).up = GLKMatrix4MultiplyVector3(sp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    
    return retval;
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
    
    //assumption that the point of image acquisition and the user lie in the same plane.
    sp->position.z = userPose.position.z;
    
    
    if(sp->validECEFEstimate !=1)
    {
        WGS84_to_ECEF(sp);
    }
    
    positionTP.x = sp->ecef.x - userPose.ecef.x;
    positionTP.y = sp->ecef.y - userPose.ecef.y;
    positionTP.z = sp->ecef.z - userPose.ecef.z;
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

//stored userPose ecef and image ecef
-(int) computeProjectionParametersMatchedImageWithImagePose:(sensorPose *)sp userHomographyPose:(sensorPose) uhpose planeNormal:(GLKVector3 *)pN Distance: (float) distance currentUserPose:(sensorPose) uPose viewParamters:(viewParameters *)vp
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
    
    GLKVector3 vuhp = GLKMatrix4MultiplyVector3(uhpose.rotationMatrix, zRay);
    GLKVector3 v = GLKMatrix4MultiplyVector3(sp->rotationMatrix, vuhp);
    
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3((uPose.rotationMatrix), planeNormalI);
    
    //intersection with plane
    GLKVector3 N = planeNormalRotated;
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
   
    
    positionTP.x = sp->ecef.x - uPose.ecef.x;
    positionTP.y = sp->ecef.y - uPose.ecef.y;
    positionTP.z = sp->ecef.z - uPose.ecef.z;
    
    positionTP = GLKMatrix4MultiplyVector3(rotation_teM, positionTP);
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
    
    (*vp).origin =  P0;
    (*vp).at =viewP.at;
    (*vp).up = viewP.up;
    
    return 1;
    
}






#pragma mark - Display Manager Notifications

- (void)didUpdateImageList:(NSNotification *)notification
{
    // simply indicate a change has happened - set dirty flag to true to trigger processing of rendering image list in GL loop
    FluxDisplayManager *fdm = [(FluxScanViewController*)self.parentViewController fluxDisplayManager];
    if ((fdm != nil) && (fdm.openGLVC == nil))
    {
        fdm.openGLVC = self;
    }

    _displayListHasChanged++;
    
}

- (void)updateImageTexture:(NSNotification *)notification{
    _displayListHasChanged++;
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

- (void)didTakeStep:(NSNotification *)notification{
//    NSNumber *n = [notification.userInfo objectForKey:@"stepDirection"];
//
//    NSNumber *stepAvgAccelX = [notification.userInfo objectForKey:@"stepAvgAccelX"];
//    NSNumber *stepAvgAccelY = [notification.userInfo objectForKey:@"stepAvgAccelY"];
//    NSNumber *stepAvgAccelZ = [notification.userInfo objectForKey:@"stepAvgAccelZ"];
//
//    if (n != nil)
//    {
//        walkDir stepDirection = n.intValue;
//        switch (stepDirection) {
//            case FORWARDS:
//                [self computePedDisplacementKFilter:1];
//                // add your logic for a single forward step...
//                break;
//            case BACKWARDS:
//                [self computePedDisplacementKFilter:-1];
//                // add your logic for a single backward step...
//                break;
//
//            default:
//                break;
//        }
//    }
    
}
    


#pragma mark - Image Capture

- (void)setupCameraView{
    
    UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                           bundle:[NSBundle mainBundle]];
    // setup the opengl controller
    // first get an instance from storyboard
    self.imageCaptureViewController = [myStoryboard instantiateViewControllerWithIdentifier:@"imageCaptureViewController"];
    
    // then add the imageCaptureView as the subview of the parent view
    [self.view addSubview:self.imageCaptureViewController.view];
    // add the glkViewController as the child of self
    [self addChildViewController:self.imageCaptureViewController];
    [self.imageCaptureViewController didMoveToParentViewController:self];
    self.imageCaptureViewController.view.frame = self.view.bounds;
    camIsOn = NO;
    imageCaptured = NO;
    _displayListHasChanged = 0;
}

- (void)showImageCapture{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.imageCaptureViewController setHidden:NO];
    camIsOn = YES;

    // TS: need to call back into fluxDisplayManager to switch to image capture mode - could be a notification send (FluxImageCaptureDidPush)
    // really should be called from ImageCaptureViewController but no really obvious place to put it.
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidPush
                                                        object:self userInfo:nil];
}

- (void)takeSnapshotAndPresentApproval{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    UIImage*img = [self snapshot:self.view];
    [self.imageCaptureViewController setHidden:NO];
    [self.imageCaptureViewController presentSnapshot:img];
}

- (void)imageCaptureDidPop:(NSNotification *)notification{
    // need to clean out the textures...
    [self.renderList removeAllObjects];
    imageCaptured = NO;
    camIsOn = NO;
}

- (void)imageCaptureDidCapture:(NSNotification *)notification{
    imageCaptured = YES;
    [(FluxScanViewController*)self.parentViewController setCameraButtonEnabled:YES];
}

#pragma mark - Image Tapping

- (FluxScanImageObject*)imageTappedAtPoint:(CGPoint)point
{
    FluxScanImageObject *touchedObject = nil;
    
    if (self.renderList.count>0) {
        FluxImageRenderElement *ire = [self.renderList objectAtIndex:0];
        if (ire != nil)
        {
            //        FluxScanImageObject *touchedObject = [[FluxScanImageObject alloc]initWithUserID:ire.imageMetadata.userID atTimestampString:nil andCameraID:0 andCategoryID:0 withDescriptionString:ire.imageMetadata.descriptionString andlatitude:0 andlongitude:0 andaltitude:0 andHeading:0 andYaw:0 andPitch:0 andRoll:0 andQW:0 andQX:0 andQY:0 andQZ:0 andHorizAccuracy:0 andVertAccuracy:0];
            touchedObject = ire.imageMetadata;
        }
    }


    return touchedObject;
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
    NSDate *currentDate = [NSDate date];
    
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
    if([connection isVideoStabilizationEnabled] ==NO )
    {
        if([connection isVideoStabilizationSupported])
        {
            NSLog(@"Stablization supported, enabling");
            [connection setEnablesVideoStabilizationWhenAvailable:YES];
            
        }
    }
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
    
    if (frameGrabRequested && frameGrabRequest && frameGrabRequest.frameRequested)
    {
        // Grab copy of frame buffer and notify reciever that it is ready
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext
                                 createCGImage:ciImage
                                 fromRect:CGRectMake(0, 0,
                                                     CVPixelBufferGetWidth(pixelBuffer),
                                                     CVPixelBufferGetHeight(pixelBuffer))];
        
        frameGrabRequest.cameraFrameImage = [UIImage imageWithCGImage:videoImage];

        CGImageRelease(videoImage);
        videoImage = nil;
        
        // Copy frame metadata
        frameGrabRequest.cameraFrameDate = currentDate;
        frameGrabRequest.cameraPose = _userPose;
        frameGrabRequest.cameraProjectionDistance = _projectionDistance;
        
        // Signal requesting thread that frame is ready
        [frameGrabRequest.frameReadyCondition lock];
        frameGrabRequest.frameReady = YES;
        [frameGrabRequest.frameReadyCondition signal];
        [frameGrabRequest.frameReadyCondition unlock];
        
        frameGrabRequest = nil;
        
        // Reset flag to grab frame
        frameGrabRequested = NO;
    }
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    NSError*error;
    [cameraManager.device lockForConfiguration:&error];
    [cameraManager.device setFocusPointOfInterest:[touch locationInView:self.view]];
}

- (void)setupAVCapture
{
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
    
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
    cameraManager = [FluxAVCameraSingleton sharedCamera];
    [cameraManager.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
}

- (void)requestCameraFrame:(FluxCameraFrameElement *)frameRequest
{
    frameGrabRequest = frameRequest;
    frameGrabRequested = YES;
}

#pragma mark ScreenShot
-(UIImage*)takeScreenCap
{
    int s = 1;
    UIScreen* screen = [ UIScreen mainScreen ];
    if ( [ screen respondsToSelector:@selector(scale) ] )
        s = (int) [ screen scale ];
    
    const int w = self.view.frame.size.width;
    const int h = self.view.frame.size.height;
    const NSInteger myDataLength = w * h * 4 * s * s;
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, 0, w*s, h*s, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    // gl renders "upside down" so swap top to bottom into new array.
    // there's gotta be a better way, but this works.
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y < h*s; y++)
    {
        memcpy( buffer2 + (h*s - 1 - y) * w * 4 * s, buffer + (y * 4 * w * s), w * 4 * s );
    }
    free(buffer); // work with the flipped buffer, so get rid of the original one.
    
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * w * s;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(w*s, h*s, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    // then make the uiimage from that
    UIImage *myImage = [ UIImage imageWithCGImage:imageRef scale:s orientation:UIImageOrientationUp];
    CGImageRelease( imageRef );
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    free(buffer2);
    return myImage;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateImageList:) name:FluxDisplayManagerDidUpdateDisplayList object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateImageTexture:) name:FluxDisplayManagerDidUpdateImageTexture object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCaptureDidPop:) name:FluxImageCaptureDidPop object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCaptureDidCapture:) name:FluxImageCaptureDidCaptureImage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(render) name:FluxOpenGLShouldRender object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTakeStep:) name:FluxPedometerDidTakeStep object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadAlphaTexture) name:@"maskChange" object:nil];
    
    [super viewDidLoad];
    _displayListHasChanged = 0;

    self.renderList = [[NSMutableArray alloc] initWithCapacity:number_textures];
    
    self.textureMap = [[NSMutableArray alloc] initWithCapacity:number_textures];
    for (int i = 0; i < number_textures; i++)
    {
        FluxTextureToImageMapElement *ime = [[FluxTextureToImageMapElement alloc] init];
        ime.textureIndex = i;
        [self.textureMap addObject:ime];
    }

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
    [self setupCameraView];
    
    //set debug labels to hidden by default
    gpsX.hidden= YES;
    gpsY.hidden=YES;
    kX.hidden = YES;
    kY.hidden =YES;
    delta.hidden = YES;
    pedometerL.hidden = YES;
    
    fluxFeatureMatchingQueue = [[FluxFeatureMatchingQueue alloc] init];
    
    frameGrabRequested = NO;
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
}

- (void)dealloc
{
    motionManager = nil;
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    
//    [super didReceiveMemoryWarning];
//    
//    if ([self isViewLoaded] && ([[self view] window] == nil)) {
//        self.view = nil;
//        
//        [self tearDownGL];
//        
//        if ([EAGLContext currentContext] == self.context) {
//            [EAGLContext setCurrentContext:nil];
//        }
//        self.context = nil;
//    }
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

- (void)setFluxDisplayManager:(FluxDisplayManager *)fluxDisplayManager{
    _fluxDisplayManager = fluxDisplayManager;
    self.imageCaptureViewController.fluxDisplayManager = fluxDisplayManager;
}



#pragma mark - OpenGL Texture & Metadata Manipulation

- (void) deleteImageTextureIdx:(int)i
{
    if (_texture[i] != nil)
    {
        GLKTextureInfo *curTexture = _texture[i];
        GLuint textureName = curTexture.name;
        glDeleteTextures(1, &textureName);
        _texture[i] = nil;
    }
}

- (void) updateImageMetadataForElementList:(NSMutableArray *)elementList
{
    NSMutableArray *removeList = [[NSMutableArray alloc]init];
    double absUserHeading;
    double relUserHeading;
    
    // first, get a copy of the userPose, just in case it changed under us.  May want to look into a lock for this...
    sensorPose localUserPose = _userPose;
    viewParameters localUserVp;

    computeTangentParametersUser(&localUserPose, &localUserVp);
//    double xu = 0.0;
//    double yu = 1.0;
    double x1 = 0.0;
    double y1 = 1.0;
    double x2 = localUserVp.at.x;
    double y2 = localUserVp.at.y;
    double dotx = (x1 * x2);
    double doty = (y1 * y2);
    
    double scalar = dotx + doty;
    double magsq1 = x1 * x1 + y1 * y1;
    double magsq2 = x2 * x2 + y2 * y2;
    
    double costheta = (scalar) / sqrt(magsq1 * magsq2);
    double theta = acos(costheta) * 180.0 / M_PI;
    
    if (x2 < 0)
    {
        theta = -theta;
    }

    relUserHeading = theta;
    absUserHeading = self.fluxDisplayManager.locationManager.heading;

//    while (relUserHeading < 0.0)
//        relUserHeading += 360.0;
    
//    NSLog(@"Relative User Heading: %f, gps user heading: %f", relUserHeading, self.fluxDisplayManager.locationManager.heading);
    
    for (FluxImageRenderElement *ire in elementList)
    {
        viewParameters vp;
        
        [self updateImageMetadataForElement:ire];
        bool cansee = computeTangentPlaneParametersImage(ire.imagePose, localUserPose, &vp);
        
        if (!cansee)
        {
            [removeList addObject:ire];
        }
        else
        {
            ire.tpImageParams = vp;
            
            // find intersection with cylindrical screen to calculate relative angle
            // get intersection point(s)
            double xi, yi;

            if (vp.at.x != 0.0)
            {
                double m = vp.at.y / vp.at.x;
                double c = vp.origin.y - m * vp.origin.x;
                double r = _projectionDistance;
                double A = (m * m) + 1;
                double B = 2.0 * m * c;
                double C = ((c * c) - (r * r));
                
                double discriminant = ((B * B) - (4.0 * A * C));
                double sqrtDiscriminant = sqrt(discriminant);
                
                if (discriminant > 0.0)
                {
                    // two intersections - calc both and figure out which it is based on m (which is based on vp.at)
                    xi = ((-B + sqrtDiscriminant) / (2 * A));
                    yi = 0.0;
                    
                    if (((xi - vp.origin.x) * vp.at.x) < 0.0)
                    {
                        // wrong side - find the other root...
                        xi = ((-B - sqrtDiscriminant) / (2 * A));
                    }
                            
                    yi = m * xi + c;
                }
                else
                {
                    // vector is tangent to or misses circle - can discard the object
                    // shouldn't get here since we are already filtering for points outside the circle
                    [removeList addObject:ire];
                    continue;
                }
            }
            else
            {
                // directly horizontal - intersection is on vp.at.y side of circle
                xi = 0.0;
                yi = (vp.at.y > 0.0) ? _projectionDistance : -_projectionDistance;
            }

//            // calculate angle
//            // first the dot-product
//            dotx = (xi * localUserVp.at.x);
//            doty = (yi * localUserVp.at.y);
//            
//            scalar = dotx + doty;
//            magsq1 = xi*xi + yi*yi;
//            magsq2 = localUserVp.at.x * localUserVp.at.x + localUserVp.at.y * localUserVp.at.y;
//            
//            costheta = (scalar) / sqrt(magsq1 * magsq2);
//            theta = acos(costheta) * 180.0 / M_PI;
//
//            if (xi < 0.0)
//                theta = -theta; // check with radar view to see if this is reversed...
//            
//            // store as relative heading
//            ire.imageMetadata.relHeading = theta;
            
            x1 = 0.0;
            y1 = 1.0;
            x2 = xi;
            y2 = yi;
            dotx = x2 * x1;
            doty = y2 * y1;
            
            scalar = dotx + doty;
            magsq1 = x2 * x2 + y2 * y2;
            magsq2 = (x1 * x1) + (y1 * y1);
            
            costheta = (scalar) / sqrt(magsq1 * magsq2);
            theta = acos(costheta) * 180.0 / M_PI;
            
            if (x2 < 0.0)
                theta = -theta;
            
            ire.imageMetadata.absHeading = theta;
            
            while (ire.imageMetadata.absHeading < 0.0)
                ire.imageMetadata.absHeading += 360.0;
            
            while (absUserHeading < 0.0)
                absUserHeading += 360.0;
            
            theta = theta - absUserHeading;
            
            while (theta < -180.0)
                theta += 360.0;
            
            while (theta > 180.0)
                theta -= 360.0;

            ire.imageMetadata.relHeading = theta;
            
            
//            if (ire.imageMetadata.imageID == 921)
//            {
//                NSLog(@"localid: %@, id: %d, rel head: %f, abs head: %f, gps head: %f, ruhead: %f, auhead: %f, guhead: %f", ire.localID, ire.imageMetadata.imageID,
//                                        ire.imageMetadata.relHeading, ire.imageMetadata.absHeading, ire.imageMetadata.heading, relUserHeading, absUserHeading, self.fluxDisplayManager.locationManager.heading);
//            }
            
//            if (fabs(ire.imageMetadata.absHeading - ire.imageMetadata.heading) > 5.0)
//            {
//                NSLog(@"headings out of whack for %@: abs: %f, gps: %f", ire.localID, ire.imageMetadata.absHeading, ire.imageMetadata.heading);
//            }

            
//            double ah = ire.imageMetadata.heading;
//            while (ah < 0.0)
//                ah += 360.0;
//            
//            double rh = ah - absUserHeading;
//            
//            while (rh > 180.0)
//                rh -= 360.0;
//            
//            while (rh < -180.0)
//                rh += 360.0;
//            
//            if (ire.imageMetadata.imageID == 921)
//            {
//                NSLog(@"grh: %f, orh: %f, gah: %f, oah: %f, guh: %f, ouh: %f",
//                      rh, ire.imageMetadata.relHeading, ah, ire.imageMetadata.absHeading, absUserHeading, relUserHeading);
//            }
            

        }
    }
    
    // remove those from nearbyList that can not be seen (too far away)
    for (FluxImageRenderElement *ire in removeList)
    {
//        NSLog(@"image %d: removed", ire.imageMetadata.imageID);
        [elementList removeObject:ire];
    }
    
}

-(void) updateImageMetadataForElement:(FluxImageRenderElement*)element
{
    //    NSLog(@"Adding metadata for key %@ (dictionary count is %d)", key, [fluxNearbyMetadata count]);
    GLKQuaternion quaternion;
    
    FluxScanImageObject *locationObject = element.imageMetadata;
    
    element.imagePose->position.x =  locationObject.latitude;
    element.imagePose->position.y =  locationObject.longitude;
    element.imagePose->position.z =  locationObject.altitude;
    
    if(locationObject.location_data_type == location_data_valid_ecef)
    {
        element.imagePose->validECEFEstimate = 1;
        element.imagePose->ecef.x = locationObject.ecefX;
        element.imagePose->ecef.y = locationObject.ecefY;
        element.imagePose->ecef.z = locationObject.ecefZ;
    }
    else
    {
        element.imagePose->validECEFEstimate = 0;
    }
    
    quaternion.x = locationObject.qx;
    quaternion.y = locationObject.qy;
    quaternion.z = locationObject.qz;
    quaternion.w = locationObject.qw;
    
    GLKMatrix4 quatMatrix =  GLKMatrix4MakeWithQuaternion(quaternion);
    GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    element.imagePose->rotationMatrix =  GLKMatrix4Multiply(matrixTP, quatMatrix);
    //    NSLog(@"Loaded metadata for image %d quaternion [%f %f %f %f]", idx, quaternion.x, quaternion.y, quaternion.z, quaternion.w);

}

-(void)updateImageMetaData
{
    viewParameters vpimage;
    GLKVector3 planeNormal;
    GLKMatrix4 tMVP;
    float distance = _projectionDistance;
    FluxScanImageObject *scanimageobject;
    sensorPose imagehomographyPose;
    // null out the valid bits...
    for (int i = 0; i < MAX_TEXTURES; i++)
        _validMetaData[i] = 0;
    
    for (FluxImageRenderElement *ire in self.renderList)
    {
        scanimageobject = ire.imageMetadata;
        imagehomographyPose = scanimageobject.imageHomographyPose;
        if (ire.textureMapElement != nil)
        {
            int idx = ire.textureMapElement.textureIndex;
            
//
            ;
            if(scanimageobject.location_data_type == location_data_from_homography)
            {
                _validMetaData[idx] = [self computeProjectionParametersMatchedImageWithImagePose:&imagehomographyPose userHomographyPose:scanimageobject.userHomographyPose planeNormal:&planeNormal Distance:distance currentUserPose:_userPose viewParamters:&vpimage]*
                                 self.fluxDisplayManager.locationManager.notMoving ;
            }
            else
            {
                _validMetaData[idx] = (computeProjectionParametersImage(ire.imagePose, &planeNormal, distance, _userPose, &vpimage) *
                                       self.fluxDisplayManager.locationManager.notMoving);
            }
            
            tViewMatrix = GLKMatrix4MakeLookAt(vpimage.origin.x, vpimage.origin.y, vpimage.origin.z,
                                               vpimage.at.x, vpimage.at.y, vpimage.at.z,
                                               vpimage.up.x, vpimage.up.y, vpimage.up.z);
            tMVP = GLKMatrix4Multiply(camera_perspective,tViewMatrix);
            
            _tBiasMVP[idx] = GLKMatrix4Multiply(biasMatrix,tMVP);
        }
        else
        {
            // TS: should generate an error here - should never get here...
        }
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
    
    
    
    /*
     NSError *error;
     NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
     
     _texture[7] = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"background" ofType:@"png"] options:options error:&error];
     if (error) NSLog(@"Image texture error %@", error);
     
     glActiveTexture(GL_TEXTURE7);
     glBindTexture(_texture[7].target, _texture[7].name);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    */
    
    [self setupBuffers];
    [self loadAlphaTexture];
    //[pedoLabel setText:@"ped"];
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

- (void) loadAlphaTexture
{
    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
   options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderGrayscaleAsAlpha];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int maskType = [[defaults objectForKey:@"Mask"] integerValue];
    _texture[5] = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i",maskType] ofType:@"png"] options:options error:&error];
    if (error) NSLog(@"Image texture error %@", error);
    
//    _texture[5] = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"] options:options error:&error];
//    if (error) NSLog(@"Image texture error %@", error);
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(_texture[5].target, _texture[5].name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
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

// IMPORTANT: Call this method after you draw and before -presentRenderbuffer:.
- (UIImage*)snapshot:(UIView*)eaglview
{
    GLint backingWidth, backingHeight;
    
    // Bind the color renderbuffer used to render the OpenGL ES view
    // If your application only creates a single color renderbuffer which is already bound at this point,
    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
    // Note, replace "_colorRenderbuffer" with the actual name of the renderbuffer object defined in your class.
    //glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorRenderbuffer);
    
    // Get the size of the backing CAEAGLLayer
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    NSInteger x = 0, y = 0, width = backingWidth, height = backingHeight;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    // Read pixel data from the framebuffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    // otherwise, use kCGImageAlphaPremultipliedLast
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    NSInteger widthInPoints, heightInPoints;
    if (NULL != UIGraphicsBeginImageContextWithOptions) {
        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
        // Set the scale parameter to your OpenGL ES view's contentScaleFactor
        // so that you get a high-resolution snapshot when its value is greater than 1.0
        CGFloat scale = eaglview.contentScaleFactor;
        widthInPoints = width / scale;
        heightInPoints = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    else {
        // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
        widthInPoints = width;
        heightInPoints = height;
        UIGraphicsBeginImageContext(CGSizeMake(widthInPoints, heightInPoints));
    }
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    return image;
}

#pragma mark - render image texture and metadata selection and loading methods 

- (NSError *)loadTexture:(int)tIndex withImage:(UIImage *)image
{
    
    // load the actual texture
    NSError *error;
    
    [self deleteImageTextureIdx:tIndex];

    // Load the new texture
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    NSData *imgData = UIImageJPEGRepresentation(image, 1); // 1 is compression quality
    _texture[tIndex] = [GLKTextureLoader textureWithContentsOfData:imgData options:options error:&error];
    
    if (error)
    {
        _texture[tIndex] = nil;
        NSLog(@"Error loading Image texture (error: %@)", error);
    }

    return error;
}

- (void)updateTextures
{
    // textureList is array of textureToImageMapElement
    // using the mapping, find if the image is already loaded into a texture
    // spin through texture mapping and mark each as "unused",
    for (FluxTextureToImageMapElement *tel in self.textureMap)
    {
        tel.used = false;
    }
    
    // spin through renderlist, find associated texture mapping (by LocalID) and mark mapping as "used"
    for (FluxImageRenderElement *ire in self.renderList)
    {
        if (ire.textureMapElement != nil)
        {
            if ([ire.textureMapElement.localID isEqualToString:ire.localID])
            {
                ire.textureMapElement.used = true;
            }
            else
            {
                // not a match - clear it out
                ire.textureMapElement = nil;
            }
        }
    }
    
    bool loadedOneHiRes = false;
    // spin through renderlist, find associated texture mapping
    //      if not found, find "unused"
    for (FluxImageRenderElement *ire in self.renderList)
    {
        int textureIndex = -1;
        bool justLoaded = false;
        if (ire.textureMapElement == nil)
        {
            // find a new texture and load it up...
            FluxTextureToImageMapElement *newTel = nil;
            double rhead = -1.0;
            for (FluxTextureToImageMapElement *tel in self.textureMap)
            {
                if (tel.used == false)
                {
                    // find a match...
                    if ((tel.localID != nil) && ([tel.localID isEqual:ire.localID]))
                    {
                        // have a match - can just link it up and continue on...
                        tel.used = true;
                        textureIndex = tel.textureIndex;
                        ire.textureMapElement = tel;
                        newTel = nil;
                        break;
                    }
                    
                    // ... or the farthest away to use for the new image
                    FluxImageRenderElement *lire = nil;
                    if (tel.localID != nil)
                        lire = [self.fluxDisplayManager getRenderElementForKey:tel.localID];
                    
                    if (lire == nil)
                    {
                        newTel = tel;
                        break;
                    }
                    else if (fabs(lire.imageMetadata.relHeading) > rhead)
                    {
                        newTel = tel;
                        rhead = fabs(lire.imageMetadata.relHeading);
                    }
                    else if (newTel == nil)
                    {
                        newTel = tel;
                    }
                }
            }
            
            if (newTel != nil)
            {
                // not found so always load lowest resolution (thumb typically)
                FluxImageType rtype = none;
                UIImage *image = [self.fluxDisplayManager.fluxDataManager fetchImagesByLocalID:ire.localID withSize:lowest_res returnSize:&rtype];
                
                if (image != nil)
                {
                    textureIndex = newTel.textureIndex;
                    if (newTel.localID != nil)
                    {
                        // break link from old ire to tel - need to search and update it.
                        FluxImageRenderElement *tire = [self.fluxDisplayManager getRenderElementForKey:newTel.localID];
                        if (tire != nil)
                        {
                            tire.textureMapElement = nil;
                        }
                    }

                    NSError *error = [self loadTexture:textureIndex withImage:image];
                    
                    if (error)
                    {
                        textureIndex = -1;
                    }
                    else
                    {
                        // found one - set it up...
                        ire.textureMapElement = newTel;
                        ire.imageRenderType = rtype;
                        ire.image = image;
                        newTel.imageType = rtype;
                        newTel.used = true;
                        newTel.localID = ire.localID;
                        justLoaded = true;
//                        int width = CGImageGetWidth(image.CGImage);
//                        int height = CGImageGetWidth(image.CGImage);
//
//                        NSLog(@"Loaded Image texture in slot %d for key %@, %d, (%d,%d)", (textureIndex),ire.localID, newTel.imageType, width, height);
                    }
                    break;
                }
                else
                {
                    NSLog(@"GLVC:UpdateTextures: lowest_res texture not found in cache");
                }
            }
        }
        else
        {
            textureIndex = ire.textureMapElement.textureIndex;
//            NSLog(@"Recycling texture in slot %d for key %@, size: %d", textureIndex, ire.localID, ire.imageType);
        }

        if ((textureIndex >= 0) && (!justLoaded) && (!loadedOneHiRes))
        {
            if (ire.textureMapElement.imageType < ire.imageRenderType)
            {
                // new one is bigger - load it up... if need to load up...
                FluxImageType rtype = none;
                UIImage *image = [self.fluxDisplayManager.fluxDataManager fetchImagesByLocalID:ire.localID withSize:ire.imageRenderType returnSize:&rtype];

                if (image != nil)
                {
                    NSError *error = [self loadTexture:textureIndex withImage:image];
                    
                    if (error)
                    {
                        textureIndex = -1;
                        NSLog(@"Failed to load texture %d for ID %@", rtype, ire.localID);
                    }
                    else
                    {
                        FluxTextureToImageMapElement *tel = ire.textureMapElement;
                        tel.imageType = rtype;
                        ire.imageRenderType = rtype;
                        ire.image = image;
                        loadedOneHiRes = true;
                        tel.used = true;
                        justLoaded = true;
                        
//                        int width = CGImageGetWidth(image.CGImage);
//                        int height = CGImageGetWidth(image.CGImage);
//
//                        NSLog(@"Updated Image texture in slot %d for key %@, %d, (%d,%d)", (textureIndex),ire.localID, ire.imageRenderType, width, height);

                        // Queue up image for feature matching with background camera feed
                        if (!ire.imageMetadata.matched)
                        {
                            // Only add object image + metadata to queue - scene object will be grabbed by matcher
                            [fluxFeatureMatchingQueue addMatchRequest:ire withOpenGLVC:self];
                        }
                    }
                }
                else
                {
                    NSLog(@"GLVC:UpdateTextures: upgrade_res texture not found in cache - not updating");
                }
            }
        }
    }
    
    // Spin through list of elements and see if any are failed matches. Retry.
    for (FluxImageRenderElement *ire in self.renderList)
    {
        if (ire.imageMetadata.matchFailed && [[NSDate date] timeIntervalSinceDate:ire.imageMetadata.matchFailureTime] > 10.0)
        {
            // Reset failure state so it doesn't get queued up again until matching is complete or fails again
            ire.imageMetadata.matchFailed = NO;

            // Only add object image + metadata to queue - scene object will be grabbed by matcher
            [fluxFeatureMatchingQueue addMatchRequest:ire withOpenGLVC:self];
        }
    }
    
    for (FluxTextureToImageMapElement *tel in self.textureMap)
    {
        if ((!tel.used) && (tel.localID != nil))
        {
            // break link from old ire to tel - need to search and update it.
            FluxImageRenderElement *tire = [self.fluxDisplayManager getRenderElementForKey:tel.localID];
            if (tire != nil)
            {
                tire.textureMapElement = nil;
            }
//            tel.localID = nil;
//            tel.imageType = none;
//
//            [self deleteImageTextureIdx:tel.textureIndex];
        }
    }
    

//    NSLog(@"Done texture loading");
}

- (void)fixRenderList
{
    [self.fluxDisplayManager lockDisplayList];
    
        int oldDisplayListHasChanged = _displayListHasChanged;

        self.renderList = [self.fluxDisplayManager selectRenderElementsInto:self.renderList ToMaxCount:number_textures];
    
//        // there may be other things to do besides transfer data so that is why it isn't just incorporated into sortRenderList
//        [self.renderList removeAllObjects];
//
//        int maxDisplayCount = self.fluxDisplayManager.displayListCount;
//        maxDisplayCount = MIN(maxDisplayCount, number_textures);
//        if (maxDisplayCount > 0)
//        {
//            [self.fluxDisplayManager lockDisplayList];
//            [self.renderList addObjectsFromArray:[self.fluxDisplayManager.displayList subarrayWithRange:NSMakeRange(0, maxDisplayCount)]];
//            [self.fluxDisplayManager unlockDisplayList];
//        }

        _displayListHasChanged -= MIN(_displayListHasChanged, oldDisplayListHasChanged);    // make sure it doesn't go (-ve)
    
    [self.fluxDisplayManager unlockDisplayList];

    if ([self.renderList count ] > 0)
    {
        [self.fluxDisplayManager sortRenderList:self.renderList];
    }
    
    [self updateTextures];
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)render{
    [self update];
    [self glkView:(GLKView*)self.view drawInRect:self.view.bounds];
    [(GLKView*)self.view display];
}

- (void)update
{
    if (_displayListHasChanged > 0)
    {
        [self fixRenderList];
    }
    
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
    
    [self computeRTFromHomography];
    [self testTransforms];
    

    
    if(self.fluxDisplayManager.locationManager.kflocation.valid ==1)
    {
        
        _userPose.ecef.x =  self.fluxDisplayManager.locationManager.kflocation.x;
        _userPose.ecef.y =  self.fluxDisplayManager.locationManager.kflocation.y;
        _userPose.ecef.z =  self.fluxDisplayManager.locationManager.kflocation.z;
        
        // [self printDebugInfo];
    }

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
    
//    _imagePose[7].position.x =0.0;
//    _imagePose[7].position.y =0.0;
//    _imagePose[7].position.z =0.0;
    
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
    
//    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX0], 1, 0, _tBiasMVP[0].m);
//    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX1], 1, 0, _tBiasMVP[1].m);
//    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX2], 1, 0, _tBiasMVP[2].m);
//    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX3], 1, 0, _tBiasMVP[3].m);
//    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX4], 1, 0, _tBiasMVP[4].m);
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
    
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(_texture[5].target, _texture[5].name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER5], 5);

    
    // then spin through the images...
    NSEnumerator *revEnumerator = [self.renderList reverseObjectEnumerator];
    int c = 0;
    for (FluxImageRenderElement *ire in revEnumerator)
    {
        if (ire.textureMapElement)
        {
            int i = ire.textureMapElement.textureIndex;

            if ((ire.textureMapElement.used) && (_texture[i] != nil) && (_validMetaData[i]==1))
            {
//                NSLog(@"    binding texture from slot %d, id %@, to gltexture %d", i, ire.localID, c);

                glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX0 + c], 1, 0, _tBiasMVP[i].m);

                glUniform1i(uniforms[UNIFORM_RENDER_ENABLE0+c],1);
                glActiveTexture(GL_TEXTURE0 + c);
                glBindTexture(_texture[i].target, _texture[i].name);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER0 + c], c);
                c++;
            }
        }
    }
    
    for ( ; c < number_textures; c++)
    {
//        NSLog(@"Blank binding unused gltexture %d", c);
        glActiveTexture(GL_TEXTURE0 + c);
        glBindTexture(GL_TEXTURE_2D, 0);
        glUniform1i(uniforms[UNIFORM_RENDER_ENABLE0+c],0);
    }

    glDrawElements(GL_TRIANGLES, 6,GL_UNSIGNED_BYTE,0);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (void) checkShaderLimitations{
    GLint maxtextureunits;
    GLint maxvertextureunits;
    
    glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxtextureunits);
//    NSLog(@"Maximum texture image units = %d",maxtextureunits);
    
    glGetIntegerv(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, &maxvertextureunits);
//    NSLog(@"Maximum vertex texture image unit = %d",maxvertextureunits);
    
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
    uniforms[UNIFORM_MYTEXTURE_SAMPLER5] = glGetUniformLocation(_program, "textureSampler[5]");
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

#pragma --- kalman filter debug ---

-(void) printDebugInfo
{
    double distancef;
    double tx, ty, tkx, tky;
    
    
    NSString *rawXS = [NSString stringWithFormat:@"RX: %f",self.fluxDisplayManager.locationManager.kfdebug.gpsx];
    [gpsX setText:rawXS];
   
    
    NSString *rawYS = [NSString stringWithFormat:@"RY: %f",self.fluxDisplayManager.locationManager.kfdebug.gpsy];
    [gpsY setText:rawYS];
    
    NSString *kXS = [NSString stringWithFormat:@"kX: %f",self.fluxDisplayManager.locationManager.kfdebug.filterx];
    [kX setText:kXS];
    
    NSString *kYS = [NSString stringWithFormat:@"kY: %f",self.fluxDisplayManager.locationManager.kfdebug.filtery];
    [kY setText:kYS];
    
    tkx = self.fluxDisplayManager.locationManager.kfdebug.gpsx;
    tky = self.fluxDisplayManager.locationManager.kfdebug.gpsy;
    tx = self.fluxDisplayManager.locationManager.kfdebug.filterx -tkx;
    ty = self.fluxDisplayManager.locationManager.kfdebug.filtery -tky;
    
    distancef = sqrt(tx*tx + ty*ty);
    
    NSString *distanceS = [NSString stringWithFormat:@"D: %f",distancef];
    [delta setText:distanceS];

    
    
}

double ci[9];
double ciinverse[9];
//using column major ordering

-(int) invertCameraIntrinsics
{
    int dim = 3;
    long lWork = dim * dim;
    long info = -1;
    long n = dim;
   
    long * ipiv = malloc((dim +1) *sizeof (long));
     double *work = malloc(dim * dim *sizeof(double));    int i;
    for(i=0;i <9;i++)
        ciinverse[i] = ci[i];
    
    dgetrf_(&n, &n,ciinverse, &n, ipiv, &info);
    dgetri_(&n, ciinverse, &n, ipiv, work, &lWork,&info );
    
   
    
    return info;
}

- (void)setCameraIntrinsics
{
    double pixel = 0.0000014; //1.4 microns Pixel Size for iPhone5
    double fx, fy;
    double ox, oy;
    
    float focalL = 0.0041; //4.10 mm iPhone5
    
    fx = focalL/pixel;
    fy = focalL/pixel;
    ox = 1080.0/2.0; //quarter hd
    oy = 1920.0/2.0; //quarter hd
    
    ci[0] = -1.0 * fx;
    ci[1] = 0.0;
    ci[2] = 0.0;
    ci[3] = 0.0;
    ci[4] = -1.0 * fy;
    ci[5] = 0.0;
    ci[6] = ox;
    ci[7] = oy;
    ci[8] = 1.0;
    
    [self invertCameraIntrinsics];
    
}

- (void)computeSVD33: (double*)a U:(double*)u S:(double*)s vT:(double*) vt
{
    long m = 3;
    long n = 3;
    long lda= 3;
    
    //column major for lapack
    
    double workSize;
    double *work = &workSize;
    long lwork = -1;
    long iwork[24];
    long info = 0;
    char jobz[1];
    jobz[0] = 'A';
    dgesdd_(jobz, &m, &n, &a[0], &lda, s, u, &m, vt, &n, work, &lwork, iwork, &info);
    NSLog(@"workSize = %f", workSize);
    lwork = workSize;
    work =(double*) malloc(lwork *sizeof(double));
    dgesdd_(jobz, &m, &n, &a[0], &lda, s, u, &m, vt, &n, work, &lwork, iwork, &info);
   
    free(work);
}

//u X v
-(void) crossProductVec1:(double*) u Vec2:(double*) v vecResult:(double *) r
{
    r[0] = u[1]*v[2] - u[2] * v[1];
    r[1] = u[2]*v[0] - u[0] * v[2];
    r[2] = u[0]*v[1] - u[1] * v[0];
}

typedef struct
{
    double normal[3];
    double translation[3];
    double rotation[9];//col major
}homographyRTn;

homographyRTn result1, result2;


-(int) computeRTFromHomography
{
    double pH[9]; //projective homography set this in OpenCV
    double tmpMat[9];
    double eH[9]; //Euclidean Homography
    double HtH[9];
    double s[3];
    double u[9];
    double vt[9];
    double scale;
    double scaleSq;
    double tmp3;
    double tmp1Vec[3];
    double tmp2Vec[3];
    double tmp3Vec[3];
    int i;
    double u1[3], u2[3], v1[3], v2[3], v3[3];
    double U1[9], U2[9], W1[9], W2[9];
    double sign = 1.0;
    
    
    
    
    //calculate euclidean homography
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 3, 3, 1.0, ciinverse, 3, pH, 3, 0.0, tmpMat, 3);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 3 , 3, 1.0, tmpMat, 3, ci, 3, 0.0, eH, 3);
    //test
    eH[0] = 1.53205;
    eH[1] =1.0;
    eH[2] = 0.0;
    eH[3] = -0.5;
    eH[4] = 0.866025;
    eH[5] = -1.73205;
    eH[6] = -0.866025;
    eH[7] = 1.5;
    eH[8] = 1.0;
    cblas_dgemm(CblasColMajor, CblasTrans, CblasNoTrans, 3, 3, 3, 1.0, eH, 3, eH, 3, 0.0, HtH, 3);
    [self computeSVD33: &HtH[0] U:&u[0] S:&s[0] vT:&vt[0]];
    NSLog(@"SVD s:[%.4f %.4f %.4f ]",s[0], s[1], s[2]);
    
    if(s[0]-s[2]< 1e-5)
    {
        NSLog(@"cannot compute transfroms no relative motion");
        return -1;
    }
        
    scaleSq = 1.0/s[1];
    scale = sqrt(scaleSq);
    
    for(i = 0; i <3; i++)
        s[i]*=scaleSq;
    
    for(i=0; i <3; i++)
    {
        v1[i] = vt[i];
        v2[i] = vt[i+3];
        v3[i] = vt[i+6];
    }
    
    for(i=0; i <3; i++)
    {
        tmp1Vec[i] = v1[i] * sqrt(1.0 -s[2]);
        tmp2Vec[i] = v3[i] * sqrt(s[0] -1.0);
        
    }
    
    tmp3 = 1.0/(sqrt(s[0]-s[2]));
    
    for(i=0; i <3; i++)
    {
      u1[i] = tmp3 * (tmp1Vec[i] + tmp2Vec[i]);
      u2[i] = tmp3 * (tmp1Vec[i] - tmp2Vec[i]);
    }
    
    //Set U1
    [self crossProductVec1:v2 Vec2:u1 vecResult:tmp1Vec];
    for(i=0; i<3; i++)
    {
        U1[i] = v2[i];
        U1[i+3] = u1[i];
        U1[i+6] = tmp1Vec[i];
    }
    
    //Set U2
    [self crossProductVec1:v2 Vec2:u2 vecResult:tmp1Vec];
    for(i=0; i<3; i++)
    {
        U2[i] = v2[i];
        U2[i+3] = u2[i];
        U2[i+6] = tmp1Vec[i];
    }
    
    //Set W1
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, scale, eH, 3, v2, 3, 0.0, tmp1Vec, 3);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, scale, eH, 3, u1, 3, 0.0, tmp2Vec, 3);
    [self crossProductVec1:tmp1Vec Vec2:tmp2Vec vecResult:tmp3Vec];
    for(i=0; i<3; i++)
    {
        W1[i] = tmp1Vec[i];
        W1[i+3] = tmp2Vec[i];
        W1[i+6] = tmp3Vec[i];
    }
    
    //Set W2
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, scale, eH, 3, u2, 3, 0.0, tmp2Vec, 3);
    [self crossProductVec1:tmp1Vec Vec2:tmp2Vec vecResult:tmp3Vec];
    for(i=0; i<3; i++)
    {
        W2[i] = tmp1Vec[i];
        W2[i+3] = tmp2Vec[i];
        W2[i+6] = tmp3Vec[i];
    }
    
    //Result 1
    [self crossProductVec1:v2 Vec2:u1 vecResult:result1.normal];
    (result1.normal[2] < 0) ? (sign = -1.0) : (sign = 1.0);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasTrans, 3, 3, 3, 1.0, W1, 3, U1, 3, 1.0, result1.rotation, 3);
    
    for(i=0; i<3; i++)
        result1.normal[i] *=sign;
    for(i=0; i<9; i++)
        tmpMat[i] = scale* eH[i] - result1.rotation[i];
    
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, 1.0, tmpMat, 3, result1.normal, 3, 0.0, result1.translation, 3);
    
    //Result2
    [self crossProductVec1:v2 Vec2:u2 vecResult:result2.normal];
    (result2.normal[2] < 0) ? (sign = -1.0) : (sign = 1.0);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasTrans, 3, 3, 3, 1.0, W2, 3, U2, 3, 1.0, result2.rotation, 3);
    
    for(i=0; i<3; i++)
        result2.normal[i] *=sign;
    for(i=0; i<9; i++)
        tmpMat[i] = scale* eH[i] - result2.rotation[i];
    
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, 1.0, tmpMat, 3, result2.normal, 3, 0.0, result2.translation, 3);
    
    
    NSLog(@"v1 [%.6f %.6f %.6f]", v1[0], v1[1], v1[2]);
    NSLog(@"v2 [%.6f %.6f %.6f]", v2[0], v2[1], v2[2]);
    NSLog(@"v3 [%.6f %.6f %.6f]", v3[0], v3[1], v3[2]);
    NSLog(@"u1 [%.6f %.6f %.6f]", u1[0], u1[1], u1[2]);
    NSLog(@"u2 [%.6f %.6f %.6f]", u2[0], u2[1], u2[2]);
    
    
    
    
    
    return 0;
}


-(void) testTransforms
{

    NSLog(@"---------------------------------");
    NSLog(@"normal [%.6f %.6f %.6f]", result1.normal[0], result1.normal[1], result1.normal[2]);
    NSLog(@"translation [%.6f %.6f %.6f]", result1.translation[0], result1.translation[1], result1.translation[2]);
    NSLog(@"rotation1 [%.6f %.6f %.6f]", result1.rotation[0], result1.rotation[3], result1.rotation[6]);
    NSLog(@"rotation1 [%.6f %.6f %.6f]", result1.rotation[1], result1.rotation[4], result1.rotation[7]);
    NSLog(@"rotation1 [%.6f %.6f %.6f]", result1.rotation[2], result1.rotation[5], result1.rotation[8]);

    NSLog(@"---------------------------------");
    NSLog(@"normal [%.6f %.6f %.6f]", result2.normal[0], result2.normal[1], result2.normal[2]);
    NSLog(@"translation [%.6f %.6f %.6f]", result2.translation[0], result2.translation[1], result2.translation[2]);

    NSLog(@"rotation1 [%.6f %.6f %.6f]", result2.rotation[0], result2.rotation[3], result2.rotation[6]);
    NSLog(@"rotation1 [%.6f %.6f %.6f]", result2.rotation[1], result2.rotation[4], result2.rotation[7]);
    NSLog(@"rotation1 [%.6f %.6f %.6f]", result2.rotation[2], result2.rotation[5], result2.rotation[8]);
    

}

- (IBAction)stepperChanged:(id)sender {
    
    }

@end
