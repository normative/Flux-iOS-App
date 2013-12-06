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

@interface FluxMatcherWrapper ()
{
    // Convert to grayscale before populating for performance improvement
    cv::Mat object_img;
    cv::Mat scene_img;
    
    double intrinsicsInverse[9];
    double homography[9];
}

//C++ class from FluxMatcher.cpp
@property (nonatomic, assign) FluxMatcher *wrappedMatcher;
@property (nonatomic) transformRt t_from_H;

@end

@implementation FluxMatcherWrapper

@synthesize wrappedMatcher = _wrappedMatcher;

- (id)init
{
    self = [super init];
    if (self)
    {
        _wrappedMatcher = new FluxMatcher();
        
        [self computeInverseCameraIntrinsics];
    }
    return self;
}

- (void)matchFeatures
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
- (void)setObjectImage:(UIImage *)objectImage
{
    cv::Mat inputImage = [objectImage CVGrayscaleMat];
    
    object_img = inputImage;
}

// Scene images are the background camera feed to match against
- (void)setSceneImage:(UIImage *)sceneImage
{
    cv::Mat inputImage = [sceneImage CVGrayscaleMat];
    
    cv::transpose(inputImage, inputImage);
    cv::flip(inputImage, inputImage, 1);
    
    scene_img = inputImage;
}

- (int)matchAndCalculateTransformsWithRotation:(double[])R withTranslation:(double[])t
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
        
        homography[0] = H.at<float>(0,0);
        homography[1] = H.at<float>(0,1);
        homography[2] = H.at<float>(0,2);
        homography[3] = H.at<float>(1,0);
        homography[4] = H.at<float>(1,1);
        homography[5] = H.at<float>(1,2);
        homography[6] = H.at<float>(2,1);
        homography[7] = H.at<float>(2,2);
        homography[8] = H.at<float>(2,3);
        
        // Check if homography calculated represents a valid match
        if (![self isHomographyValid:H withRows:object_img.rows withCols:object_img.cols])
        {
            result = -1;
            
        }
        else
        {
            // Calculate transform_from_H
            result = [self computeTransformsFromHomography];
            
            // Extract transforms (R and t)
            if (result == 0)
            {
                for (int i=0; i < 3; i++)
                {
                    t[i] = self.t_from_H.translation[i];
                    for (int j=0; j < 3; j++)
                    {
                        R[i + 3*j] = self.t_from_H.rotation[i + 3*j];
                    }
                }
            }
        }
    }
    
    return result;
}

- (UIImage *)matchAndDrawFeatures
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

//Needs to be at least one set for each camera model
- (void)computeInverseCameraIntrinsics
{
    double pixel = 0.0000014; //1.4 microns Pixel Size for iPhone5
    double fx, fy;
    double cx, cy;
    
    float focalL = 0.0041; //4.10 mm iPhone5
    
    fx = focalL/pixel;
    fy = focalL/pixel;
    cx = 0.0;
    cy = 0.0;
    
    intrinsicsInverse[0] = 1.0/fx;
    intrinsicsInverse[1] = 0.0;
    intrinsicsInverse[2] = -1.0 * cx/fx;
    intrinsicsInverse[3] = 0.0;
    intrinsicsInverse[4] = 1.0/fy;
    intrinsicsInverse[5] = -1.0 * cy/fy;
    intrinsicsInverse[6] = 0.0;
    intrinsicsInverse[7] = 0.0;
    intrinsicsInverse[8] = 1.0;
    
}

- (void)computeNextOrthonormal
{
    long m = 3;
    long n = 3;
    long lda= 3;
    
    //column major for lapack
    double s[3];
    double u[9];
    double vt[9];
    double workSize;
    double *work = &workSize;
    long lwork = -1;
    long iwork[24];
    long info = 0;
    char jobz[1];
    jobz[0] = 'A';
    dgesdd_(jobz, &m, &n, &self.t_from_H.rotation[0], &lda, s, u, &m, vt, &n, work, &lwork, iwork, &info);
    NSLog(@"workSize = %f", workSize);
    lwork = workSize;
    work =(double*) malloc(lwork *sizeof(double));
    dgesdd_(jobz, &m, &n, &self.t_from_H.rotation[0], &lda, s, u, &m, vt, &n, work, &lwork, iwork, &info);
    
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 3, 3, 1.0, u, 3, vt, 3, 1.0, self.t_from_H.rotation, 3);
    
    free(work);
}

