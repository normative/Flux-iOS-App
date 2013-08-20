//
//  FluxOpenGLViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-20.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "ImageViewerImageUtil.h"
@interface FluxOpenGLViewController : GLKViewController{
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _tBiasMVP;
    GLKMatrix4 _tBiasMVP1 ;
    GLKMatrix4 _tBiasMVP2;
    
    
    
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
- (GLuint) init_texture: (demoImage*)img;
//- (GLuint) sub_texture:(demoImage*)img;

- (void)setupGL;
- (void)tearDownGL;
- (void) checkShaderLimitations;
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end