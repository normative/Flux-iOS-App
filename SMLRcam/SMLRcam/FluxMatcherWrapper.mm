//
//  FluxMatcherWrapper.mm
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMatcherWrapper.h"
#import "FluxMatcher.h"
#import "FluxOpenGLCommon.h"
#import "UIImage+OpenCV.h"
#import <Accelerate/Accelerate.h>
#include <iostream>

typedef struct{
    double theta1;
    double theta2;
    double theta3;
} euler_angles;

const double minLengthHomographyDiagonal = 50.0;
const double maxRatioSideLength = 2.0;

const long int auto_threshold_min = 100;
const long int auto_threshold_max = 10000;
const int auto_threshold_inc = 10;

uint32_t const  fluxMagic = 0x58554C46;	// "FLUX" backwards so it reads correct if you cat the file
uint16_t const  majorVersion = 1;
uint16_t const  minorVersion = 0;

@interface FluxMatcherWrapper ()
{
    // Convert to grayscale before populating for performance improvement
    cv::Mat object_img;
    cv::Mat scene_img;
    std::vector<cv::KeyPoint> keypoints_object;
    std::vector<cv::KeyPoint> keypoints_scene;
    cv::Mat descriptors_object;
    cv::Mat descriptors_scene;
    int object_img_rows;
    int object_img_cols;
    
    NSDate *cameraFrameFeatureExtractDate;
    
    double intrinsicsInverse[9];
    transformRtn result1;
    transformRtn result2;
    
    long ipiv[9];
    double work[9];
    double ci[9];
    double ciinverse[9];
}

//C++ class from FluxMatcher.cpp
@property (nonatomic, assign) FluxMatcher *wrappedMatcher;
@property (nonatomic) transformRtn t_from_H1;
@property (nonatomic) transformRtn t_from_H2;

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

- (void)matchFeatures
{
    // Check if object_img and scene_img are valid/set was performed higher up the stack
    std::vector<cv::DMatch> matches;
    cv::Mat fundamental;
    
    int result = 0;
    result = self.wrappedMatcher->match(matches,
                                        keypoints_object, keypoints_scene,
                                        descriptors_object, descriptors_scene,
                                        fundamental);
}

// Object images are downloaded content to be matched
- (void)setObjectImage:(UIImage *)objectImage
{
    if (!objectImage)
    {
        object_img = cv::Mat();
    }
    else
    {
        cv::Mat inputImage = [objectImage CVGrayscaleMat];
        
        object_img = inputImage;
    }
}

// Object images are downloaded content to be matched and this routine supplies raw features
- (void)setObjectFeaturesFromString:(NSString *)objectFeatures
{
    cv::FileStorage fs([objectFeatures UTF8String], cv::FileStorage::READ + cv::FileStorage::MEMORY);

    cv::FileNode kptFileNode = fs["Keypoints"];
    cv::read(kptFileNode, keypoints_object);
    
    fs["Descriptors"] >> descriptors_object;
    fs["img_cols"] >> object_img_cols;
    fs["img_rows"] >> object_img_rows;
    
//    std::cout << keypoints_object.size() << " keypoints and " << descriptors_object.rows << " descriptors read from file." << std::endl;
}

