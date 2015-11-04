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
#import "FluxDeviceInfoSingleton.h"
#import "FluxTransformUtilities.h"

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

const int default_number_textures = 5;

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
    
    UNIFORM_SET_SEPIA0,
    UNIFORM_SET_SEPIA1,
    UNIFORM_SET_SEPIA2,
    UNIFORM_SET_SEPIA3,
    UNIFORM_SET_SEPIA4,
    
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
#define SQUAREIMAGES1080P

GLuint texture[3];
GLKMatrix4 camera_perspective;

GLKMatrix4 planeRotationMatrix;
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
// called once based on current device model
void init_camera_model()
{
    FluxCameraModel *cm = [FluxDeviceInfoSingleton sharedDeviceInfo].cameraModel;

//	float _fov = 2.0 * atan2(cm.pixelSize * 1920.0 / 2.0, cm.focalLength); //radians
	float _fov = 2.0 * atan2(cm.pixelSizeScaleToRaw * cm.yPixels / 2.0, cm.focalLength); //radians
    NSLog(@"pixelSizeScaleToRaw %f", cm.pixelSizeScaleToRaw);
    fprintf(stderr,"FOV = %.4f degrees\n", _fov * 180.0 / M_PI);
    float aspect = cm.xPixels / cm.yPixels;
    camera_perspective = GLKMatrix4MakePerspective(_fov, aspect, 0.001f, 50.0f);
}

GLKMatrix4 rotation_teM_proj;
GLKMatrix4 rotation_teM_tan;


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
    
    [FluxTransformUtilities WGS84toECEFWithPose:usp];
    
    [FluxTransformUtilities tangentplaneRotation:&rotation_teM_proj fromPose:usp];

    // rotationMat = rotationMat_t;
    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(usp->rotationMatrix, zRay);
    
    //NSLog(@"Projection vector: [%f, %f, %f]", v.x, v.y, v.z);
    
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3((usp->rotationMatrix), planeNormalI);
    //intersection with plane
    GLKVector3 N = GLKVector3Normalize(planeNormalRotated);
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

    [FluxTransformUtilities WGS84toECEFWithPose:usp];
    
    [FluxTransformUtilities tangentplaneRotation:&rotation_teM_tan fromPose:usp];

    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(usp->rotationMatrix, zRay);
    
    //NSLog(@"Projection vector: [%f, %f, %f]", v.x, v.y, v.z);
    
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
    (*vp).origin = GLKVector3Add(positionTP, P0);
    (*vp).at = V;
    (*vp).up = GLKMatrix4MultiplyVector3(usp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    
    return 0;
}

// compute the tangent plane location and direction vector for an image
bool computeTangentPlaneParametersImage(sensorPose *sp, sensorPose *userPose, viewParameters *vp, LocationDataType ldt)
{
    bool retval = true;
    
    GLKVector3 zRay;
    GLKVector3 upRay;
	GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    
    if (ldt == location_data_from_homography)
    {
        zRay = GLKVector3Make(0.0, 0.0, 1.0);
        upRay = GLKVector3Make(0.0, -1.0, 0.0);
    }
    else
    {
        zRay = GLKVector3Make(0.0, 0.0, -1.0);
        upRay = GLKVector3Make(0.0, 1.0, 0.0);

        //assumption that the point of image acquisition and the user lie in the same plane.
        sp->position.z = userPose->position.z;
        
        if (sp->validECEFEstimate != 1)
        {
            [FluxTransformUtilities WGS84toECEFWithPose:sp];
        }
    }
    
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(sp->rotationMatrix, zRay);
    
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
    positionTP.x = sp->ecef.x -userPose->ecef.x;
    positionTP.y = sp->ecef.y -userPose->ecef.y;
    positionTP.z = sp->ecef.z -userPose->ecef.z;
    
    positionTP = GLKMatrix4MultiplyVector3(rotation_teM_tan, positionTP);
    
    P0 = positionTP;
    
    float _distanceToUser = GLKVector3Length(P0);
    
    if (_distanceToUser > MAX_IMAGE_RADIUS)
    {
        //NSLog(@"too far to render %f -> %f", distancetoPlane, distance);
        retval = false;
    }
    
    (*vp).origin = P0;
    (*vp).at = V;
    (*vp).up = GLKMatrix4MultiplyVector3(sp->rotationMatrix, upRay);
    
    return retval;
}

