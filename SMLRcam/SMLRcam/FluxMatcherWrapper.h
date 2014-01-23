//
//  FluxMatcherWrapper.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxCameraFrameElement.h"

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

const uint32_t fluxMagic = 0x58554C46;	// "FLUX" backwards so it reads correct if you cat the file
const uint16_t majorVersion = 1;
const uint16_t minorVersion = 0;

typedef struct {
	uint32_t magic;
    char buff[28];
	uint16_t major;
	uint16_t minor;
	uint16_t image_cols;
	uint16_t image_rows;
	uint32_t feature_count;
    uint32_t reserved[4];
} binHeader;

enum feature_matching_error_codes {
  feature_matching_success = 0,
  feature_matching_match_error = -1,
  feature_matching_homography_error = -2,
  feature_matching_extract_camera_features_error = -3
};
    
@interface FluxMatcherWrapper : NSObject

// Wrapper to set object_image for matching
-(void)setObjectImage:(UIImage*)objectImage;
-(void)setObjectFeatures:(NSData*)objectFeatures;

// Wrapper to extract keypoints and descriptors into buffers for later use during extraction from the input sceneImage
// Returns YES for success
-(bool)extractFeaturesForSceneImage:(UIImage *)sceneImage withCameraFrameElement:(FluxCameraFrameElement *)cfe;

// Wrapper to set scene_image for matching
// Uses keypoint and descriptor buffers calculated by extractFeaturesForSceneImage
// Returns YES For success
-(bool)setSceneImage:(UIImage *)sceneImage withKeypoints:(NSData *)keypoints_buffer withDescriptors:(NSMutableData *)descriptors_buffer
                 withDescriptorsRows:(int)rows withDescriptorsCols:(int)cols withDescriptorsSteps:(int)steps;

-(void)setSceneImageNoOrientationChange:(UIImage *)sceneImage;

// Wrapper for: FluxMatcher::match()
-(void)matchFeatures;

// Wrapper for: FluxMatcher::match() with transforms computed from H
// Returns 0 for success
-(int)matchAndCalculateTransformsWithRotation:(double[])R1 withTranslation:(double[])t1 withNormal:(double[])n1 withDebugImage:(bool)outputImage;

// Wrapper for: FluxMatcher::match() with matched box drawn
-(UIImage *)matchAndDrawFeatures;

@end