// Object images are downloaded content to be matched and this routine supplies raw features
- (void)setObjectFeatures:(NSData *)objectFeatures
{
	// open file and pull out header...
    Byte *fp = (Byte *)[objectFeatures bytes];

    binHeader *header = (binHeader *)fp;
    fp += sizeof(binHeader);
    
    // parse out and validate the header
    if ((header->magic != fluxMagic) || (header->major != 1))
    {
    	// problem
        NSLog(@"Feature header Magic number wrong (%x) or major wrong (%i).", header->magic, header->major);
        keypoints_object.resize(0);
    	return;
    }
 
    object_img_cols = header->image_cols;
    object_img_rows = header->image_rows;

    int expectedSize = sizeof(binHeader) + header->feature_count * (sizeof(FluxKeyPoint) + 64);
    
    if (objectFeatures.length < expectedSize)
    {
        NSLog(@"Invalid feature block size.  Expecting %i, have %i.", expectedSize, objectFeatures.length);
        keypoints_object.resize(0);
        return;
    }
    
    keypoints_object.resize(header->feature_count);
    
    int kpsize = keypoints_object.size();
    
    // read the keypoints...
    FluxKeyPoint *fkp;
    for (int i = 0; i < header->feature_count; i++)
    {
        fkp = (FluxKeyPoint *)fp;
        fp += sizeof(FluxKeyPoint);
        
        keypoints_object[i] = cv::KeyPoint(fkp->ptx, fkp->pty, fkp->size, fkp->angle, fkp->response, fkp->octave, fkp->class_id);
    }
    
    descriptors_object = cv::Mat(header->feature_count, 64, CV_8U);

    for (int r = 0; r < header->feature_count; r++)
    {
        Byte *buff = fp;
        fp += 64;
        
       	char *dc = descriptors_object.ptr<char>(r);
        
    	for (int c = 0; c < 64; c++)
    	{
    		dc[c] = buff[c];
    	}
    }
    
//    int descsize = descriptors_object.rows;
    
//    NSLog(@"%i keypoints and %i descriptors read from file.", kpsize, descsize);
    
    kpsize = 0;
}

// Scene images are the background camera feed to match against
// Extracts features from scene image into buffers for later use
- (bool)extractFeaturesForSceneImage:(UIImage *)sceneImage withCameraFrameElement:(FluxCameraFrameElement *)cfe
{
    bool success = YES;
    
    // Prepare the image and store it in the engine
    cv::Mat inputImage = [sceneImage CVGrayscaleMat];
    
    cv::transpose(inputImage, inputImage);
    cv::flip(inputImage, inputImage, 1);
    
    cv::Mat scene_extract_img = inputImage;
    
    std::vector<cv::KeyPoint> keypoints;
    cv::Mat descriptors;

    // Now extract and store the keypoints and descriptors using auto mode
    // Intentionally using a wide range to prevent retries with parameter selection
    int result = self.wrappedMatcher->extractFeaturesWithAutoThreshold(scene_extract_img, keypoints, descriptors,
                                                                       auto_threshold_min, auto_threshold_max,
                                                                       auto_threshold_inc);

    if (result < 0)
    {
        NSLog(@"Extracting features from current camera frame failed.");
        success = NO;
    }
    else
    {
        // Convert keypoints (std::vector<cv::KeyPoint>) to NSData buffer
        cfe.cameraFeatureKeypoints = [[NSData alloc] initWithBytes:&keypoints[0] length:keypoints.size()*sizeof(cv::KeyPoint)];
        
        // Convert descriptors (cv::Mat) to NSMutableData buffer
        if (!descriptors.isContinuous())
        {
            NSLog(@"Camera matrix not continuous!");
        }
        
        cfe.cameraFeatureDescriptors = [[NSMutableData alloc] initWithBytes:descriptors.data length:descriptors.rows * descriptors.step];
        
        cfe.cameraFeatureDescriptorsRows = descriptors.rows;
        cfe.cameraFeatureDescriptorsCols = descriptors.cols;
        cfe.cameraFeatureDescriptorsSteps = descriptors.step;
        
        // Store extracted image (from UIImage to cv::Mat) in NSMutableData buffer
        cfe.cameraFrameMatchImage = [[NSMutableData alloc] initWithBytes:scene_extract_img.data length:scene_extract_img.rows * scene_extract_img.step];
        
        cfe.cameraFrameMatchImageRows = scene_extract_img.rows;
        cfe.cameraFrameMatchImageCols = scene_extract_img.cols;
        cfe.cameraFrameMatchImageSteps = scene_extract_img.step;
    }
    
    return success;
}

