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

- (void)setSceneImageNoOrientationChange:(UIImage *)sceneImage
{
    cv::Mat inputImage = [sceneImage CVGrayscaleMat];
    
    scene_img = inputImage;
}



- (int)matchAndCalculateTransformsWithRotationSoln1:(double[])R1 withTranslationSoln1:(double[])t1 withNormalSoln1:(double[])n1 withRotationSoln2:(double[])R2 withTranslationSoln2:(double[])t2 withNormalSoln2:(double[])n2 withDebugImage:(bool)outputImage
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

    if (result == feature_matching_success)
    {
        // Calculate homography using matches
        std::vector<cv::Point2f> obj;
        std::vector<cv::Point2f> scene;
        
         double scale_factor = scene_img.rows / object_img.rows;
        
        [self setCameraIntrinsicsWithRows:scene_img.rows andColums:scene_img.cols];
        
        for( size_t i = 0; i < matches.size(); i++ )
        {
            //-- Get the keypoints from the good matches
            obj.push_back( keypoints_object[ matches[i].queryIdx ].pt * scale_factor);
            scene.push_back( keypoints_scene[ matches[i].trainIdx ].pt );
        }
        
        cv::Mat H = cv::findHomography( obj, scene, CV_LMEDS );
        
        homography[0] = H.at<double>(0,0);
        homography[1] = H.at<double>(1,0);
        homography[2] = H.at<double>(2,0);
        homography[3] = H.at<double>(0,1);
        homography[4] = H.at<double>(1,1);
        homography[5] = H.at<double>(2,1);
        homography[6] = H.at<double>(0,2);
        homography[7] = H.at<double>(1,2);
        homography[8] = H.at<double>(2,2);
        
        bool validHomographyFound = NO;
        
        // Check if homography calculated represents a valid match
        if (![self isHomographyValid:H withRows:object_img.rows withCols:object_img.cols])
        {
            result = feature_matching_homography_error;
            
        }
        else
        {
            validHomographyFound = YES;

             // Calculate transform_from_H
            result = [self computeRTFromHomography:homography];
            
            // Extract transforms (R and t)
            if (result == 0)
            {
                for (int i=0; i < 3; i++)
                {
                    t1[i] = self.t_from_H1.translation[i];
                    t2[i] = self.t_from_H2.translation[i];
                    n1[i] = self.t_from_H1.normal[i];
                    n2[i] = self.t_from_H2.normal[i];
                    for (int j=0; j < 3; j++)
                    {
                        R1[i + 3*j] = self.t_from_H1.rotation[i + 3*j];
                        R2[i + 3*j] = self.t_from_H2.rotation[i + 3*j];
                    }
                }
            }
        }
        
        // Debugging code to output image
        if (outputImage)
        {
            // Draw box around video image in destination image
            scene_img.copyTo(dst);
            
            // Will be a green box if homography is deemed valid, black otherwise
            if (validHomographyFound)
            {
                cv::cvtColor(dst, dst, CV_GRAY2RGB);
            }
            
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
            
            UIImage *outputImg = [UIImage imageWithCVMat:dst];
            UIImageWriteToSavedPhotosAlbum(outputImg, nil, nil, nil);
        }
    }
    else
    {
        result = feature_matching_match_error;
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

//using column major ordering

-(int) invertCameraIntrinsics
{
    int dim = 3;
    long lWork = dim * dim;
    long info = -1;
    long n = dim;
    
    //long * ipiv = (long *)malloc((5 +1) *sizeof (long));
    //double *work = (double*) malloc(3 * 3 *sizeof(double));
    int i;
    for(i=0;i <9;i++)
        ciinverse[i] = ci[i];
    
    dgetrf_(&n, &n,ciinverse, &n, &ipiv[0], &info);
    dgetri_(&n, ciinverse, &n, &ipiv[0], &work[0], &lWork,&info );
    
    //free(ipiv);
    //free(work);
    
    return info;
}

- (void)setCameraIntrinsicsWithRows:(int)rows andColums:(int)cols
{
    double pixel = 0.0000014; //1.4 microns Pixel Size for iPhone5
    double fx, fy;
    double ox, oy;
    
    float focalL = 0.0041; //4.10 mm iPhone5
    
    fx = focalL/pixel;
    fy = focalL/pixel;
    ox = ((double)cols)/2.0; //quarter hd
    oy = ((double)rows)/2.0; //quarter hd
    
    ci[0] = 1.0 * fx;
    ci[1] = 0.0;
    ci[2] = 0.0;
    ci[3] = 0.0;
    ci[4] = 1.0 * fy;
    ci[5] = 0.0;
    ci[6] = ox;
    ci[7] = oy;
    ci[8] = 1.0;
    
    [self invertCameraIntrinsics];
    
}

- (void)computeSVD33: (double*)a U:(double*)u S:(double*)s vT:(double*) vt
{
    long m = 3;
    long n = 3;
    long lda= 3;
    
    //column major for lapack
    
    double workSize;
    double *work = &workSize;
    long lwork = -1;
    long iwork[24];
    long info = 0;
    char jobz[1];
    jobz[0] = 'A';
    dgesdd_(jobz, &m, &n, &a[0], &lda, s, u, &m, vt, &n, work, &lwork, iwork, &info);
    NSLog(@"workSize = %f", workSize);
    lwork = workSize;
    work =(double*) malloc(lwork *sizeof(double));
    dgesdd_(jobz, &m, &n, &a[0], &lda, s, u, &m, vt, &n, work, &lwork, iwork, &info);
    
    free(work);
}

//u X v
-(void) crossProductVec1:(double*) u Vec2:(double*) v vecResult:(double *) r
{
    r[0] = u[1]*v[2] - u[2] * v[1];
    r[1] = u[2]*v[0] - u[0] * v[2];
    r[2] = u[0]*v[1] - u[1] * v[0];
}



- (double)computeDeterminant:(double*)detMat
{
    
    //column major
    double a = detMat[0];
    double d = detMat[1];
    double g = detMat[2];
    double b = detMat[3];
    double e = detMat[4];
    double h = detMat[5];
    double c = detMat[6];
    double f = detMat[7];
    double i = detMat[8];
    
    return a*e*i+b*f*g +c*d*h - c*e*g - b*d*i - a*f*h;
    
}


-(int) computeRTFromHomography:(double *) pH
{
    //double pH[9]; //projective homography set this in OpenCV
    double tmpMat[9];
     double eH[9]; //Euclidean Homography
    double HtH[9];
    double s[3];
    double u[9];
    double vt[9];
    double scale;
    double scaleSq;
    double tmp3;
    double tmp1Vec[3];
    double tmp2Vec[3];
    double tmp3Vec[3];
    int i;
    double u1[3], u2[3], v1[3], v2[3], v3[3];
    double U1[9], U2[9], W1[9], W2[9];
    double sign = 1.0;
    
    double determinant =0.0;
    
    
    //calculate euclidean homography
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 3, 3, 1.0, ciinverse, 3, pH, 3, 0.0, tmpMat, 3);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 3 , 3, 1.0, tmpMat, 3, ci, 3, 0.0, eH, 3);
    
    /*
    eH[0] = 5.404;
    eH[1] = 0.0;
    eH[2] = -1.236;
    
    eH[3] = 0.0;
    eH[4] = 4.0;
    eH[5] = 0.0;
    eH[6] = 4.436;
    eH[7] = 0.0;
    eH[8] = 3.804;
    */
    
    
    cblas_dgemm(CblasColMajor, CblasTrans, CblasNoTrans, 3, 3, 3, 1.0, eH, 3, eH, 3, 0.0, HtH, 3);
    [self computeSVD33: &HtH[0] U:&u[0] S:&s[0] vT:&vt[0]];
    NSLog(@"SVD s:[%.4f %.4f %.4f ]",sqrt(s[0]), sqrt(s[1]), sqrt(s[2]));
    
    
    double lambda = sqrt(s[1]);
    
    //normalize eH
    for(i=0; i<9;i++)
        eH[i] = eH[i]/lambda;
    
    cblas_dgemm(CblasColMajor, CblasTrans, CblasNoTrans, 3, 3, 3, 1.0, eH, 3, eH, 3, 0.0, HtH, 3);
    [self computeSVD33: &HtH[0] U:&u[0] S:&s[0] vT:&vt[0]];
    NSLog(@"SVD 2 s:[%.4f %.4f %.4f ]",(s[0]), (s[1]), (s[2]));
    
    
    determinant =[self computeDeterminant:&u[0]];
    
    if((determinant - (-1.0))<1e-5)
    {
        for(i=0;i<9;i++)
        {
            u[i] = -1.0 * u[i];
            vt[i]= -1.0*  vt[i];
            
        }
    }
    
    
    if(s[0]-s[2]< 1e-5)
    {
        NSLog(@"cannot compute transfroms no relative motion");
        return -1;
    }
    
    scale =1.0;

    for(i=0; i <3; i++)
    {
        v1[i] = u[i];
        v2[i] = u[i+3];
        v3[i] = u[i+6];
    }
    
    for(i=0; i <3; i++)
    {
        tmp1Vec[i] = v1[i] * sqrt(1.0 -s[2]);
        tmp2Vec[i] = v3[i] * sqrt(s[0] -1.0);
        
    }
    
    tmp3 = 1.0/(sqrt(s[0]-s[2]));
    
    for(i=0; i <3; i++)
    {
        u1[i] = tmp3 * (tmp1Vec[i] + tmp2Vec[i]);
        u2[i] = tmp3 * (tmp1Vec[i] - tmp2Vec[i]);
    }
    
   // NSLog(@"u1 = [%f %f %f]",u1[0], u1[1], u1[2] );
   // NSLog(@"u2 = [%f %f %f]",u2[0], u2[1], u2[2] );
    
    //Set U1
    [self crossProductVec1:v2 Vec2:u1 vecResult:tmp1Vec];
    for(i=0; i<3; i++)
    {
        U1[i] = v2[i];
        U1[i+3] = u1[i];
        U1[i+6] = tmp1Vec[i];
    }
    
    //Set U2
    [self crossProductVec1:v2 Vec2:u2 vecResult:tmp1Vec];
    for(i=0; i<3; i++)
    {
        U2[i] = v2[i];
        U2[i+3] = u2[i];
        U2[i+6] = tmp1Vec[i];
    }
    
    //Set W1
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, scale, eH, 3, v2, 3, 0.0, tmp1Vec, 3);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, scale, eH, 3, u1, 3, 0.0, tmp2Vec, 3);
    [self crossProductVec1:tmp1Vec Vec2:tmp2Vec vecResult:tmp3Vec];
    for(i=0; i<3; i++)
    {
        W1[i] = tmp1Vec[i];
        W1[i+3] = tmp2Vec[i];
        W1[i+6] = tmp3Vec[i];
    }
    
    //Set W2
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, scale, eH, 3, u2, 3, 0.0, tmp2Vec, 3);
    [self crossProductVec1:tmp1Vec Vec2:tmp2Vec vecResult:tmp3Vec];
    for(i=0; i<3; i++)
    {
        W2[i] = tmp1Vec[i];
        W2[i+3] = tmp2Vec[i];
        W2[i+6] = tmp3Vec[i];
    }
    
    //Result 1
    [self crossProductVec1:v2 Vec2:u1 vecResult:result1.normal];
    (result1.normal[2] < 0) ? (sign = -1.0) : (sign = 1.0);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasTrans, 3, 3, 3, 1.0, W1, 3, U1, 3, 1.0, result1.rotation, 3);
    
    for(i=0; i<3; i++)
        result1.normal[i] *=sign;
    for(i=0; i<9; i++)
        tmpMat[i] = scale* eH[i] - result1.rotation[i];
    
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, 1.0, tmpMat, 3, result1.normal, 3, 0.0, result1.translation, 3);
    
    //Result2
    [self crossProductVec1:v2 Vec2:u2 vecResult:result2.normal];
    (result2.normal[2] < 0) ? (sign = -1.0) : (sign = 1.0);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasTrans, 3, 3, 3, 1.0, W2, 3, U2, 3, 1.0, result2.rotation, 3);
    
    for(i=0; i<3; i++)
        result2.normal[i] *=sign;
    for(i=0; i<9; i++)
        tmpMat[i] = scale* eH[i] - result2.rotation[i];
    
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 3, 1 , 3, 1.0, tmpMat, 3, result2.normal, 3, 0.0, result2.translation, 3);
    
    /*
     NSLog(@"v1 [%.6f %.6f %.6f]", v1[0], v1[1], v1[2]);
     NSLog(@"v2 [%.6f %.6f %.6f]", v2[0], v2[1], v2[2]);
     NSLog(@"v3 [%.6f %.6f %.6f]", v3[0], v3[1], v3[2]);
     NSLog(@"u1 [%.6f %.6f %.6f]", u1[0], u1[1], u1[2]);
     NSLog(@"u2 [%.6f %.6f %.6f]", u2[0], u2[1], u2[2]);
     */
    
        
    self.t_from_H1 = result1;
    self.t_from_H2 = result2;
    
    return 0;
}

