//
//  FluxMatcherWrapper.mm
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMatcherWrapper.h"
#import "FluxMatcher.h"
#import "UIImage+OpenCV.h"

@interface FluxMatcherWrapper ()
{
    // Convert to grayscale before populating for performance improvement
    cv::Mat object_img;
    cv::Mat scene_img;
}

//C++ class from FluxMatcher.cpp
@property (nonatomic, assign) FluxMatcher *wrappedMatcher;

@end

@implementation FluxMatcherWrapper

@synthesize wrappedMatcher = _wrappedMatcher;

- (id)init
{
    self = [super init];
    if (self)
    {
        _wrappedMatcher = new FluxMatcher();
    }
    return self;
}

-(void)matchFeatures
{
    // TODO: check if object_img and scene_img are valid/set
    
    std::vector<cv::DMatch> matches;
    std::vector<cv::KeyPoint> keypoints_object, keypoints_scene;
    cv::Mat descriptors_object, descriptors_scene;
    cv::Mat fundamental;
    
    self.wrappedMatcher->match(object_img, scene_img, matches,
                               keypoints_object, keypoints_scene,
                               descriptors_object, descriptors_scene,
                               fundamental);
}

// Object images are downloaded content to be matched
-(void)setObjectImage:(UIImage *)objectImage
{
//    cv::Mat inputImage = [objectImage CVGrayscaleMat];
//    
//    object_img = inputImage;
    
    cv::Mat inputImage = [objectImage CVMat];
    cv::Mat outputImage;
    cv::cvtColor(inputImage, outputImage, CV_RGB2GRAY);
    object_img = outputImage;

}

// Scene images are the background camera feed to match against
-(void)setSceneImage:(UIImage *)sceneImage
{
//    cv::Mat inputImage = [sceneImage CVGrayscaleMat];
//    
//    scene_img = inputImage;
    
    cv::Mat inputImage = [sceneImage CVMat];
    cv::Mat outputImage;
    cv::cvtColor(inputImage, outputImage, CV_RGB2GRAY);
    scene_img = outputImage;
}

- (void)dealloc
{
    delete _wrappedMatcher;
}

@end
