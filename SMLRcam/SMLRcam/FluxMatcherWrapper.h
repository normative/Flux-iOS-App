//
//  FluxMatcherWrapper.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface FluxMatcherWrapper : NSObject

// Wrapper to set object_image for matching
-(void)setObjectImage:(UIImage*)objectImage;

// Wrapper to set scene_image for matching
-(void)setSceneImage:(UIImage *)sceneImage;
-(void)setSceneImageNoOrientationChange:(UIImage *)sceneImage;

// Wrapper for: FluxMatcher::match()
-(void)matchFeatures;

// Wrapper for: FluxMatcher::match() with transforms computed from H
// Returns 0 for success
-(int)matchAndCalculateTransformsWithRotation:(double[])R withTranslation:(double[])t withDebugImage:(bool)outputImage;

// Wrapper for: FluxMatcher::match() with matched box drawn
-(UIImage *)matchAndDrawFeatures;

@end
