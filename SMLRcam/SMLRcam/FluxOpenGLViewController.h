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
#import "FluxSnapshotCaptureViewController.h"
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
#import "FluxCameraFrameElement.h"
#import "FluxLocationServicesSingleton.h"

#define MAX_TEXTURES 8


@interface FluxOpenGLViewController : GLKViewController <AVCaptureVideoDataOutputSampleBufferDelegate>{
    GLuint _program;
    GLKMatrix4 _modelViewProjectionMatrixInOrder;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _tBiasMVP[MAX_TEXTURES];
    tapParameters _tapParams[MAX_TEXTURES];
    float _projectionDistance;
    int number_textures;
    
    int _validMetaData[MAX_TEXTURES];
    float _rotation;
    GLKVector2 _testparams;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLKTextureInfo* _texture[MAX_TEXTURES];
    
//    int _opengltexturesset;
    
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    GLKMatrix4 _userRotationRaw;
    sensorPose _userPose;
//    sensorPose _imagePose[8];
    
    demoImage *demoimage;
    
    int _takesnapshot;
    int  _imagetapped;
    CGFloat _screenWidth;
    CGFloat _screenHeight;
    size_t _videoTextureWidth;
    size_t _videoTextureHeight;
    CVOpenGLESTextureRef _videotexture;
    NSString *_sessionPreset;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    FluxMotionManagerSingleton *motionManager;
    
    FluxCameraFrameElement *frameGrabRequest;
    bool frameGrabRequested;
    int _renderingMatchedImage;
    
    CGPoint _tapPoint;
    fluxCameraParameters *cameraParameters;
    
    BOOL camIsOn;
    BOOL imageCaptured;
    
    int _displayListHasChanged;
    
    __weak IBOutlet UILabel *pedometerL;
    __weak IBOutlet UILabel *gpsX;
    
    __weak IBOutlet UILabel *gpsY;
    __weak IBOutlet UILabel *kX;
    
    __weak IBOutlet UILabel *kY;
    
    __weak IBOutlet UILabel *delta;
   //    __weak IBOutlet UILabel *pedoLabel;
   
}

@property (strong) GLKTextureLoader *asyncTextureLoader;
@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, weak) FluxDisplayManager *fluxDisplayManager;

@property (nonatomic, strong) FluxAVCameraSingleton *cameraManager;
@property (nonatomic, strong) FluxImageCaptureViewController *imageCaptureViewController;
@property (nonatomic, strong) FluxSnapshotCaptureViewController *snapshotViewController;

@property (nonatomic, strong) NSMutableArray *renderList;
@property (nonatomic, strong) NSArray *textureMap;

//- (IBAction)stepperChanged:(id)sender;

//- (GLuint) sub_texture:(demoImage*)img;
- (void)setupBuffers;
- (void)updateBuffers;
- (void)setupGL;
- (void)tearDownGL;
- (void)checkShaderLimitations;
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
- (void)activateNewImageCaptureWithImage:(UIImage *)image andAnnotation:(NSString *)annotation andFlickrID:(NSString *)flickrID;
- (void)activateSnapshotCapture;
- (void)setSnapShotFlag;
- (void)setBackgroundSnapFlag;

- (UIImage*)snapshot:(UIView*)eaglview;
- (UIImage*)takeScreenCap;

- (void)didUpdateImageList:(NSNotification *)notification;
//- (void)updateImageTexture:(NSNotification *)notification;

- (void)render;
//- (void)updateImageMetadataForElement:(FluxImageRenderElement*)element;
- (void)updateImageMetadataForElementList:(NSMutableArray *)elementList andMaxIncidentThreshold:(double)maxIncidentThreshold;

//image tap
- (void)imageTappedAtPoint:(CGPoint)point;

- (void) requestCameraFrame:(FluxCameraFrameElement *)frameRequest;

@end