/*
 -(void) testTransforms
 {
 
 NSLog(@"---------------------------------");
 NSLog(@"normal [%.6f %.6f %.6f]", result1.normal[0], result1.normal[1], result1.normal[2]);
 NSLog(@"translation [%.6f %.6f %.6f]", result1.translation[0], result1.translation[1], result1.translation[2]);
 NSLog(@"rotation1 [%.6f %.6f %.6f]", result1.rotation[0], result1.rotation[3], result1.rotation[6]);
 NSLog(@"rotation1 [%.6f %.6f %.6f]", result1.rotation[1], result1.rotation[4], result1.rotation[7]);
 NSLog(@"rotation1 [%.6f %.6f %.6f]", result1.rotation[2], result1.rotation[5], result1.rotation[8]);
 
 NSLog(@"---------------------------------");
 NSLog(@"normal [%.6f %.6f %.6f]", result2.normal[0], result2.normal[1], result2.normal[2]);
 NSLog(@"translation [%.6f %.6f %.6f]", result2.translation[0], result2.translation[1], result2.translation[2]);
 
 NSLog(@"rotation1 [%.6f %.6f %.6f]", result2.rotation[0], result2.rotation[3], result2.rotation[6]);
 NSLog(@"rotation1 [%.6f %.6f %.6f]", result2.rotation[1], result2.rotation[4], result2.rotation[7]);
 NSLog(@"rotation1 [%.6f %.6f %.6f]", result2.rotation[2], result2.rotation[5], result2.rotation[8]);
 
 
 }
 
 */

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

    if ((intersection_x > A_x_low) && (intersection_x < A_x_high) &&
        (intersection_x > B_x_low) && (intersection_x < B_x_high))
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
    return (B.y - A.y) / (B.x - A.x);
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