// Scene images are the background camera feed to match against
// Uses previously calculated buffers and sets them to data structures used by feature matching
- (bool)setSceneImage:(NSMutableData *)image_buffer
        withImageRows:(int)image_rows withImageCols:(int)image_cols withImageSteps:(int)image_steps
        withKeypoints:(NSData *)keypoints_buffer
      withDescriptors:(NSMutableData *)descriptors_buffer
  withDescriptorsRows:(int)descriptors_rows withDescriptorsCols:(int)descriptors_cols withDescriptorsSteps:(int)descriptors_steps
{
    bool success = YES;

    // Read image into cv::Mat from NSMutableData buffer
    scene_img = cv::Mat(image_rows, image_cols, CV_8U, [image_buffer mutableBytes], image_steps);

    if ((scene_img.rows != image_rows) || (scene_img.cols != image_cols))
    {
        NSLog(@"Array dimensions do not match in image for extracted camera frame when re-reading buffer.");
        success = NO;
        return success;
    }

    // Read keypoints into std::vector<cv::KeyPoint> from NSData buffer
    keypoints_scene =  std::vector<cv::KeyPoint>((cv::KeyPoint*)[keypoints_buffer bytes], (cv::KeyPoint*)((cv::KeyPoint*)[keypoints_buffer bytes]+([keypoints_buffer length]/sizeof(cv::KeyPoint))));

    // Read descriptors into cv::Mat from NSMutableData buffer
    descriptors_scene = cv::Mat(descriptors_rows, descriptors_cols, CV_8U, [descriptors_buffer mutableBytes], descriptors_steps);
    
    if ((descriptors_scene.rows != descriptors_rows) || (descriptors_scene.cols != descriptors_cols))
    {
        NSLog(@"Array dimensions do not match in descriptors for extracted camera frame when re-reading buffer.");
        success = NO;
        return success;
    }
    
    return success;
}

- (void)setSceneImageNoOrientationChange:(UIImage *)sceneImage
{
    cv::Mat inputImage = [sceneImage CVGrayscaleMat];
    
    scene_img = inputImage;
}



