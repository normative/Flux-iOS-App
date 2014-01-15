//
//  FluxMatcherWrapper.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct {
    float ptx; //!< coordinates of the keypoints
    float pty; //!< coordinates of the keypoints
    float size; //!< diameter of the meaningful keypoint neighborhood
    float angle; //!< computed orientation of the keypoint (-1 if not applicable);
    //!< it's in [0,360) degrees and measured relative to
    //!< image coordinate system, ie in clockwise.
    float response; //!< the response by which the most strong keypoints have been selected. Can be used for the further sorting or subsampling
    int32_t octave; //!< octave (pyramid layer) from which the keypoint has been extracted
    int32_t class_id; //!< object class (if the keypoints need to be clustered by an object they belong to)
} FluxKeyPoint;

const uint32_t fluxMagic = 0x464C5558;	// "FLUX"
const uint16_t majorVersion = 1;
const uint16_t minorVersion = 0;

typedef struct {
	uint32_t magic;
	uint16_t major;
	uint16_t minor;
	uint16_t image_cols;
	uint16_t image_rows;
	uint32_t feature_count;
} binHeader;

enum feature_matching_error_codes {
  feature_matching_success = 0,
  feature_matching_match_error = -1,
  feature_matching_homography_error = -2
};
    
@interface FluxMatcherWrapper : NSObject

// Wrapper to set object_image for matching
-(void)setObjectImage:(UIImage*)objectImage;
-(void)setObjectFeatures:(NSData*)objectFeatures;

// Wrapper to set scene_image for matching
// Pass in a date if you want to re-use a set of features. If dates match, will re-use.
// Returns the date if a new set of features are extracted
-(NSDate *)setSceneImage:(UIImage *)sceneImage withPreviousExtractDate:(NSDate *)extractDate;
-(void)setSceneImageNoOrientationChange:(UIImage *)sceneImage;

// Wrapper for: FluxMatcher::match()
-(void)matchFeatures;

// Wrapper for: FluxMatcher::match() with transforms computed from H
// Returns 0 for success

-(int)matchAndCalculateTransformsWithRotationSoln1:(double[])R1 withTranslationSoln1:(double[])t1 withNormalSoln1:(double[])n1 withRotationSoln2:(double[])R2 withTranslationSoln2:(double[])t2 withNormalSoln2:(double[])n2 withRotationSoln3:(double[])R3 withTranslationSoln3:(double[])t3 withNormalSoln3:(double[])n3 withDebugImage:(bool)outputImage;
// Wrapper for: FluxMatcher::match() with matched box drawn
-(UIImage *)matchAndDrawFeatures;

@end
