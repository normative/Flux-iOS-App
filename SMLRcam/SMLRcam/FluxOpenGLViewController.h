//
//  FluxOpenGLViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-20.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "ImageViewerImageUtil.h"
#import "FluxImageCaptureViewController.h"
#import "FluxDataManager.h"
#import "FluxDisplayManager.h"
#import "FluxMotionManagerSingleton.h"
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <AVFoundation/AVFoundation.h>
#import "FluxKalmanFilter.h"
#import "FluxAVCameraSingleton.h"
#import "FluxOpenGLCommon.h"
#import "FluxTextureToImageMapElement.h"
#import "FluxImageRenderElement.h"

//
//typedef struct{
//    GLKVector3 origin;
//    GLKVector3 at;
//    GLKVector3 up;
//} viewParameters;
//
//typedef struct {
//    
//    GLKMatrix4 rotationMatrix;
//    GLKVector3 rotation_ypr;
//    GLKVector3 position;
//    GLKVector3 ecef;
//} sensorPose;

@interface FluxOpenGLViewController : GLKViewController <AVCaptureVideoDataOutputSampleBufferDelegate>{
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
    
//    int _opengltexturesset;
    
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    
    sensorPose _userPose;
//    sensorPose _imagePose[8];
    
    demoImage *demoimage;
    
    CGFloat _screenWidth;
    CGFloat _screenHeight;
    size_t _videoTextureWidth;
    size_t _videoTextureHeight;
    CVOpenGLESTextureRef _videotexture;
    NSString *_sessionPreset;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    FluxMotionManagerSingleton *motionManager;
    FluxAVCameraSingleton *cameraManager;
    
    
    FluxKalmanFilter *kfilter;
    NSTimer *kfilterTimer;
    bool kfStarted;
    bool kfValidData;
    
    
    double kfDt;
    double kfMeasureX;
    double kfMeasureY;
    double kfMeasureZ;
    double kfNoiseX;
    double kfNoiseY;
    double kfXDisp;
    double kfYDisp;
    GLKMatrix4 kfrotation_teM;
    GLKMatrix4 kfInverseRotation_teM;
    sensorPose _kfInit;
    sensorPose _kfMeasure;
    sensorPose _kfPose;
    
//    NSLock *_nearbyListLock;
//    NSLock *_renderListLock;
    
    BOOL camIsOn;
    BOOL imageCaptured;
    
    int _displayListHasChanged;
    
    
    int stepcount;
    __weak IBOutlet UILabel *pedoLabel;
    //__weak IBOutlet UILabel *pedometer;
    
}

@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, weak) FluxDisplayManager *fluxDisplayManager;
//	@property (nonatomic, strong) NSMutableDictionary *fluxNearbyMetadata;
//@property (nonatomic, strong)NSMutableArray *nearbyList;
//@property (nonatomic, strong)NSMutableArray *renderedTextures;
@property (nonatomic, strong)FluxImageCaptureViewController*imageCaptureViewController;

@property (nonatomic, strong)NSMutableArray *renderList;
@property (nonatomic, strong)NSMutableArray *textureMap;



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

- (void)setupMotionManager;
- (void)startDeviceMotion;
- (void)stopDeviceMotion;

//AVCam Methods
- (void)setupAVCapture;
//image capture methods
- (void)showImageCapture;
- (UIImage*)snapshot:(UIView*)eaglview;
-(UIImage*)takeScreenCap;

- (void)didUpdateImageList:(NSNotification *)notification;
//- (void)updateImageTexture:(NSNotification *)notification;

- (void)render;
-(void) updateImageMetadataForElement:(FluxImageRenderElement*)element;

//image tap
- (FluxScanImageObject*)imageTappedAtPoint:(CGPoint)point;


@end