- (int)matchAndCalculateTransformsWithRotation:(double[])R1 withTranslation:(double[])t1 withNormal:(double[])n1
                        withProjectionDistance:(float)projectionDistance
                                withDebugImage:(bool)outputImage withImageID:(FluxImageID)imageID
{
    // Check if object_img and scene_img are valid/set was performed higher up the stack
    std::vector<cv::DMatch> matches;
    cv::Mat fundamental;
    cv::Mat dst;

    int result = 0;
    
    result = self.wrappedMatcher->match(matches,
                                        keypoints_object, keypoints_scene,
                                        descriptors_object, descriptors_scene,
                                        fundamental);

    if (result == feature_matching_success)
    {
        // Calculate homography using matches
        std::vector<cv::Point2f> obj;
        std::vector<cv::Point2f> scene;
        
        cv::Mat R_matchcam_origin;
        
        double scale_factor = scene_img.rows / object_img_rows;
        
        for( size_t i = 0; i < matches.size(); i++ )
        {
            //-- Get the keypoints from the good matches
            obj.push_back( keypoints_object[ matches[i].queryIdx ].pt * scale_factor );
            scene.push_back( keypoints_scene[ matches[i].trainIdx ].pt );
        }
        
        cv::Mat H = cv::findHomography( obj, scene, CV_LMEDS );
        
        bool validHomographyFound = NO;
        
        // Check if homography calculated represents a valid match
        if (![self isHomographyValid:H withRows:object_img_rows withCols:object_img_cols])
        {
            result = feature_matching_homography_error;
            
        }
        else
        {
            validHomographyFound = YES;

            // Use SolvePnP method for calculating R and t
            cv::Mat t_matchcam_origin;
            
            //-- Get the corners from the object image ( the object to be "detected" )
            std::vector<cv::Point2f> obj_corners(4);
            obj_corners[0] = cvPoint(0,0);
            obj_corners[1] = cvPoint( object_img_cols * scale_factor, 0 );
            obj_corners[2] = cvPoint( object_img_cols * scale_factor, object_img_rows * scale_factor );
            obj_corners[3] = cvPoint( 0, object_img_rows * scale_factor );
            std::vector<cv::Point2f> scene_corners(4);
            
            cv::perspectiveTransform( obj_corners, scene_corners, H );
            
            // Call method for calculating R and t
            [self calcPnPWithSceneCorners:scene_corners withObjectCorners:obj_corners
                             withRotation:R_matchcam_origin withTranslation:t_matchcam_origin
                   withProjectionDistance:projectionDistance];
            
            std::cout << R_matchcam_origin << std::endl;
            std::cout << t_matchcam_origin << std::endl;
            
            // Extract transforms (R and t) using SolvePnP method
            for (int i=0; i < 3; i++)
            {
                t1[i] = t_matchcam_origin.at<double>(i)/projectionDistance;
                
                n1[i] = (i < 2) ? 0.0 : 1.0;
                for (int j=0; j < 3; j++)
                {
                    R1[i + 3*j] = R_matchcam_origin.at<double>(j,i);
                }
            }
        }
        
        // Debugging code to output image
        if (outputImage && (object_img.rows > 0) && (object_img.cols > 0))
        {
            UIImage *outputImg = [UIImage imageWithCVMat:object_img];
            UIImageWriteToSavedPhotosAlbum(outputImg, nil, nil, nil);
            
            // Draw box around video image in destination image
            scene_img.copyTo(dst);
            
            // Will be green box/text if homography is deemed valid, black otherwise
            if (validHomographyFound)
            {
                cv::cvtColor(dst, dst, CV_GRAY2RGB);
            }
            
            //-- Get the corners from the object image ( the object to be "detected" )
            std::vector<cv::Point2f> obj_corners(5);
            obj_corners[0] = cvPoint(0,0);
            obj_corners[1] = cvPoint( object_img_cols * scale_factor, 0 );
            obj_corners[2] = cvPoint( object_img_cols * scale_factor, object_img_rows * scale_factor );
            obj_corners[3] = cvPoint( 0, object_img_rows * scale_factor );
            obj_corners[4] = cvPoint( object_img_cols * scale_factor / 2, object_img_rows * scale_factor / 2 );
            std::vector<cv::Point2f> scene_corners(5);
            
            cv::perspectiveTransform( obj_corners, scene_corners, H );
            
            //-- Draw lines between the corners (the mapped object in the scene - image_2 )
            line( dst, scene_corners[0], scene_corners[1], cv::Scalar( 0, 255, 0), 4 );
            line( dst, scene_corners[1], scene_corners[2], cv::Scalar( 0, 255, 0), 4 );
            line( dst, scene_corners[2], scene_corners[3], cv::Scalar( 0, 255, 0), 4 );
            line( dst, scene_corners[3], scene_corners[0], cv::Scalar( 0, 255, 0), 4 );
            line( dst, scene_corners[0], scene_corners[2], cv::Scalar( 0, 255, 0), 4 );
            line( dst, scene_corners[1], scene_corners[3], cv::Scalar( 0, 255, 0), 4 );
            
            NSString *testOutStr = [NSString stringWithFormat:@"ID: %d Center: (%.2f, %.2f)",
                                    imageID, scene_corners[4].x, scene_corners[4].y];
            cv::putText(dst, testOutStr.UTF8String, cvPoint(50,125), cv::FONT_HERSHEY_SIMPLEX, 1.5f, cv::Scalar( 0, 255, 0),2);

            if (validHomographyFound)
            {
                euler_angles test_angles = [self calculateEulerAngles:R_matchcam_origin];
                testOutStr = [NSString stringWithFormat:@"euler(%.5f, %.5f, %.5f)", test_angles.theta1*180.0/M_PI, test_angles.theta2*180.0/M_PI, test_angles.theta3*180.0/M_PI];
                cv::putText(dst, testOutStr.UTF8String, cvPoint(50,200), cv::FONT_HERSHEY_SIMPLEX, 1.5f, cv::Scalar( 0, 255, 0),2);
                testOutStr = [NSString stringWithFormat:@"t(%.5f, %.5f, %.5f)",
                              t1[0]*projectionDistance, t1[1]*projectionDistance, t1[2]*projectionDistance];
                cv::putText(dst, testOutStr.UTF8String, cvPoint(50,275), cv::FONT_HERSHEY_SIMPLEX, 1.5f, cv::Scalar( 0, 255, 0),2);
            }

            outputImg = [UIImage imageWithCVMat:dst];
            UIImageWriteToSavedPhotosAlbum(outputImg, nil, nil, nil);
        }
    }
    else
    {
        result = feature_matching_match_error;
    }

    return result;
}