//distance - distance of plane
int computeProjectionParametersImage(sensorPose *sp, GLKVector3 *planeNormal, float distance, sensorPose *userPose, viewParameters *vp)
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
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3((userPose->rotationMatrix), planeNormalI);
    
    //intersection with plane
    GLKVector3 N = GLKVector3Normalize(planeNormalRotated);
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
    sp->position.z = userPose->position.z;
    
    
    if(sp->validECEFEstimate !=1)
    {
        [FluxTransformUtilities WGS84toECEFWithPose:sp];
    }
    
    positionTP.x = sp->ecef.x - userPose->ecef.x;
    positionTP.y = sp->ecef.y - userPose->ecef.y;
    positionTP.z = sp->ecef.z - userPose->ecef.z;
    
    positionTP = GLKMatrix4MultiplyVector3(rotation_teM_proj, positionTP);
    
    // Pin z-component to local plane (assumption is that unmatched images are at a relative altitude of zero)
    positionTP.z = 0.0;
    
    P0 = positionTP;
    V = GLKVector3Normalize(v);
    
    float vd = GLKVector3DotProduct(N,V);
    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
    float t = v0/vd;
    
    if(vd==0)
    {
        // NSLog(@"ImagePose: Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
        return 0;
    }
    if(t < 0)
    {
        
        // NSLog(@"ImagePose: Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
        return 0;
    }
    
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
-(int) computeProjectionParametersMatchedImageWithImagePose:(sensorPose *)sp userHomographyPose:(sensorPose *) uhpose planeNormal:(GLKVector3 *)pN Distance: (float) distance currentUserPose:(sensorPose *) uPose viewParamters:(viewParameters *)vp
{
    viewParameters viewP;
	GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    
    if(distance <0.0)
    {
        NSLog(@"distance is a scalar, setting to positive");
        distance =  -1.0 *distance;
    }
    
    
    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, 1.0);
    zRay = GLKVector3Normalize(zRay);
   
  
    GLKVector3 v = GLKMatrix4MultiplyVector3(sp->rotationMatrix, zRay);
    
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3((uPose->rotationMatrix), planeNormalI);
    
    //intersection with plane
    GLKVector3 N = planeNormalRotated;
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
   
    
    positionTP.x = sp->ecef.x - uPose->ecef.x;
    positionTP.y = sp->ecef.y - uPose->ecef.y;
    positionTP.z = sp->ecef.z - uPose->ecef.z;
    
    positionTP = GLKMatrix4MultiplyVector3(rotation_teM_proj, positionTP);
    P0 = positionTP;
    V = GLKVector3Normalize(v);
    //  V = v;
    
    float vd = GLKVector3DotProduct(N,V);
    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
    float t = v0/vd;
    
    if(vd==0)
    {
           NSLog(@"ImagePose: Optical axis is parallel to viewing plane. This should never happen, unless plane is being set through user pose.");
        return 0;
    }
    if(t < 0)
    {
        
         NSLog(@"ImagePose: Optical axis intersects viewing plane behind principal point. This should never happen, unless plane is being set through user pose.");
        return 0;
    }
    
    //    if(distancetoPlane > (distance + 3))
    float _distanceToUser = GLKVector3Length(P0);
    
    if(_distanceToUser > MAX_IMAGE_RADIUS)
    {
        
//        NSLog(@"too far to render %f -> %f", distancetoPlane, distance);
        return 0;
    }
    
    viewP.at = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
    viewP.up = GLKMatrix4MultiplyVector3(sp->rotationMatrix, GLKVector3Make(0.0, -1.0, 0.0));
    
    (*vp).origin =   P0;
    (*vp).at = viewP.at;
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
    
    NSLog(@"received notificationdxc65 y");
    
    
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
    
    
    self.snapshotViewController = [myStoryboard instantiateViewControllerWithIdentifier:@"snapshotViewController"];
    // then add the imageCaptureView as the subview of the parent view
    [self.view addSubview:self.snapshotViewController.view];
    // add the glkViewController as the child of self
    [self addChildViewController:self.snapshotViewController];
    [self.snapshotViewController didMoveToParentViewController:self];
    self.snapshotViewController.view.frame = self.view.bounds;
    [self.snapshotViewController.view setHidden:YES];
    
    camIsOn = NO;
    imageCaptured = NO;
    _displayListHasChanged = 0;
}



- (void)activateNewImageCaptureWithImage:(UIImage *)image andAnnotation:(NSString *)annotation andFlickrID:(NSString *)flickrID
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.imageCaptureViewController setHidden:NO];
    [self.imageCaptureViewController setHistoricalTransparentImage:image andDefaultAnnotation:annotation andFlickrID:flickrID];
    
    camIsOn = YES;

    // TS: need to call back into fluxDisplayManager to switch to image capture mode - could be a notification send (FluxImageCaptureDidPush)
    // really should be called from ImageCaptureViewController but no really obvious place to put it.
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidPush
                                                        object:self userInfo:nil];
}

- (void)activateSnapshotCapture{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.snapshotViewController setHidden:NO];
    [self.snapshotViewController updateSnapshotButton];
}


- (void)setSnapShotFlag{
    _takesnapshot =1;
}

- (void)setBackgroundSnapFlag{
    _takesnapshot = 2;
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
}

#pragma mark - Image Tapping


- (int) calcVertexAtPoint:(GLKVector3)point withModelViewProjectionMatrix:(GLKMatrix4)mvp withScreenViewport:(GLKVector4)vp andCalcVertex:(GLKVector3 *) vertex
{
    bool isinvertible;
    GLKMatrix4 invMVP = GLKMatrix4Invert(mvp, &isinvertible);
    if (isinvertible == false)
        return -1;
    GLKVector4 in = GLKVector4Make(point.x, point.y, point.z, 1.0);
    in.x = (in.x - vp.x) /vp.z;
    in.y = (in.y - vp.y) /vp.w;
    
    in.x = in.x *2.0 - 1.0;
    in.y = in.y *2.0 - 1.0;
    in.z = in.z *2.0 - 1.0;
    
    GLKVector4 out = GLKMatrix4MultiplyVector4(invMVP, in);
    if(out.w == 0.0) return -1;
    
    out.x /= out.w;
    out.y /= out.w;
    out.z /= out.w;
    
    vertex->x = out.x;
    vertex->y = out.y;
    vertex->z = out.z;
    
    return 0;
}

