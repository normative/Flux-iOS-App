//
//  FluxMatcherWrapper.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

enum feature_matching_error_codes {
  feature_matching_success = 0,
  feature_matching_match_error = -1,
  feature_matching_homography_error = -2
};
    
@interface FluxMatcherWrapper : NSObject

// Wrapper to set object_image for matching
-(void)setObjectImage:(UIImage*)objectImage;
-(void)setObjectFeatures:(NSString*)objectFeatures;

// Wrapper to set scene_image for matching
-(void)setSceneImage:(UIImage *)sceneImage;
-(void)setSceneImageNoOrientationChange:(UIImage *)sceneImage;

// Wrapper for: FluxMatcher::match()
-(void)matchFeatures;

// Wrapper for: FluxMatcher::match() with transforms computed from H
// Returns 0 for success

-(int)matchAndCalculateTransformsWithRotationSoln1:(double[])R1 withTranslationSoln1:(double[])t1 withNormalSoln1:(double[])n1 withRotationSoln2:(double[])R2 withTranslationSoln2:(double[])t2 withNormalSoln2:(double[])n2 withDebugImage:(bool)outputImage;
// Wrapper for: FluxMatcher::match() with matched box drawn
-(UIImage *)matchAndDrawFeatures;

@end