- (void)calcPnPWithSceneCorners:(std::vector<cv::Point2f>&)scene_corners withObjectCorners:(std::vector<cv::Point2f>&)object_corners
                   withRotation:(cv::Mat&)R_final withTranslation:(cv::Mat&)t_final
         withProjectionDistance:(float)projection_distance
{
    // Camera intrinsics
    cv::Mat K = [self calculateCameraMatrixWithRows:scene_img.rows andColums:scene_img.cols];
    
    std::cout << "K:" << std::endl;
    std::cout << K << std::endl;
    std::cout << "K_inverse:" << std::endl;
    std::cout << K.inv() << std::endl;
    
    // 2D image location of corners of matched image projected against rendering plane from the homography
    // projected on the user's camera
    std::cout << "Scene corners:" << std::endl;
    for( size_t i = 0; i < scene_corners.size(); i++ )
    {
        std::cout << scene_corners[i] << std::endl;
    }
    
    // 2D image location of image to be matched projected on it's own camera (pixel extents)
    std::cout << "Object corners:" << std::endl;
    for( size_t i = 0; i < object_corners.size(); i++ )
    {
        std::cout << object_corners[i] << std::endl;
    }
    
    // Calculate 3D points of "object" in world coordinates
    std::cout << "World coordinates:" << std::endl;
    
    std::vector<cv::Point3_<double> > planar_3d_points;
    
    for( size_t i = 0; i < scene_corners.size(); i++ )
    {
        // Corners of projected homography transform on rendering plane treated as a 3D surface
        // Assume z = 1 here, but zero out coordinate to transpose it in reference frame at center of projection plane
        cv::Mat pt1 = cv::Mat::zeros(3, 1, CV_64F);
        pt1.at<double>(0,0) = scene_corners[i].x;
        pt1.at<double>(1,0) = scene_corners[i].y;
        pt1.at<double>(2,0) = 1.0;
        
        cv::Mat result = projection_distance * K.inv() * pt1;
        
        planar_3d_points.push_back(cv::Point3_<double>(result.at<double>(0),result.at<double>(1),0.0));
        
        std::cout << i << ": " << planar_3d_points[i] << std::endl;
    }
    
    // Call solvePnP to calculate R and t given the 2D/3D pairing
    // 3D points are at the projected plane (projection_distance away along z).
    // Origin of this frame is at the center of the camera with x to the right and y down.
    // z is away from the camera
    // 2D points are the object image
    // We assume that the "box" calculated from the homography resides on the plane perpendicular to the user's camera.
    // It will have a shape dependent on the warping resulting from matching.
    // The original image which was matched will have a defined rectangular shape which projects this shape on the plane
    // because of the R and t transformations.
    // Therefore the 3D object is this skewed projection on the rendering plane (a planar surface) and the 2D image
    // points are the raw image to be matched.
    cv::Mat rvec, tvec;
    cv::Mat dist;
    cv::solvePnP(planar_3d_points, object_corners, K, dist, rvec, tvec);
    
    // Frame transformations
    cv::Mat rotM;
    cv::Rodrigues(rvec, rotM);
    
    // User camera position (of background image) to center of image plane (where camera axis intersects rendering plane)
    cv::Mat R_imageplane_usercam = cv::Mat::eye(3, 3, CV_64F);
    cv::Mat t_imageplane_usercam_Fimageplane = cv::Mat::zeros(3, 1, CV_64F);
    t_imageplane_usercam_Fimageplane.at<double>(2,0) = projection_distance;
    cv::Mat rvec_imageplane_usercam;
    cv::Rodrigues(R_imageplane_usercam, rvec_imageplane_usercam);
    
    // Center of image plane to camera frame of matched image
    cv::Mat R_matchcam_imageplane = rotM;
    cv::Mat t_matchcam_imageplane_Fmatchcam = -tvec;
    cv::Mat rvec_matchcam_imageplane;
    cv::Rodrigues(R_matchcam_imageplane, rvec_matchcam_imageplane);
    
    // User camera position (of background image) to camera frame of matched image
    cv::Mat R_matchcam_usercam = R_matchcam_imageplane*R_imageplane_usercam;
    cv::Mat tvec_matchcam_usercam = R_imageplane_usercam.t()*(R_matchcam_imageplane.t()*t_matchcam_imageplane_Fmatchcam + t_imageplane_usercam_Fimageplane);
    euler_angles euler_matchcam_usercam = [self calculateEulerAngles:R_matchcam_usercam];
    
    std::cout << "tvec_matchcam_usercam: " << tvec_matchcam_usercam << std::endl;
    std::cout << "R_matchcam_usercam: " << std::endl;
    std::cout << "theta 1: " << 180.0/M_PI*euler_matchcam_usercam.theta1 << ", theta 2: " << 180.0/M_PI*euler_matchcam_usercam.theta2
    << ", theta 3: " << 180.0/M_PI*euler_matchcam_usercam.theta3 << std::endl;
    
    R_final = R_matchcam_usercam;
    t_final = tvec_matchcam_usercam;
}