-(int) isImageTapped:(tapParameters)tp withVertex:(GLKVector3) vertex
{
    int valid = 0;
    GLKVector3 opticalAxis = GLKVector3Subtract(tp.at, tp.origin);
    GLKVector3 tapVector = GLKVector3Subtract(vertex, tp.origin);
    
    float dotproduct = GLKVector3DotProduct(opticalAxis, tapVector);
    float magnitude1 = GLKVector3Length(opticalAxis);
    float magnitude2 = GLKVector3Length(tapVector);
    
    float angle = acosf (dotproduct/(magnitude1 *magnitude2));
    if(angle <= tp.fov)
        valid =1;
    return valid;
}

-(int) isImageTappedAtVertex:(GLKVector3)vertex withMVP:(GLKMatrix4)tMVP
{
    int valid=0;
    GLKVector4 vertex4 = GLKVector4Make(vertex.x, vertex.y, vertex.z, 1.0);
    
    GLKVector4 tCoord = GLKMatrix4MultiplyVector4(tMVP, vertex4);
    
    float s = tCoord.x / tCoord.w;
    float t = tCoord.y / tCoord.w;

    if(s>0.0 && s<1.0 && t>0.25 && t<0.75 &&tCoord.w >0.0)
        valid = 1;
    else
        valid = 0;
    
    return valid;
}

-(int) calcTappedVertexV0:(GLKVector3)vertex0 V1:(GLKVector3) vertex1 result:(GLKVector3*) vertex
{
   
    GLKVector3 positionTP;
    positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    float distance = 15.0;
    
    GLKVector3 zRay = GLKVector3Subtract(vertex1, vertex0);
    
    GLKVector3 v = GLKVector3Normalize(zRay);
    
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3(planeRotationMatrix, planeNormalI);
    //intersection with plane
    GLKVector3 N = GLKVector3Normalize(planeNormalRotated);
    GLKVector3 P0 = vertex0;
    GLKVector3 V = GLKVector3Normalize(v);
        
    float vd = GLKVector3DotProduct(N,V);
    float v0 = -1.0 * (GLKVector3DotProduct(N,P0) + distance);
    float t = v0/vd;
        
    if(vd==0)
    {
        return -1;
    }
    if(t < 0)
    {
        return -1;
    }
    *vertex = GLKVector3Add(P0,GLKVector3Make(t*V.x , t*V.y ,t*V.z));
    return 0;
}
- (FluxScanImageObject*)imageTappedAtPointFunc
{
    FluxScanImageObject *touchedObject = nil;
    
    int valid =-1;
    GLKVector3 tapPoint;
    GLKVector3 vertex, vertex1, vertex0;
    GLKVector4 vp;
    
    //assuming that this is a retina device
    vp.x = 0.0;
    vp.y = 0.0;
    vp.z = _screenWidth  * 2.0;
    vp.w = _screenHeight * 2.0;
    
    tapPoint.x = _tapPoint.x;
    tapPoint.y = _tapPoint.y;
    tapPoint.z =0.0;
    valid = [self calcVertexAtPoint:tapPoint
      withModelViewProjectionMatrix:_modelViewProjectionMatrix
                 withScreenViewport:vp
                      andCalcVertex:&vertex0];
    
    tapPoint.z = 1.0;
    valid = [self calcVertexAtPoint:tapPoint
      withModelViewProjectionMatrix:_modelViewProjectionMatrix
                 withScreenViewport:vp
                      andCalcVertex:&vertex1];
    
    
    valid = [self calcTappedVertexV0:vertex0 V1:vertex1 result:&vertex];
    if(valid ==-1)
        return nil;
  
    int tapped = 0;
    //this is order dependant of course so any time the ordering of items in renderList will change this needs to be updated
    for (FluxTextureToImageMapElement *tel in [self.textureMap subarrayWithRange:NSMakeRange(0, [self.renderList count])])
    {
        int element = tel.textureIndex;
       // tapped = [self isImageTappedAtVertex:vertex withMVP:_tBiasMVP[element]];
        tapped = [self isImageTapped:_tapParams[element] withVertex:vertex];
        if (tapped == 1)
        {
            touchedObject = [self.fluxDisplayManager getRenderElementForKey:tel.localID].imageMetadata;
            break;
        }
    }
     _imagetapped = 0;
    return touchedObject;
}


