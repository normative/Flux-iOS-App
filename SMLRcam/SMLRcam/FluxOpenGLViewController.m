//
//  ImageViewerViewController.m
//  ImageViewer
//
//  Created by Arjun Chopra on 8/11/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//

#import "FluxOpenGLViewController.h"
#import "ImageViewerImageUtil.h"
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_TBIASMVP_MATRIX,
    UNIFORM_MYTEXTURE_SAMPLER,
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
    
    0.5f, 0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f
};


GLfloat textureCoord[12] =
{
    
    1.0f, 1.0f,
    0.0f, 1.0f,
    1.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    0.0f, 0.0f
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

void init_pose()
{
    
    
    
}




void init_camera_model()
{
	float _fov = 2 * atan2(iPhone5_pixelsize*3264.0/2.0, iPhone5_focalLength); //radians
    fprintf(stderr,"FOV = %.4f degrees\n", _fov *180.0/3.14);
    float aspect = (float)iPhone5_xpixels/(float)iPhone5_ypixels;
    camera_perspective = 	GLKMatrix4MakePerspective(_fov * 180.0/3.14, aspect, 0.001f, 50.0f);
    
}
/*
 int init_texture(int width, int height)
 {
 int i;
 
 fprintf(stderr, "w = %d, h = %d\n", width, height);
 
 
 for(i =0; i <3; i++)
 {
 glGenTextures(1, &texture[i]);
 glBindTexture(GL_TEXTURE_2D, texture[i]);
 
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
 
 glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
 
 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE,NULL);
 //        glGenerateMipmap(GL_TEXTURE_2D);
 glBindTexture(GL_TEXTURE_2D, 0);
 }
 return 1;
 }
 */


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
    
    rotation_teM = GLKMatrix4MakeWithArray(rotation_te);
    
};
/*
 void test_wgs84_tangent_conversions()
 {
 lla_rad.x = 0.59341195;
 lla_rad.y = -2.0478571;
 lla_rad.z = 251.702;
 
 WGS84_to_ECEF();
 
 fprintf(stderr,"TEST\n");
 fprintf(stderr,"----\n");
 fprintf(stderr,"ecef.x = %.1f m (-2430601.8) \n", ecef.x);
 fprintf(stderr,"ecef.y = %.1f m (-4702442.7) \n", ecef.y);
 fprintf(stderr,"ecef.z = %.1f m (3546587.4)\n", ecef.z);
 }
 */
