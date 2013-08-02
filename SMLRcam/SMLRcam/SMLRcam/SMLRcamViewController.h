//
//  SMLRcamViewController.h
//  SMLRcam
//
//  Created by Denis Delorme on 7/4/13.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>


@interface SMLRcamViewController : UIViewController{
    
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;

    __weak IBOutlet UIButton *CameraButton;
}



@end