- (void)imageTappedAtPoint:(CGPoint)point
{
    
    _tapPoint.x = point.x;
    _tapPoint.y = point.y;
    _imagetapped = 1;
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
    if([connection activeVideoStabilizationMode] == AVCaptureVideoStabilizationModeOff )
    {
        if([connection isVideoStabilizationSupported])
        {
            NSLog(@"Stablization supported, enabling");
            [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
            
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
        //_userPose.rotationMatrix = _userRotationRaw;
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
    [self.cameraManager.device lockForConfiguration:&error];
    [self.cameraManager.device setFocusPointOfInterest:[touch locationInView:self.view]];
}

- (void)setupAVCapture
{
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
    
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
    self.cameraManager = [FluxAVCameraSingleton sharedCamera];
    [self.cameraManager.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [self.cameraManager startAVCapture];
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
    [super viewDidLoad];
    
    _displayListHasChanged = 0;
    
    // Make a call here to set the maximum number of textures
    number_textures = [[FluxDeviceInfoSingleton sharedDeviceInfo] renderTextureCount];
    
    if (number_textures > (MAX_TEXTURES - 1))
    {
        // Need to keep a texture for the background
        NSLog(@"Requested number of textures exceeds maximum. Setting to default value of %d.", default_number_textures);
        number_textures = default_number_textures;
    }

    self.renderList = [[NSMutableArray alloc] initWithCapacity:number_textures];
    
    NSMutableArray *tempTextureList = [[NSMutableArray alloc] initWithCapacity:number_textures];
    for (int i = 0; i < number_textures; i++)
    {
        FluxTextureToImageMapElement *ime = [[FluxTextureToImageMapElement alloc] initWithSlotIndex:i];
        [tempTextureList addObject:ime];
    }
    self.textureMap = [NSArray arrayWithArray:tempTextureList];

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
    
    _renderingMatchedImage = 0;
    
    //set debug labels to hidden by default
    gpsX.hidden= YES;
    gpsY.hidden= YES;
    kX.hidden = YES;
    kY.hidden = YES;
    delta.hidden = YES;
    pedometerL.hidden = YES;
    
    frameGrabRequested = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateImageList:) name:FluxDisplayManagerDidUpdateDisplayList object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateImageTexture:) name:FluxDisplayManagerDidUpdateImageTexture object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCaptureDidPop:) name:FluxImageCaptureDidPop object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCaptureDidCapture:) name:FluxImageCaptureDidCaptureImage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(render) name:FluxOpenGLShouldRender object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadAlphaTexture) name:@"maskChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadBorderTexture) name:@"BorderChange" object:nil];
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
    [self.cameraManager.videoDataOutput setSampleBufferDelegate:nil queue:NULL];

    motionManager = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDisplayManagerDidUpdateDisplayList object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDisplayManagerDidUpdateImageTexture object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxImageCaptureDidPop object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxImageCaptureDidCaptureImage object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxOpenGLShouldRender object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"maskChange" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BorderChange" object:nil];
    
    [self tearDownGL];
    
    free(cameraParameters);
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [self.cameraManager stopAVCapture];
}

- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
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