void setParametersTP(GLKVector3 location){
    
}
void setupViewingPlane(GLKVector3 position, GLKMatrix4 rotationMatrix, float distance)
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
     //   result[i] = GLKMatrix4MultiplyVector4( GLKMatrix4Transpose(basenormalMat), pts[i]);
        //   fprintf(stderr, "i: x=%.4f y=%.4f z = %.4f \n",result[i].x, result[i].y, result[i].z);
    }

    
}
void calculateCoordinatesTP(GLKVector3 originposition, GLKVector3 position, GLKVector3 *positionTP)
{
    
}
int computeProjectionParametersUser(sensorPose *sp, GLKVector3 *planeNormal, float distance, viewParameters *vp, GLKVector3 userLocation)
{
    viewParameters viewP;
	GLKVector3 positionTP;
    //sp->rotation = Matrix4MakeFromYawPitchRoll(sp->.x, sp->position.y, sp->position.z);
    if(distance <0.0)
    {
        NSLog(@"distance is a scalar, setting to positive");
        distance =  -1.0 *distance;
    }
    
    setParametersTP(userLocation);
    
    NSLog(@"positionTP:%f %f %f", positionTP.x, positionTP.y, positionTP.y);
    
    // rotationMat = rotationMat_t;
    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(sp->rotationMatrix, zRay);
    
    
    NSLog(@"Projection vector: [%f, %f, %f]", v.x, v.y, v.z);
    
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3(sp->rotationMatrix, planeNormalI);
    //intersection with plane
    GLKVector3 N = planeNormalRotated;
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
    
    float vd = GLKVector3DotProduct(N,V);
    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
    float t = v0/vd;
    
    if(vd==0)
    {
        NSLog(@"Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
        return -1;
    }
    if(v0 < 0)
    {
        
        NSLog(@"Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
        return -1;
    }
    
    
    
    viewP.at = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
    viewP.up = GLKMatrix4MultiplyVector3(rotationMat, GLKVector3Make(0.0, 1.0, 0.0));
    viewP.up = GLKVector3Normalize(viewP.up);
    
    (*vp).origin = GLKVector3Add(positionTP, P0);
    (*vp).at = GLKVector3Add(positionTP, viewP.at);
    (*vp).up = GLKVector3Add(positionTP, viewP.up);
    
    
    // setupViewingPlane(positionTP, sp->rotationMatrix, distance);
    
    return 0;
}
//distance - distance of plane
int computeProjectionParametersImage(sensorPose *sp, GLKVector3 *planeNormal, float distance, GLKVector3 userLocation, viewParameters *vp)
{
    
    viewParameters viewP;
	GLKVector3 positionTP;
   //sp->rotation = Matrix4MakeFromYawPitchRoll(sp->.x, sp->position.y, sp->position.z);
    if(distance <0.0)
    {
        NSLog(@"distance is a scalar, setting to positive");
        distance =  -1.0 *distance;
    }
    
    calculateCoordinatesTP(userLocation, sp->position, &positionTP);
    
    NSLog(@"positionTP:%f %f %f", positionTP.x, positionTP.y, positionTP.y);

   // rotationMat = rotationMat_t;
    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(sp->rotationMatrix, zRay);
    
    
    NSLog(@"Projection vector: [%f, %f, %f]", v.x, v.y, v.z);
    
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3(sp->rotationMatrix, planeNormalI);
    //intersection with plane
    GLKVector3 N = planeNormalRotated;
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
   
    
    float vd = GLKVector3DotProduct(N,V);
    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
    float t = v0/vd;

    if(vd==0)
    {
        NSLog(@"Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
        return -1;
    }
    if(v0 < 0)
    {
        
        NSLog(@"Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
        return -1;
    }

    
    
    viewP.at = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
    viewP.up = GLKMatrix4MultiplyVector3(rotationMat, GLKVector3Make(0.0, 1.0, 0.0));
    viewP.up = GLKVector3Normalize(viewP.up);
    
    (*vp).origin = GLKVector3Add(positionTP, P0);
    (*vp).at = GLKVector3Add(positionTP, viewP.at);
    (*vp).up = GLKVector3Add(positionTP, viewP.up);
    
    
     // setupViewingPlane(positionTP, sp->rotationMatrix, distance);
    
    return 0;
}


void compute_new_intersection()
{
    bool isinvertible;
	
    GLKMatrix4 rotationMat_t= GLKMatrix4Make(
                                             -0.694398, -0.469567, 0.54527, 0, 0.577056, 0.0893289, 0.811804, 0, -0.429905, 0.878366, 0.208937, 0, 0, 0, 0, 1);
    
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
    
    
  
    GLKVector4 up = GLKMatrix4MultiplyVector4(rotationMat, GLKVector4Make(0.0, 1.0, 0.0, 1.0));
    upvec = GLKVector3Normalize(GLKVector3Make(up.x, up.y, up.z));
    
    
    //set eye
    GLKVector4 _eye_at = GLKMatrix4MultiplyVector4(GLKMatrix4Invert(basenormalMat, &isinvertible) ,GLKVector4Make(0.0, 14.0, 0.0, 1.0));
    eye_at = GLKVector3Make(_eye_at.x, _eye_at.y, _eye_at.z);
    eye_origin = GLKVector3Make(0.0, 0.0, 0.0);
    eye_up = GLKVector3Make(0.0, 0.0, 1.0);
    
    NSLog(@"eye_at: %f %f %f", eye_at.x, eye_at.y, eye_at.z);
    NSLog(@"eye_origin: %f %f %f", eye_origin.x, eye_origin.y, eye_origin.z);
    NSLog(@"eye_up: %f, %f %f", eye_up.x, eye_up.y, eye_up.z);
    
}

GLKVector4 result[4];
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

void init(){
    
    
    biasMatrix= GLKMatrix4Make(
                               0.5, 0.0, 0.0, 0.0,
                               0.0, 0.5, 0.0, 0.0,
                               0.0, 0.0, 0.5, 0.0,
                               0.5, 0.5, 0.5, 1.0
                               );
    init_camera_model();
    
    
};
/*
 GLfloat gCubeVertexData[216] =
 {
 // Data layout for each line below is:
 // positionX, positionY, positionZ,     normalX, normalY, normalZ,
 0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
 0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
 0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
 0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
 0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
 0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
 
 0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
 -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
 0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
 0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
 -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
 -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
 
 -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
 -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
 -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
 -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
 -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
 -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
 
 -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
 0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
 -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
 -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
 0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
 0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
 
 0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
 -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
 0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
 0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
 -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
 -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
 
 0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
 -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
 0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
 0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
 -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
 -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
 };
 */

@implementation FluxOpenGLViewController

@synthesize imageDict,theDelegate;

#pragma mark - Location

//allocates the location object and sets some parameters
- (void)setupLocationManager
{
    // Create the manager object
    locationManager = [FluxLocationServicesSingleton sharedManager];
}

- (void)didUpdateHeading:(NSNotification *)notification{
    //CLLocationDirection heading = locationManager.heading;
    CMAttitude *att = motionManager.attitude;
    NSLog(@"Attitude: %f, %f, %f", att.pitch, att.yaw, att.roll);
}

- (void)didUpdateLocation:(NSNotification *)notification{
    CLLocation *loc = locationManager.location;
    [networkServices getImagesForLocation:loc.coordinate andRadius:50];
}


#pragma mark - Network Services
- (void)setupNetworkServices{
    networkServices = [[FluxNetworkServices alloc]init];
    [networkServices setDelegate:self];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageList:(NSMutableDictionary *)imageList{
    imageDict = imageList;
    if ([theDelegate respondsToSelector:@selector(OpenGLView:didUpdateImageList:)]) {
        [theDelegate OpenGLView:self didUpdateImageList:imageDict];
    }
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImage:(UIImage *)image forImageID:(int)imageID{
    
}

#pragma mark - Motion Manager

//starts the motion manager and sets an update interval
- (void)setupMotionManager{
    motionManager = [FluxMotionManagerSingleton sharedManager];
}

- (void)startDeviceMotion
{
    if (motionManager) {
        [motionManager startDeviceMotion];
    }
}

- (void)stopDeviceMotion
{
    if (motionManager) {
        [motionManager stopDeviceMotion];
    }
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    imageDict = [[NSMutableDictionary alloc]init];
    [self setupLocationManager];
    [self setupMotionManager];
    [self setupNetworkServices];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)viewWillAppear
{
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateHeading:) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateLocation:) name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
        // Call these immediately since location is not always updated frequently (use current value)
        [self didUpdateHeading:nil];
        [self didUpdateLocation:nil];
    }
    
    [self startDeviceMotion];
}

- (void)viewWillDisappear
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
    
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

- (void) checkShaderLimitations{
    GLint maxtextureunits;
    GLint maxvertextureunits;
    
    glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxtextureunits);
    NSLog(@"Maximum texture image units = %d",maxtextureunits);
    
    glGetIntegerv(GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, &maxvertextureunits);
    NSLog(@"Maximum vertex texture image unit = %d",maxvertextureunits);
    
}
- (void)setupBuffers
{
    
    glGenBuffers(1, &_indexVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexdata), indexdata, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_positionVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);
    //    glBufferData(GL_ARRAY_BUFFER, sizeof(testvertexData), testvertexData, GL_STATIC_DRAW);
    
    
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), 0);
    
    glGenBuffers(1, &_texcoordVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(textureCoord), textureCoord, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), 0);
}

