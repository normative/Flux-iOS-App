//
//  FluxOpenGLViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-20.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "ImageViewerImageUtil.h"
#import "FluxImageAnnotationViewController.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxMotionManagerSingleton.h"
#import "FluxNetworkServices.h"
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <AVFoundation/AVFoundation.h>

#import "FluxAVCameraSingleton.h"

@class FluxOpenGLViewController;
@protocol OpenGLViewDelegate <NSObject>
@optional
//updated ImageList
- (void)OpenGLView:(FluxOpenGLViewController*)glView didUpdateImageList:(NSMutableDictionary*)imgList;
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

@interface FluxOpenGLViewController : GLKViewController <AVCaptureVideoDataOutputSampleBufferDelegate, NetworkServicesDelegate>{
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _tBiasMVP[8];
    
    
    int _validMetaData[8];
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLKTextureInfo* _texture[8];
    
    int _opengltexturesset;
    
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    
    sensorPose _userPose;
    sensorPose _imagePose[8];
    
    demoImage *demoimage;
    
    CGFloat _screenWidth;
    CGFloat _screenHeight;
    size_t _videoTextureWidth;
    size_t _videoTextureHeight;
    CVOpenGLESTextureRef _videotexture;
    NSString *_sessionPreset;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    
    FluxLocationServicesSingleton *locationManager;
    FluxMotionManagerSingleton *motionManager;
    FluxNetworkServices * networkServices;
    FluxAVCameraSingleton *cameraManager;
    
    __weak id <OpenGLViewDelegate> theDelegate;
    __weak IBOutlet UISlider *DistanceSlider;
    __weak IBOutlet UIStepper *PositionStepper;
}

@property (nonatomic, weak) id <OpenGLViewDelegate> theDelegate;
@property (strong, nonatomic) EAGLContext *context;
@property (weak) NSCache *fluxImageCache;
@property (nonatomic, weak) NSMutableDictionary *fluxMetadata;
@property (nonatomic, strong)NSMutableArray *nearbyList;
@property (nonatomic, strong)NSMutableDictionary *requestList;

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
- (void)didAcquireNewPicture:(NSNotification *)notification;
- (void)didUpdateLocation:(NSNotification *)notification;
- (void)didUpdateHeading:(NSNotification *)notification;
- (void)setupNetworkServices;

- (void)pauseOpenGLRender;
- (void)restartOpenGLRender;
- (BOOL)openGLRenderIsActive;

//AVCam Methods
- (void)setupAVCapture;

- (IBAction)onDistanceSliderValueChanged:(id)sender;
- (IBAction)onPositionStepperValueChanged:(id)sender;

@end