- (cv::Mat)R_x:(double)theta
{
    cv::Mat R_final = cv::Mat::eye(3, 3, CV_64F);
    
    R_final.at<double>(0,0) = 1.0;
    R_final.at<double>(1,0) = 0.0;
    R_final.at<double>(2,0) = 0.0;
    R_final.at<double>(0,1) = 0.0;
    R_final.at<double>(1,1) = cos(theta);
    R_final.at<double>(2,1) = sin(theta);
    R_final.at<double>(0,2) = 0.0;
    R_final.at<double>(1,2) = -sin(theta);
    R_final.at<double>(2,2) = cos(theta);
    
    return R_final;
}

- (cv::Mat)R_y:(double)theta
{
    cv::Mat R_final = cv::Mat::eye(3, 3, CV_64F);
    
    R_final.at<double>(0,0) = cos(theta);
    R_final.at<double>(1,0) = 0.0;
    R_final.at<double>(2,0) = -sin(theta);
    R_final.at<double>(0,1) = 0.0;
    R_final.at<double>(1,1) = 1.0;
    R_final.at<double>(2,1) = 0.0;
    R_final.at<double>(0,2) = sin(theta);
    R_final.at<double>(1,2) = 0.0;
    R_final.at<double>(2,2) = cos(theta);
    
    return R_final;
}

- (cv::Mat)R_z:(double)theta
{
    cv::Mat R_final = cv::Mat::eye(3, 3, CV_64F);
    
    R_final.at<double>(0,0) = cos(theta);
    R_final.at<double>(1,0) = sin(theta);
    R_final.at<double>(2,0) = 0.0;
    R_final.at<double>(0,1) = -sin(theta);
    R_final.at<double>(1,1) = cos(theta);
    R_final.at<double>(2,1) = 0.0;
    R_final.at<double>(0,2) = 0.0;
    R_final.at<double>(1,2) = 0.0;
    R_final.at<double>(2,2) = 1.0;
    
    return R_final;
}

- (euler_angles)calculateEulerAngles:(cv::Mat)rotM
{
    euler_angles angles;
    
    // From Computing Euler angles from a rotation matrix
    // Gregory G. Slabaugh
    angles.theta2 = -asin(rotM.at<double>(2,0));
    angles.theta1 = atan2(rotM.at<double>(2,1)/cos(angles.theta1), rotM.at<double>(2,2)/cos(angles.theta1));
    angles.theta3 = atan2(rotM.at<double>(1,0)/cos(angles.theta1), rotM.at<double>(0,0)/cos(angles.theta1));
    
    return angles;
}

- (cv::Mat)calculateCameraMatrixWithRows:(int)rows andColums:(int)cols
{
    double pixel = 0.0000014; //1.4 microns Pixel Size for iPhone5
    double fx, fy;
    double ox, oy;
    
    float focalL = 0.0041; //4.10 mm iPhone5
    
    fx = focalL/pixel;
    fy = focalL/pixel;
    ox = ((double)cols)/2.0;
    oy = ((double)rows)/2.0;
    
    cv::Mat K = cv::Mat::eye(3, 3, CV_64F);
    K.at<double>(0,0) = 1.0*fx;
    K.at<double>(1,1) = 1.0*fy;
    K.at<double>(0,2) = ox;
    K.at<double>(1,2) = oy;
    
    return K;
}