- (void) updateImageMetadataForElementList:(NSMutableArray *)elementList andMaxIncidentThreshold:(double)maxIncidentThreshold
{
    NSMutableArray *removeList = [[NSMutableArray alloc]init];
    double absUserHeading;
    double relUserHeading;
    
    // first, get a copy of the userPose, just in case it changed under us.  May want to look into a lock for this...
    sensorPose localUserPose = _userPose;
    viewParameters localUserVp;

    // calculate angle between user's viewpoint and North
    computeTangentParametersUser(&localUserPose, &localUserVp);
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

    while (relUserHeading < 0.0)
        relUserHeading += 360.0;

    absUserHeading = relUserHeading;
    
//    NSString *logstr = [NSString stringWithFormat:@"OGLVC.updateImageMetadataForElementList: Local calc heading: %f, locMgr orHeading: %f", absUserHeading, self.fluxDisplayManager.locationManager.orientationHeading];
//    [self.fluxDisplayManager writeLog:logstr];

//    absUserHeading = self.fluxDisplayManager.locationManager.orientationHeading;
//    absUserHeading = self.fluxDisplayManager.locationManager.heading;

    
//    NSLog(@"Relative User Heading: %f, gps user heading: %f", relUserHeading, self.fluxDisplayManager.locationManager.heading);
    
    for (FluxImageRenderElement *ire in elementList)
    {
        viewParameters vp;
        bool cansee = false;
        
        [self updateImageMetadataForElement:ire];
        
        if (ire.imageMetadata.location_data_type == location_data_from_homography)
        {
            sensorPose imPose = ire.imageMetadata.imageHomographyPosePnP;
            cansee = computeTangentPlaneParametersImage(&imPose, &localUserPose, &vp, ire.imageMetadata.location_data_type);
            ire.imageMetadata.imageHomographyPosePnP = imPose;
        }
        else
        {
            cansee = computeTangentPlaneParametersImage(ire.imagePose, &localUserPose, &vp, ire.imageMetadata.location_data_type);
        }
        
        if (!cansee)
        {
            [removeList addObject:ire];
        }
        else
        {
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
            
            // calculate the angle between the vectors (user position -> North) and (user position -> image's intersection point on the cylindrical screen)
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

            // now calculate angle between camera LOS and perpendicular to cylinder at camera LOS intersection point
            x1 = vp.origin.x - xi;
            y1 = vp.origin.y - yi;
            x2 = -xi;
            y2 = -yi;
            
            dotx = x2 * x1;
            doty = y2 * y1;
            
            scalar = dotx + doty;
            magsq1 = x2 * x2 + y2 * y2;
            magsq2 = (x1 * x1) + (y1 * y1);
            
            costheta = (scalar) / sqrt(magsq1 * magsq2);
            theta = acos(costheta) * 180.0 / M_PI;

            if (theta > maxIncidentThreshold)
            {
//                NSLog(@"Removing id %@, incident angle %f > threshold, rh: %f, uh: %f", ire.localID, theta, ire.imageMetadata.relHeading, absUserHeading);
//                NSLog(@"cam origin:(%f, %f), cam at: (%f, %f), cam intersect: %f, %f)", vp.origin.x, vp.origin.y, vp.at.x, vp.at.y, xi, yi);
//                NSLog(@"1: (%f, %f), 2: (%f, %f)", x1, y1, x2, y2);
                [removeList addObject:ire];
            }
            
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

-(GLKMatrix4) computeImageCameraPerspectivewithDevicePlatform:(FluxDevicePlatform) platform andFov:(float *) camfov
{
    GLKMatrix4 icameraPerspective;
    FluxCameraModel *cam = [FluxDeviceInfoSingleton cameraModelForPlatform:platform];
    // this is the direct conversion:
    // use xPixels rather than yPixels because originally cameraParameters.yPixels = cameraParameters.xPixels = 1080
    // where FluxCameraModel.xPixels != FluxCameraModel.yPixels
    // float _fov = 2 * atan2(cam.pixelSize * cam.xPixels / 2.0, cam.focalLength); //radians
    
    // thinking this is more what it should be given the relative capture areas of the raw cam vs HD video
    float fov = 2.0 * atan2(cam.pixelSizeScaleToRaw * cam.xPixels /2.0, cam.focalLength   ); //radians
   // (*camfov) =atan2((1.414 * cam.xPixels) /2.0, cam.focalLength   );
    
    (*camfov) =atan2((cam.pixelSize * cam.xPixels) /2.0, cam.focalLength   );
   // float _fov = globalFOV;
    float aspect = 1.0; //square image
    icameraPerspective = GLKMatrix4MakePerspective(fov, aspect, 0.001f, 50.0f);
    return icameraPerspective;
}

-(void)updateImageMetaData
{
    viewParameters vpimage;
    GLKVector3 planeNormal;
    GLKMatrix4 tMVP;
    GLKMatrix4 icameraPerspective;
    float fov;
    float distance = _projectionDistance;
    FluxScanImageObject *scanimageobject;
    sensorPose imagehomographyPose;
    // null out the valid bits...
    for (int i = 0; i < MAX_TEXTURES; i++)
        _validMetaData[i] = 0;
    
    for (FluxTextureToImageMapElement *tel in [self.textureMap subarrayWithRange:NSMakeRange(0, [self.renderList count])])
    {
        int idx = tel.textureIndex;
        FluxImageRenderElement *ire = [self.fluxDisplayManager getRenderElementForKey:tel.localID];
        if (ire)
        {
            scanimageobject = ire.imageMetadata;
            imagehomographyPose = scanimageobject.imageHomographyPosePnP;
            sensorPose uhPose = scanimageobject.userHomographyPose;
            
            if(scanimageobject.location_data_type == location_data_from_homography)
            {
                _validMetaData[idx] = ([self computeProjectionParametersMatchedImageWithImagePose:&imagehomographyPose
                                                                              userHomographyPose:&uhPose
                                                                                     planeNormal:&planeNormal
                                                                                        Distance:distance
                                                                                 currentUserPose:&_userPose
                                                                                    viewParamters:&vpimage]);
                _renderingMatchedImage = 1;
            }
            else
            {
                _validMetaData[idx] = computeProjectionParametersImage(ire.imagePose, &planeNormal, distance, &_userPose, &vpimage);
            }
            
            GLKMatrix4 scaleMatrix = GLKMatrix4Identity;
            scaleMatrix = GLKMatrix4Scale(scaleMatrix, 0.5, 0.5, 1.0);
            
            tViewMatrix = GLKMatrix4MakeLookAt(vpimage.origin.x, vpimage.origin.y, vpimage.origin.z,
                                               vpimage.at.x, vpimage.at.y, vpimage.at.z,
                                               vpimage.up.x, vpimage.up.y, vpimage.up.z);
            
          // tViewMatrix = GLKMatrix4Multiply( tViewMatrix, scaleMatrix);
            icameraPerspective = [self computeImageCameraPerspectivewithDevicePlatform:scanimageobject.devicePlatform andFov:&fov];
            tMVP = GLKMatrix4Multiply(icameraPerspective,tViewMatrix);
            
            _tBiasMVP[idx] = GLKMatrix4Multiply(biasMatrix,tMVP);
            _tapParams[idx].origin = vpimage.origin;
            _tapParams[idx].at = vpimage.at;
            _tapParams[idx].fov = fov;
        }
        else {
            // no ire
            _validMetaData[idx] = 0;
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
    
    self.asyncTextureLoader = [[GLKTextureLoader alloc] initWithSharegroup:self.context.sharegroup];

    [self loadShaders];
    
    [self checkShaderLimitations];
    
    init();
    
    _projectionDistance = MAX_IMAGE_RADIUS;
    glEnable(GL_DEPTH_TEST);
    
    _takesnapshot =0;
    _imagetapped = 0;
    
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
    [self loadBorderTexture];
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
    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    int maskType = [[defaults objectForKey:@"Mask"] integerValue];
    int maskType = 2;
    _texture[6] = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i",maskType] ofType:@"png"] options:options error:&error];
    if (error) NSLog(@"Image texture error %@", error);
    
//    _texture[5] = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"] options:options error:&error];
//    if (error) NSLog(@"Image texture error %@", error);
    
    glActiveTexture(GL_TEXTURE6);
    glBindTexture(_texture[6].target, _texture[6].name);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
}
- (void) loadBorderTexture
{
    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderGrayscaleAsAlpha];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int borderType = [[defaults objectForKey:@"Border"] integerValue];
    
    _texture[5] = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"border%i",borderType] ofType:@"png"] options:options error:&error];
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
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
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
        CGFloat scale = eaglview.contentScaleFactor;
        widthInPoints = width / scale;
        heightInPoints = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);

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

- (void)loadTexture:(int)tIndex withImage:(UIImage *)image withTextureObject:(FluxTextureToImageMapElement *)tel
{
    [self deleteImageTextureIdx:tIndex];

    // Store copies of properties of the texture for verification before replacing texture
    FluxLocalID *localID = [tel.localID copy];
    FluxImageType imageTypeToLoad = tel.requestedImageType;
    
    // Load the new texture
//    NSLog(@"Loading texture of size (%f, %f) with scale %f", image.size.width, image.size.height, image.scale);
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *imgData = UIImageJPEGRepresentation(image, 1); // 1 is compression quality
        
        dispatch_sync(dispatch_get_main_queue(), ^{

            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            [self.asyncTextureLoader textureWithContentsOfData:imgData options:options queue:queue completionHandler:^(GLKTextureInfo *textureInfo, NSError *error) {
                
                if (error)
                {
                    NSLog(@"Error loading Image texture (error: %@)", error);
                }
                else if ((tel.storedImageType < imageTypeToLoad) && [tel.localID isEqualToString:localID])
                {
                    _texture[tIndex] = textureInfo;
                    tel.texturedLoaded = YES;
                    tel.storedImageType = imageTypeToLoad;
                }
                else
                {
                    NSLog(@"Texture slot changed since load requested. Doing nothing.");
                }
            }];
        });
    });
}