- (void)setupGL
{
    
    
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    [self checkShaderLimitations];
    
    init();
    compute_new_intersection();
    multiply_vertices();
    
    
    
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
    
    
    
    
    
    
    glEnable(GL_DEPTH_TEST);
    
    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    _texture = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Image2" ofType:@"png"] options:options error:&error];
    if (error) NSLog(@"Image texture error %@", error);
    
    //bind the texture to texture unit 0
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(_texture.target, _texture.name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
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

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    ray_origin = GLKVector3Make(0.0, 0.0, 0.0);
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(eye_origin.x, eye_origin.y, eye_origin.z, eye_at.x, eye_at.y, eye_at.z , eye_up.x, eye_up.y, eye_up.z);
    
    
    
    
    
   
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelViewMatrix);
    
    

    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    tViewMatrix = GLKMatrix4MakeLookAt(ray_origin.x, ray_origin.y, ray_origin.z, centrevec.x, centrevec.y, centrevec.z, upvec.x, upvec.y, upvec.z);
    
    
    GLKMatrix4 tMVP = GLKMatrix4Multiply(camera_perspective,tViewMatrix);
    
    _tBiasMVP = GLKMatrix4Multiply(biasMatrix,tMVP);




}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX], 1, 0, _tBiasMVP.m);
    
    
    //glActiveTexture(GL_TEXTURE0);
    //glBindTexture(GL_TEXTURE_2D, texture[0]);
    
    // Set our "myTextureSampler" sampler to user Texture Unit 0
    glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER], 0);
    
    
    glDrawElements(GL_TRIANGLES, 6,GL_UNSIGNED_BYTE,0);
    
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shaders/Shader" ofType:@"vsh"];
    // vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"testshader" ofType:@"vsh"];
    //test
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    //test
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shaders/Shader" ofType:@"fsh"];
    //fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"testshader" ofType:@"fsh"];
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
    uniforms[UNIFORM_TBIASMVP_MATRIX] = glGetUniformLocation(_program, "tBiasMVP");
    uniforms[UNIFORM_MYTEXTURE_SAMPLER] = glGetUniformLocation(_program, "textureSampler");
    
    
    
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

@end