- (UIImage *)matchAndDrawFeatures
{
    // Check if object_img and scene_img are valid/set was performed higher up the stack
    std::vector<cv::DMatch> matches;
    cv::Mat fundamental;
    cv::Mat dst;
    
    if (object_img.size <= 0)
    {
        return nil;
    }

    int result = 0;
    result = self.wrappedMatcher->match(matches,
                                        keypoints_object, keypoints_scene,
                                        descriptors_object, descriptors_scene,
                                        fundamental);
    
    if (result == 0)
    {
        // Calculate homography using matches
        std::vector<cv::Point2f> obj;
        std::vector<cv::Point2f> scene;
        
        double scale_factor = scene_img.rows / object_img_rows;
        
        for( size_t i = 0; i < matches.size(); i++ )
        {
            //-- Get the keypoints from the good matches
            obj.push_back( keypoints_object[ matches[i].queryIdx ].pt * scale_factor );
            scene.push_back( keypoints_scene[ matches[i].trainIdx ].pt );
        }
        
        cv::Mat H = cv::findHomography( obj, scene, CV_LMEDS );
        
        // Draw box around video image in destination image
        scene_img.copyTo(dst);
        
        //-- Get the corners from the object image ( the object to be "detected" )
        std::vector<cv::Point2f> obj_corners(5);
        obj_corners[0] = cvPoint(0,0);
        obj_corners[1] = cvPoint( object_img_cols * scale_factor, 0 );
        obj_corners[2] = cvPoint( object_img_cols * scale_factor, object_img_rows * scale_factor );
        obj_corners[3] = cvPoint( 0, object_img_rows * scale_factor );
        obj_corners[4] = cvPoint( object_img_cols * scale_factor / 2, object_img_rows * scale_factor / 2 );
        std::vector<cv::Point2f> scene_corners(5);
        
        cv::perspectiveTransform( obj_corners, scene_corners, H );
        
        //-- Draw lines between the corners (the mapped object in the scene - image_2 )
        line( dst, scene_corners[0], scene_corners[1], cv::Scalar( 0, 255, 0), 4 );
        line( dst, scene_corners[1], scene_corners[2], cv::Scalar( 0, 255, 0), 4 );
        line( dst, scene_corners[2], scene_corners[3], cv::Scalar( 0, 255, 0), 4 );
        line( dst, scene_corners[3], scene_corners[0], cv::Scalar( 0, 255, 0), 4 );
        line( dst, scene_corners[0], scene_corners[2], cv::Scalar( 0, 255, 0), 4 );
        line( dst, scene_corners[1], scene_corners[3], cv::Scalar( 0, 255, 0), 4 );
    }
    else
    {
        dst = object_img;
    }
    
    return [UIImage imageWithCVMat:dst];
}

- (bool)isHomographyValid:(cv::Mat &)H withRows:(int)rows withCols:(int)cols
{
    bool isValid = NO;
    
    //-- Get the corners from the object image ( the object to be "detected" )
    std::vector<cv::Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0);
    obj_corners[1] = cvPoint( cols, 0 );
    obj_corners[2] = cvPoint( cols, rows );
    obj_corners[3] = cvPoint( 0, rows );
    std::vector<cv::Point2f> scene_corners(4);
    
    // Calculate "box" representing matched image in current camera frame
    cv::perspectiveTransform( obj_corners, scene_corners, H );
    
    // Determine if box is valid (if diagonal segments intersect then a convex quadrilateral)
    if ([self doLinesIntersectWithEndpointA1:scene_corners[0] withEndpointA2:scene_corners[2] withEndpointB1:scene_corners[1] withEndpointB2:scene_corners[3]])
    {
        // Also check the size of the box. If it is too small, it may be a garbage match
        if (([self lengthOfLineSegmentWithEndpointA1:scene_corners[0] withEndpointA2:scene_corners[2]] > minLengthHomographyDiagonal) &&
            ([self lengthOfLineSegmentWithEndpointA1:scene_corners[1] withEndpointA2:scene_corners[3]] > minLengthHomographyDiagonal))
        {
            if ([self sideLengthRatioCheckWithSideLengthL1:([self lengthOfLineSegmentWithEndpointA1:scene_corners[0] withEndpointA2:scene_corners[1]] /
                                                            [self lengthOfLineSegmentWithEndpointA1:obj_corners[0] withEndpointA2:obj_corners[1]])
                                                    withL2:([self lengthOfLineSegmentWithEndpointA1:scene_corners[1] withEndpointA2:scene_corners[2]] /
                                                            [self lengthOfLineSegmentWithEndpointA1:obj_corners[1] withEndpointA2:obj_corners[2]])
                                                    withL3:([self lengthOfLineSegmentWithEndpointA1:scene_corners[2] withEndpointA2:scene_corners[3]] /
                                                            [self lengthOfLineSegmentWithEndpointA1:obj_corners[2] withEndpointA2:obj_corners[3]])
                                                    withL4:([self lengthOfLineSegmentWithEndpointA1:scene_corners[3] withEndpointA2:scene_corners[0]] /
                                                            [self lengthOfLineSegmentWithEndpointA1:obj_corners[3] withEndpointA2:obj_corners[0]])])
            {
                isValid = YES;
            }
        }
    }
    
    return isValid;
}

