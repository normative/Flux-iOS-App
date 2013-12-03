//
//  FluxMatcherWrapper.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxOpenGLCommon.h"
@interface FluxMatcherWrapper : NSObject
{
    double intrinsicsInverse[9];
    double homography[9];
   
}

@property (nonatomic) transform t;


// Wrapper to set object_image for matching
-(void)setObjectImage:(UIImage*)objectImage;

// Wrapper to set scene_image for matching
-(void)setSceneImage:(UIImage *)sceneImage;

// Wrapper for: FluxMatcher::match()
-(void)matchFeatures;

// Wrapper for: FluxMatcher::match() with matched box drawn
-(UIImage *)matchAndDrawFeatures;

@end
