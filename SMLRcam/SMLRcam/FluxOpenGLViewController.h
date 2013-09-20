//
//  FluxOpenGLViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-20.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "ImageViewerImageUtil.h"
//#import "FluxScanViewController.h"
#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxMotionManagerSingleton.h"
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <AVFoundation/AVFoundation.h>

#import "FluxRightDrawerViewController.h"

#import "FluxAVCameraSingleton.h"


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

@interface FluxOpenGLViewController : GLKViewController <AVCaptureVideoDataOutputSampleBufferDelegate, RightDrawerFilterDelegate>{
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _tBiasMVP[8];
    float _projectionDistance;
    
    int _validMetaData[8];
    float _rotation;
    GLKVector2 _testparams;
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
    FluxAVCameraSingleton *cameraManager;
    
    NSLock *_nearbyListLock;
    NSLock *_renderListLock;
    
    FluxDataFilter *dataFilter;
    
    __weak IBOutlet UISlider *DistanceSlider;
    __weak IBOutlet UIStepper *PositionStepper;
}

@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, weak) FluxDataManager *fluxDataManager;
@property (nonatomic, weak) NSMutableDictionary *fluxNearbyMetadata;
@property (nonatomic, strong)NSMutableArray *nearbyList;
@property (nonatomic, strong)NSMutableArray *renderedTextures;

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

//AVCam Methods
- (void)setupAVCapture;

- (IBAction)onDistanceSliderValueChanged:(id)sender;
- (IBAction)onPositionStepperValueChanged:(id)sender;


@end