// Check ratios of lengths of box sides. If ratio between max and min segment lengths is too large, invalid homography
- (bool)sideLengthRatioCheckWithSideLengthL1:(float)l1 withL2:(float)l2 withL3:(float)l3 withL4:(float)l4
{
    double maxLength = fmaxf(fmaxf(fmaxf(l1, l2), l3), l4);
    double minLength = fminf(fminf(fminf(l1, l2), l3), l4);
    
    return ((maxLength / minLength) < maxRatioSideLength);
}

// Determine length of line segment (A1,A2)
- (float)lengthOfLineSegmentWithEndpointA1:(cv::Point2f)A1 withEndpointA2:(cv::Point2f)A2
{
    return sqrtf(powf(A2.x - A1.x, 2) + powf(A2.y - A1.y, 2));
}

// Determine if line segment (A1,A2) and line segment (B1,B2) intersect
- (bool)doLinesIntersectWithEndpointA1:(cv::Point2f)A1 withEndpointA2:(cv::Point2f)A2 withEndpointB1:(cv::Point2f)B1 withEndpointB2:(cv::Point2f)B2
{
    // Use equation of line y=mx+b for each line
    // Solve for slope and b
    float m1 = [self slopeOfLineABWithPointA:A1 withPointB:A2];
    float m2 = [self slopeOfLineABWithPointA:B1 withPointB:B2];
    
    // Use one endpoint to calculate b
    float b1 = A1.y - m1*A1.x;
    float b2 = B1.y - m2*B1.x;
    
    float intersection_x = -(b2 - b1)/(m2 - m1);

    // No guarantee on ordering of A1, A2, B1, and B2. Get lower x coord and upper x coord.
    float A_x_low = fmin(A1.x, A2.x);
    float A_x_high = fmax(A1.x, A2.x);
    float B_x_low = fmin(B1.x, B2.x);
    float B_x_high = fmax(B1.x, B2.x);

    if ((intersection_x >= A_x_low) && (intersection_x <= A_x_high) &&
        (intersection_x >= B_x_low) && (intersection_x <= B_x_high))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (float)slopeOfLineABWithPointA:(cv::Point2f)A withPointB:(cv::Point2f)B
{
    if (fabs(B.x - A.x) < 0.00001)
    {
        // Ugly - fix in the future, but handles case of vertical lines
        return (B.y > A.y) ? 99999.0 : -99999.0;
    }
    return (B.y - A.y) / (B.x - A.x);
}

//- (void)testTransformsFromHomography
//{
//    //assuming row major
//    homography[0] = 5.404;
//    homography[1] = 0.0;
//    homography[2] = 4.436;
//    homography[3] = 0.0;
//    homography[4] = 4.0;
//    homography[5] = 0.0;
//    homography[6] = -1.236;
//    homography[7] = 0.0;
//    homography[8] = 3.804;
//    
//    //singular values {7.197, 4.000, 3.619} Pg 138
//}


- (void)dealloc
{
    delete _wrappedMatcher;
}

@end