- (int)pickSlotToReplace:(NSMutableArray *)unusedSlots withRemaining:(NSMutableArray *)remainingLocalIDs
{
    int slotToUse = 0;
    
    if ([unusedSlots count] == 0)
    {
        slotToUse = -1;
    }
    else
    {
        if ([unusedSlots count] == [remainingLocalIDs count])
        {
            // We will use all of the slots anyways, so just pick one (last is optimal)
            slotToUse = [[unusedSlots lastObject] integerValue];
            [unusedSlots removeLastObject];
        }
        else
        {
            // Find the slot furthest away in terms of heading (most likely to disappear)
            double maxRelativeHeadingFound = -1.0;
            int indexToRemove = 0;
            
            for (int i=0; i<[unusedSlots count]; i++)
            {
                FluxLocalID *localID = ((FluxTextureToImageMapElement *)self.textureMap[[unusedSlots[i] integerValue]]).localID;
                
                if (!localID || [localID isEqualToString:@""])
                {
                    // localID was previously not set (slot has never been used), so just pick this one
                    slotToUse = [unusedSlots[i] integerValue];
                    indexToRemove = i;
                    break;
                }
                
                FluxImageRenderElement *ire = [self.fluxDisplayManager getRenderElementForKey:localID];
                if (fabs(ire.imageMetadata.relHeading) > maxRelativeHeadingFound)
                {
                    slotToUse = [unusedSlots[i] integerValue];
                    indexToRemove = i;
                }
            }
            
            // Remove from unusedSlots list
            [unusedSlots removeObjectAtIndex:indexToRemove];
        }
        
    }
    
    return slotToUse;
}

- (bool)replaceDataInTexture:(FluxTextureToImageMapElement *)tel forLocalID:(FluxLocalID *)localID withImageType:(FluxImageType)imageType
{
    bool success = YES;
    
    FluxImageRenderElement *ire = [self.fluxDisplayManager getRenderElementForKey:localID];
    
    // Check if we are replacing the stored texture
    // Need to check if storedImageType is none, since lowest_res is equivalent to none, and we request lowest_res in some cases
    if (![localID isEqualToString:tel.localID] || (imageType != tel.storedImageType) || (tel.storedImageType == none))
    {
        tel.texturedLoaded = NO;
        tel.storedImageType = none;
        
        // If we are replacing with a different localID or image size, then clean up reference counts for the old cached image
        // End access for existing texture element/image cache object
        [tel.imageCacheObject endContentAccess];
        tel.imageCacheObject = nil;
        
        // Populate with new image data
        FluxImageType rtype = none;
        
        // Fetch new image cache object to replace the old one
        FluxCacheImageObject *imageCacheObj = [self.fluxDisplayManager.fluxDataManager fetchImagesByLocalID:ire.localID withSize:imageType returnSize:&rtype];
        
        if (imageCacheObj.image != nil)
        {
            tel.texturedLoaded = NO;
            tel.requestedImageType = rtype;
            tel.imageCacheObject = imageCacheObj;
            tel.localID = ire.localID;
            
            // Load texture into slot
            [self loadTexture:tel.textureIndex withImage:imageCacheObj.image withTextureObject:tel];
        }
        else
        {
            success = NO;
        }
    }
    else
    {
        // Case where we already have stored exactly what we are looking for. Return NO since we didn't replace anything.
        success = NO;
    }
    
    return success;
}

