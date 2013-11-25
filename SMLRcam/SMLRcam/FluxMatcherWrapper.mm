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
    // Check if object_img and scene_img are valid/set was performed higher up the stack
    std::vector<cv::DMatch> matches;
    std::vector<cv::KeyPoint> keypoints_object, keypoints_scene;
    cv::Mat descriptors_object, descriptors_scene;
    cv::Mat fundamental;
    
    int result = 0;
    result = self.wrappedMatcher->match(object_img, scene_img, matches,
                               keypoints_object, keypoints_scene,
                               descriptors_object, descriptors_scene,
                               fundamental);
}

// Object images are downloaded content to be matched
-(void)setObjectImage:(UIImage *)objectImage
{
    cv::Mat inputImage = [objectImage CVGrayscaleMat];
    
    object_img = inputImage;
}

// Scene images are the background camera feed to match against
-(void)setSceneImage:(UIImage *)sceneImage
{
    cv::Mat inputImage = [sceneImage CVGrayscaleMat];
    
    cv::transpose(inputImage, inputImage);
    cv::flip(inputImage, inputImage, 1);
    
    scene_img = inputImage;
}

-(UIImage *)matchAndDrawFeatures
{
    // Check if object_img and scene_img are valid/set was performed higher up the stack
    std::vector<cv::DMatch> matches;
    std::vector<cv::KeyPoint> keypoints_object, keypoints_scene;
    cv::Mat descriptors_object, descriptors_scene;
    cv::Mat fundamental;
    cv::Mat dst;
    
    int result = 0;
    result = self.wrappedMatcher->match(object_img, scene_img, matches,
                               keypoints_object, keypoints_scene,
                               descriptors_object, descriptors_scene,
                               fundamental);
    
    if (result == 0)
    {
        // Calculate homography using matches
        std::vector<cv::Point2f> obj;
        std::vector<cv::Point2f> scene;
        
        for( size_t i = 0; i < matches.size(); i++ )
        {
            //-- Get the keypoints from the good matches
            obj.push_back( keypoints_object[ matches[i].queryIdx ].pt );
            scene.push_back( keypoints_scene[ matches[i].trainIdx ].pt );
        }
        
        cv::Mat H = cv::findHomography( obj, scene, CV_LMEDS );
        
        // Draw box around video image in destination image
        scene_img.copyTo(dst);
        
        //-- Get the corners from the object image ( the object to be "detected" )
        std::vector<cv::Point2f> obj_corners(4);
        obj_corners[0] = cvPoint(0,0);
        obj_corners[1] = cvPoint( object_img.cols, 0 );
        obj_corners[2] = cvPoint( object_img.cols, object_img.rows );
        obj_corners[3] = cvPoint( 0, object_img.rows );
        std::vector<cv::Point2f> scene_corners(4);
        
        cv::perspectiveTransform( obj_corners, scene_corners, H );
        
        //-- Draw lines between the corners (the mapped object in the scene - image_2 )
        line( dst, scene_corners[0], scene_corners[1], cv::Scalar( 0, 255, 0), 4 );
        line( dst, scene_corners[1], scene_corners[2], cv::Scalar( 0, 255, 0), 4 );
        line( dst, scene_corners[2], scene_corners[3], cv::Scalar( 0, 255, 0), 4 );
        line( dst, scene_corners[3], scene_corners[0], cv::Scalar( 0, 255, 0), 4 );
    }
    else
    {
        dst = object_img;
    }
    
    return [UIImage imageWithCVMat:dst];
}

- (void)dealloc
{
    delete _wrappedMatcher;
}

@end
