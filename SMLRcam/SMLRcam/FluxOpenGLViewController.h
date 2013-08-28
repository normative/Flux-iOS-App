//
//  FluxOpenGLViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-20.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "ImageViewerImageUtil.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxMotionManagerSingleton.h"
#import "FluxNetworkServices.h"


@class FluxOpenGLViewController;
@protocol OpenGLViewDelegate <NSObject>
@optional
//images
- (void)OpenGLView:(FluxOpenGLViewController *)glView didUpdateImageList:(NSMutableDictionary*)aImageDict;
@end

typedef struct{
    GLKVector3 origin;
    GLKVector3 at;
    GLKVector3 up;
} viewParameters;

typedef struct {
    
    GLKMatrix4 rotationMatrix;
    GLKVector3 rotation_ypr;
    GLKVector3 position;
    GLKVector3 ecef;
} sensorPose;

@interface FluxOpenGLViewController : GLKViewController<NetworkServicesDelegate>{
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _tBiasMVP[8];
    
    
    
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLKTextureInfo* _texture[8];
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    
    sensorPose _userPose;
    sensorPose _imagePose[8];
    
    FluxLocationServicesSingleton *locationManager;
    FluxMotionManagerSingleton *motionManager;
    FluxNetworkServices * networkServices;

    __weak id <OpenGLViewDelegate> theDelegate;
}

@property (nonatomic, weak) id <OpenGLViewDelegate> theDelegate;
@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, strong)NSMutableDictionary*imageDict;


//- (GLuint) sub_texture:(demoImage*)img;
- (void)setupBuffers;
- (void)updateBuffers;
- (void)setupGL;
- (void)tearDownGL;
- (void) checkShaderLimitations;
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

- (void)setupLocationManager;
- (void)setupMotionManager;
- (void)startDeviceMotion;
- (void)stopDeviceMotion;
- (void)didUpdateLocation:(NSNotification *)notification;
- (void)didUpdateHeading:(NSNotification *)notification;
- (void)setupNetworkServices;
@end