- (void)updateTextures
{
    NSMutableArray *unusedTextureMapSlots = [[NSMutableArray alloc] init];
    NSMutableArray *renderedLocalIDs = [[NSMutableArray alloc] init];
    
    // List of localIDs in renderList to render
    for (FluxImageRenderElement *ire in self.renderList)
    {
        [renderedLocalIDs addObject:ire.localID];
    }

    // List of localIDs still looking for a slot
    NSMutableArray *remainingLocalIDs = [renderedLocalIDs mutableCopy];
    
    // Flag to ensure only one high-res image is loaded per cycle
    bool highResAddedThisCycle = NO;

    // Check which textureElements are already populated correctly
    for (int i=0; i<[self.textureMap count]; i++)
    {
        FluxTextureToImageMapElement *tel = self.textureMap[i];
        if ([renderedLocalIDs containsObject:tel.localID])
        {
            tel.used = YES;
            tel.renderOrder = [renderedLocalIDs indexOfObject:tel.localID];
            
            // If already loaded, set accordingly (happens when we toggle used off then on)
            if (tel.storedImageType == tel.requestedImageType)
            {
                tel.texturedLoaded = YES;
            }
            
            [remainingLocalIDs removeObject:tel.localID];
            
            // Pick a higher resolution texture to load (only select from textures already in the correct slot)
            FluxImageRenderElement *ire = [self.fluxDisplayManager getRenderElementForKey:tel.localID];
            if (!highResAddedThisCycle && (tel.requestedImageType < ire.imageRenderType))
            {
                if ([self replaceDataInTexture:tel forLocalID:ire.localID withImageType:ire.imageRenderType])
                {
                    highResAddedThisCycle = YES;
                }
            }
        }
        else
        {
            tel.used = NO;
            tel.texturedLoaded = NO;
            tel.renderOrder = NSUIntegerMax;
            [unusedTextureMapSlots addObject:@(i)];
        }
    }
    
    // Find slots for remaining elements to be rendered
    for (FluxLocalID *localID in remainingLocalIDs)
    {
        int slotToUse = [self pickSlotToReplace:unusedTextureMapSlots withRemaining:remainingLocalIDs];
        if (slotToUse >= 0)
        {
            FluxTextureToImageMapElement *tel = self.textureMap[slotToUse];

            tel.used = YES;
            tel.renderOrder = [renderedLocalIDs indexOfObject:tel.localID];

            // Load information into the new texture
            [self replaceDataInTexture:tel forLocalID:localID withImageType:lowest_res];
        }
    }
    
    // Sort textureMap based on desired render order (reverse the order here)
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"renderOrder" ascending:YES]];
    self.textureMap = [self.textureMap sortedArrayUsingDescriptors:sortDescriptors];
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
    
    //in case of moveing to background
    if (self.view) {
        [(GLKView*)self.view display];
    }
}