- (int)computeTransformsFromHomography
{
    double h[9]; //convenience matrix;
    double r[9];
    double invC[9]; //convenience matrix;
    int i;
    double invH[3];
    double lambda;
    
    for(i = 0; i<9; i++)
    {
        h[i] = homography[i];
        invC[i] = intrinsicsInverse[i];
    }
    
    invH[0] = invC[0] * h[0] + invC[1] * h[1] + invC[2] * h[2];
    invH[1] = invC[3] * h[0] + invC[4] * h[1] + invC[5] * h[2];
    invH[2] = invC[6] * h[0] + invC[7] * h[1] + invC[8] * h[2];
    
    lambda = sqrt(invH[0] * invH[0] + invH[1] * invH[1] + invH[2] * invH[2] );
    
    if (lambda == 0)
        return -1;
    
    lambda = 1.0/lambda;
    
    for(i = 0; i <9 ; i++)
        invC[i] *= lambda;
    
    //Nomalized R1 & R2
    r[0] = invC[0] * h[0] + invC[1] * h[1] + invC[2]*  h[2];
    r[1] = invC[3] * h[0] + invC[4] * h[1] + invC[5] * h[2];
    r[2] = invC[6] * h[0] + invC[7] * h[1] + invC[8] * h[2];
    

    r[3] = invC[0] * h[3] + invC[1] * h[4] + invC[2]*  h[5];
    r[4] = invC[3] * h[3] + invC[4] * h[4] + invC[5] * h[5];
    r[5] = invC[6] * h[3] + invC[7] * h[4] + invC[8] * h[5];
    
    //R3 orthonormal to R1 and R2
    r[6] = r[1] * r[5] - r[2] * r[4];
    r[7] = r[2] * r[3] - r[0] * r[5];
    r[8] = r[0] * r[4] - r[1] * r[3];
    
    transformRt tempRt;
    tempRt.translation[0] = invC[0] * h[6] + invC[1] * h[7] + invC[2]*  h[8];
    tempRt.translation[1] = invC[3] * h[6] + invC[4] * h[7] + invC[5] * h[8];
    tempRt.translation[2] = invC[6] * h[6] + invC[7] * h[7] + invC[8] * h[8];

    tempRt.rotation[0] = r[0];
    tempRt.rotation[1] = r[3];
    tempRt.rotation[2] = r[6];
    tempRt.rotation[3] = r[1];
    tempRt.rotation[4] = r[4];
    tempRt.rotation[5] = r[7];
    tempRt.rotation[6] = r[2];
    tempRt.rotation[7] = r[5];
    tempRt.rotation[8] = r[8];
    self.t_from_H = tempRt;

    //Transform rotation matrix into next orthonormal matrix (Frobenius)
    [self computeNextOrthonormal];
    
    return 0;
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
        // TODO: We may also want to check the size of the box. If it is too small, it may be a garbage match
        isValid = YES;
    }
    
    return isValid;
}

// Determine if line segment (A1,A2) and line segment (B1,B2) intersect
- (bool)doLinesIntersectWithEndpointA1:(CvPoint)A1 withEndpointA2:(CvPoint)A2 withEndpointB1:(CvPoint)B1 withEndpointB2:(CvPoint)B2
{
    // Line1 made with endpoints (A1, A2) and Line2 made with endpoints (B1,B2)
    // If and only if endpoints A1,A2 are on opposite sides of the line (B1,B2)
    // and endpoints B1,B2 are on opposite sides of the line (A1,A2)
    // then the line segments intersect.
    // Can use counter-clockwise relationship of sets of points to test for this
    if ([self ccwWithPointA:A1 withPointB:B1 withPointC:B2] == [self ccwWithPointA:A2 withPointB:B1 withPointC:B2])
    {
        return NO;
    }
    else if ([self ccwWithPointA:A1 withPointB:A2 withPointC:B1] == [self ccwWithPointA:A1 withPointB:A2 withPointC:B2])
    {
        return NO;
    }
    
    return YES;
}

// Determine if sequence of points (A,B,C) form a counter-clockwise hull
- (bool)ccwWithPointA:(CvPoint)A withPointB:(CvPoint)B withPointC:(CvPoint)C
{
    float slope_AB = (B.y - A.y) / (B.x - A.x);
    float slope_AC = (C.y - A.y) / (C.x - A.x);
    return slope_AB < slope_AC;
}

- (void)testTransformsFromHomography
{
    //assuming row major
    homography[0] = 5.404;
    homography[1] = 0.0;
    homography[2] = 4.436;
    homography[3] = 0.0;
    homography[4] = 4.0;
    homography[5] = 0.0;
    homography[6] = -1.236;
    homography[7] = 0.0;
    homography[8] = 3.804;
    
    //singular values {7.197, 4.000, 3.619} Pg 138
}


- (void)dealloc
{
    delete _wrappedMatcher;
}

@end