- (void)update
{
    if (_displayListHasChanged > 0)
    {
        [self fixRenderList];
    }
    
    CMQuaternion att = motionManager.attitude;
    
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
    GLKQuaternion quat = GLKQuaternionMake(att.x, att.y, att.z, att.w);
   _userPose.rotationMatrix =  GLKMatrix4MakeWithQuaternion(quat);
    _userRotationRaw = _userPose.rotationMatrix;
    //_userPose.rotationMatrix = att.rotationMatrix;
  GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    _userPose.rotationMatrix =  GLKMatrix4Multiply(matrixTP, _userPose.rotationMatrix);
    
   
        _userPose.position.x =self.fluxDisplayManager.locationManager.location.coordinate.latitude;
        _userPose.position.y =self.fluxDisplayManager.locationManager.location.coordinate.longitude;
        _userPose.position.z =self.fluxDisplayManager.locationManager.location.altitude;
  
    
    
    GLKVector3 planeNormal;
    float distance = _projectionDistance;
    viewParameters vpuser;
    
    setupRenderingPlane(planeNormal, _userPose.rotationMatrix, distance);
    
    planeRotationMatrix = _userPose.rotationMatrix;
    
    
    computeProjectionParametersUser(&_userPose, &planeNormal, distance, &vpuser);
    
    
    if(self.fluxDisplayManager.locationManager.kflocation.valid ==1)
    {
        
        _userPose.ecef.x =  self.fluxDisplayManager.locationManager.kflocation.x;
        _userPose.ecef.y =  self.fluxDisplayManager.locationManager.kflocation.y;
        _userPose.ecef.z =  self.fluxDisplayManager.locationManager.kflocation.z;
        
        //[self printDebugInfo];
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
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelViewMatrix);
    
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(camera_perspective, modelViewMatrix);
     _modelViewProjectionMatrixInOrder = GLKMatrix4Multiply(modelViewMatrix, camera_perspective);
    
    [self updateImageMetaData];
    
    //    GLKMatrix4 texrotate = GLKMatrix4MakeRotation(M_PI, 0.0, 1.0, 0.0);
    //    GLKMatrix4 textranslate = GLKMatrix4MakeTranslation(1.0f, 0.0f, 0.0f);
    
//    _imagePose[7].position.x =0.0;
//    _imagePose[7].position.y =0.0;
//    _imagePose[7].position.z =0.0;
    
    tViewMatrix = viewMatrix;
    
    GLKMatrix4 texrotate = GLKMatrix4MakeRotation(-M_PI_2, 0.0, 0.0, 1.0);
    tMVP = GLKMatrix4Multiply(camera_perspective,tViewMatrix);
    _tBiasMVP[6] = texrotate;
    _tBiasMVP[7] = GLKMatrix4Multiply(biasMatrix, tMVP);
    
    [self updateBuffers];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    FluxScanImageObject *sio;
    float sepia;
    
    if(_videotexture==NULL)
        return;
    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    

    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX7], 1, 0, _tBiasMVP[7].m);
    glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX6], 1, 0, _tBiasMVP[6].m);
    
    if(_videotexture != NULL)
    {
        glActiveTexture(GL_TEXTURE7);
        glBindTexture(CVOpenGLESTextureGetTarget(_videotexture), CVOpenGLESTextureGetName(_videotexture));
        glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER7], 7);
    }
  
    
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(_texture[5].target, _texture[5].name);
    glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER5], 5);

    glActiveTexture(GL_TEXTURE6);
    glBindTexture(_texture[6].target, _texture[6].name);
    glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER6], 6);
    
    // then spin through the images...
    NSEnumerator *revEnumerator = [[self.textureMap subarrayWithRange:NSMakeRange(0, [self.renderList count])] reverseObjectEnumerator];
    int c = 0;
    for (FluxTextureToImageMapElement *tel in revEnumerator)
    {
        int i = tel.textureIndex;

        if ((tel.used) && (tel.texturedLoaded) && (_texture[i] != nil) && (_validMetaData[i]==1))
        {
            sio = ((FluxImageRenderElement *)[self.fluxDisplayManager getRenderElementForKey:tel.localID]).imageMetadata;
            sepia = (sio.location_data_type == location_data_from_homography || sio.location_data_type == location_data_valid_ecef) ? 0.0 : 1.0;
            glUniform1f(uniforms[UNIFORM_SET_SEPIA0+c],sepia);
            glUniformMatrix4fv(uniforms[UNIFORM_TBIASMVP_MATRIX0 + c], 1, 0, _tBiasMVP[i].m);
            glUniform1i(uniforms[UNIFORM_RENDER_ENABLE0+c],1);
            glActiveTexture(GL_TEXTURE0 + c);
            glBindTexture(_texture[i].target, _texture[i].name);
            glUniform1i(uniforms[UNIFORM_MYTEXTURE_SAMPLER0 + c], c);
            c++;
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
    
    if(_takesnapshot ==1)
    {
        [self takeSnapshotAndPresentApproval];
        _takesnapshot =0;
    }
    if (_takesnapshot == 2) {
        UIImage*img = [self snapshot:self.view];
        NSDictionary *userInfoDict = @{@"snapshot" : img};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didCaptureBackgroundSnapshot"
                                                            object:self userInfo:userInfoDict];
        _takesnapshot =0;
    }
    if (_imagetapped == 1) {
        
        FluxScanImageObject* fsio = [self imageTappedAtPointFunc];
        if(fsio != nil)
        {
            FluxScanViewController *fsvc;
            fsvc = (FluxScanViewController*)self.parentViewController;
            UIImage*img = [self snapshot:self.view];
            [fsvc didTapImageFunc:fsio withBGImage:img];
            //NSDictionary *userInfoDict = @{@"tappedimage" : fsio};
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"FluxDidTapImage"
                //                                                object:self userInfo:nil];
        }
       
    }
    
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
    uniforms[UNIFORM_MYTEXTURE_SAMPLER6] = glGetUniformLocation(_program, "textureSampler[6]");
    uniforms[UNIFORM_MYTEXTURE_SAMPLER7] = glGetUniformLocation(_program, "textureSampler[7]");
    
    uniforms[UNIFORM_RENDER_ENABLE0] = glGetUniformLocation(_program, "renderEnable[0]");
    uniforms[UNIFORM_RENDER_ENABLE1] = glGetUniformLocation(_program, "renderEnable[1]");
    uniforms[UNIFORM_RENDER_ENABLE2] = glGetUniformLocation(_program, "renderEnable[2]");
    uniforms[UNIFORM_RENDER_ENABLE3] = glGetUniformLocation(_program, "renderEnable[3]");
    uniforms[UNIFORM_RENDER_ENABLE4] = glGetUniformLocation(_program, "renderEnable[4]");
    uniforms[UNIFORM_RENDER_ENABLE5] = glGetUniformLocation(_program, "renderEnable[5]");
    uniforms[UNIFORM_RENDER_ENABLE6] = glGetUniformLocation(_program, "renderEnable[6]");
    uniforms[UNIFORM_RENDER_ENABLE7] = glGetUniformLocation(_program, "renderEnable[7]");
    
    uniforms[UNIFORM_SET_SEPIA0] = glGetUniformLocation(_program, "sepiaEnable[0]");
    uniforms[UNIFORM_SET_SEPIA1] = glGetUniformLocation(_program, "sepiaEnable[1]");
    uniforms[UNIFORM_SET_SEPIA2] = glGetUniformLocation(_program, "sepiaEnable[2]");
    uniforms[UNIFORM_SET_SEPIA3] = glGetUniformLocation(_program, "sepiaEnable[3]");
    uniforms[UNIFORM_SET_SEPIA4] = glGetUniformLocation(_program, "sepiaEnable[4]");


    
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


- (IBAction)stepperChanged:(id)sender {
    
    }

@end
