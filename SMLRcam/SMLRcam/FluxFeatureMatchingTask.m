//
//  FluxFeatureMatchingTask.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingTask.h"

// Time interval after which to retry feature matching

// If homography fails, it means we had good correspondence with features, but no valid matched box
const double retryTimeIfInvalidHomographyIfDisplayed = 1.5;
const double retryTimeIfInvalidHomographyIfNotDisplayed = 6.0;
// If feature matching fails, it means we likely don't have the same features in the current FOV
const double retryTimeIfInvalidMatchIfDisplayed = 3.0;
const double retryTimeIfInvalidMatchIfNotDisplayed = 12.0;

enum {SOLUTION1 = 0, SOLUTION2, SOLUTION1Neg, SOLUTION2Neg};


@implementation FluxFeatureMatchingTask

@synthesize delegate = _delegate;

#pragma mark - Life Cycle

- (id)initWithFeatureMatchingRecord:(FluxFeatureMatchingRecord *)record withMatcher:(FluxMatcherWrapper *)matcher delegate:(id<FluxFeatureMatchingTaskDelegate>)theDelegate
{
    if (self = [super init])
    {
        self.delegate = theDelegate;
        self.matchRecord = record;
        self.matcherEngine = matcher;
    }
    return self;
}

#pragma mark - Feature matching on image

- (void)main
{
    @autoreleasepool
    {
        NSDate *startTime = [NSDate date];
        
        int result = feature_matching_success;
        
        // Make sure camera frame (scene) and object are both available
        if (self.isCancelled || !self.matchRecord.hasCameraScene || !self.matchRecord.hasObjectFeatures)
        {
            [(NSObject *)self.delegate performSelectorOnMainThread:@selector(featureMatchingTaskWasCancelled:) withObject:self waitUntilDone:NO];
            return;
        }
        
        // Set object image features/image
        [self.matcherEngine setObjectFeatures:self.matchRecord.ire.imageMetadata.features];
        [self.matcherEngine setObjectImage:self.matchRecord.ire.imageCacheObject.image];
        
        // Set scene image features/image using previously computed values
        if (![self.matcherEngine setSceneImage:self.matchRecord.cfe.cameraFrameMatchImage
                                 withImageRows:self.matchRecord.cfe.cameraFrameMatchImageRows
                                 withImageCols:self.matchRecord.cfe.cameraFrameMatchImageCols
                                withImageSteps:self.matchRecord.cfe.cameraFrameMatchImageSteps
                                 withKeypoints:self.matchRecord.cfe.cameraFeatureKeypoints
                               withDescriptors:self.matchRecord.cfe.cameraFeatureDescriptors
                           withDescriptorsRows:self.matchRecord.cfe.cameraFeatureDescriptorsRows
                           withDescriptorsCols:self.matchRecord.cfe.cameraFeatureDescriptorsCols
                          withDescriptorsSteps:self.matchRecord.cfe.cameraFeatureDescriptorsSteps])
        {
            NSLog(@"Error reading pre-extracted feature buffer for camera frame. Aborting match.");
            result = feature_matching_extract_camera_features_error;
        }
        else
        {
            double rotation1[9];
            double translation1[3];
            double normal1[3];
            
            result = [self.matcherEngine matchAndCalculateTransformsWithRotation:rotation1
                                                                 withTranslation:translation1
                                                                      withNormal:normal1
                                                          withProjectionDistance:self.matchRecord.cfe.cameraProjectionDistance
                                                                  withDebugImage:NO //Debugging of images
                                                                     withImageID:self.matchRecord.ire.imageMetadata.imageID];
            
            if (feature_matching_success == result)
            {
                self.matchRecord.ire.imageMetadata.userHomographyPose = self.matchRecord.cfe.cameraPose;
                
                sensorPose imagePosePnP = self.matchRecord.ire.imageMetadata.imageHomographyPosePnP;
                
                [self computeImagePoseInECEF:&imagePosePnP
                                    userPose: self.matchRecord.ire.imageMetadata.userHomographyPose
                               hTranslation1: translation1
                                  hRotation1: rotation1
                                    hNormal1: normal1
                               hTranslation2:translation1
                                  hRotation2:rotation1
                                    hNormal2:normal1];
                
                self.matchRecord.ire.imageMetadata.imageHomographyPosePnP = imagePosePnP;
            }
        }
        
        // Check again if operation is cancelled after performing feature matching in case location is no longer valid
        // Doesn't matter if cancelled (since previous values were populated) as nothing happens
        // until location_data_type is set.
        if (self.isCancelled)
        {
            [(NSObject *)self.delegate performSelectorOnMainThread:@selector(featureMatchingTaskWasCancelled:) withObject:self waitUntilDone:NO];
            return;
        }
        
        // If not cancelled, finish things up
        if (feature_matching_success == result)
        {
            // Flag to use homography for rendering of image
            self.matchRecord.ire.imageMetadata.location_data_type = location_data_from_homography;
        
            // Update match information
            self.matchRecord.ire.imageMetadata.matched = YES;   // This one goes in the FluxDataStore cache
            self.matchRecord.matched = YES;                     // This one is just quick access for the record
        }
        else
        {
            // Matching failed. Need to try again later.
            self.matchRecord.failed = YES;
            self.matchRecord.ire.imageMetadata.matchFailed = YES;
            
            // Set the next retry time (depends if homography, matching, or camera extract failure)
            NSTimeInterval timeBeforeRetry = 0.0;
            if (feature_matching_homography_error == result)
            {
                timeBeforeRetry = self.matchRecord.isImageDisplayed ? retryTimeIfInvalidHomographyIfDisplayed : retryTimeIfInvalidHomographyIfNotDisplayed;
                self.matchRecord.ire.imageMetadata.numFeatureMatchFailHomographyErrors++;
            }
            else if (feature_matching_match_error == result)
            {
                timeBeforeRetry = self.matchRecord.isImageDisplayed ? retryTimeIfInvalidMatchIfDisplayed : retryTimeIfInvalidMatchIfNotDisplayed;
                self.matchRecord.ire.imageMetadata.numFeatureMatchFailMatchErrors++;
            }
            else if (feature_matching_extract_camera_features_error == result)
            {
                timeBeforeRetry = 0.0;
            }
            
            self.matchRecord.ire.imageMetadata.matchFailureRetryTime = [NSDate dateWithTimeIntervalSinceNow:timeBeforeRetry];
        }
        
        NSTimeInterval timeElapsedForCurrentMatch = [[NSDate date] timeIntervalSinceDate:startTime];
        self.matchRecord.ire.imageMetadata.cumulativeFeatureMatchTime = self.matchRecord.ire.imageMetadata.cumulativeFeatureMatchTime + timeElapsedForCurrentMatch;
        
        NSLog(@"Matching of localID %@ completed in %f seconds", self.matchRecord.ire.localID, timeElapsedForCurrentMatch);

        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(featureMatchingTaskDidFinish:) withObject:self waitUntilDone:NO];
    }
}

#pragma -- WGS84 tranforms

-(void) computeInverseRotationMatrixFromPose:(sensorPose*) sp
{
    
    float rotation_te[16];
    
    GLKVector3 lla_rad; //latitude, longitude, altitude
    
    lla_rad.x = sp->position.x*M_PI/180.0;
    lla_rad.y = sp->position.y*M_PI/180.0;
    lla_rad.z = sp->position.z;
    
    rotation_te[0] = -1.0 * sin(lla_rad.y);
    rotation_te[1] = cos(lla_rad.y);
    rotation_te[2] = 0.0;
    rotation_te[3]= 0.0;
    rotation_te[4] = -1.0 * cos(lla_rad.y)* sin(lla_rad.x);
    rotation_te[5] = -1.0 * sin(lla_rad.x) * sin(lla_rad.y);
    rotation_te[6] = cos(lla_rad.x);
    rotation_te[7]= 0.0;
    rotation_te[8] = cos(lla_rad.x) * cos(lla_rad.y);
    rotation_te[9] = cos(lla_rad.x) * sin(lla_rad.y);
    rotation_te[10] = sin(lla_rad.x);
    rotation_te[11]= 0.0;
    rotation_te[12]= 0.0;
    rotation_te[13]= 0.0;
    rotation_te[14]= 0.0;
    rotation_te[15]= 1.0;
    
    inverseRotation_teM = GLKMatrix4MakeWithArray(rotation_te);
    
}

- (int) solutionBasedOnNormalWithNormal1:(double *) normal1 withNormal2:(double*)normal2 withPlaneNormal:(GLKVector3) planeNormal
{
    int solution1 = SOLUTION1;
    int solution2 = SOLUTION2;
    
    GLKVector3 normal1V = GLKVector3Make(normal1[0], normal1[1], normal1[2]);
    GLKVector3 normal2V = GLKVector3Make(normal2[0], normal2[1], normal2[2]);
    normal1V    = GLKVector3Normalize(normal1V);
    normal2V    = GLKVector3Normalize(normal2V);
    planeNormal = GLKVector3Normalize(planeNormal);
    
   // double dotProduct1 = planeNormal.x * normal1[0] + planeNormal.y * normal1[1] + planeNormal.z * normal1[2];
   // double dotProduct2 = planeNormal.x * normal2[0] + planeNormal.y * normal2[1] + planeNormal.z * normal2[2];
    
    //Positive depth constraint to get 2 of the 4 possible solutions;
    /*
    if(dotProduct1 < 0.0)
    {
       dotProduct1= planeNormal.x * -1.0* normal1[0] + planeNormal.y * -1.0 * normal1[1] + planeNormal.z * -1.0 *normal1[2];
       solution1 = SOLUTION1Neg;
    }
    
    if(dotProduct2 < 0.0)
    {
        dotProduct2 = planeNormal.x * -1.0 * normal2[0] + planeNormal.y * -1.0 * normal2[1] + planeNormal.z * -1.0 * normal2[2];
        solution2 = SOLUTION2Neg;
    }
    */
    double dotProduct1 = GLKVector3DotProduct(normal1V, planeNormal);
    double dotProduct2 = GLKVector3DotProduct(normal2V, planeNormal);
    if(dotProduct1 <0)
    {
        normal1V = GLKVector3Make(-1.0 * normal1V.x, -1.0* normal1V.y, -1.0*normal1V.z);
        dotProduct1 = GLKVector3DotProduct(normal1V, planeNormal);
        solution1 = SOLUTION1Neg;
    }
    if(dotProduct2 <0)
    {
        normal2V = GLKVector3Make(-1.0 * normal2V.x, -1.0* normal2V.y, -1.0*normal2V.z);
        dotProduct2 = GLKVector3DotProduct(normal2V, planeNormal);
        solution2 = SOLUTION2Neg;
    }

    
    return (dotProduct1 > dotProduct2) ? solution1:solution2;
}


typedef struct
{
    GLKVector3 normal;
    GLKVector3 translation;
    double rotation[9];
} rntTransforms;

- (void) arrayDataCopyWithLeft:(double*)left andRight:(double*)right withSize:(int)size withFactor :(double)factor
{
    int i;
    for (i =0; i< size; i++)
    {
        left[i] = factor* right[i];
    }
    
}
rntTransforms rntResult;
- (void) computeImagePoseInECEF:(sensorPose*)iPose userPose:(sensorPose)upose hTranslation1:(double*)translation1 hRotation1:(double *)rotation1 hNormal1:(double *)normal1 hTranslation2:(double*)translation2 hRotation2:(double *)rotation2 hNormal2:(double *)normal2
{
    float rotation44[16];
    
    double rotation[9];
    double translation[3];
    double normal[3];
    int i;
    GLKVector3 cameraNormal = GLKVector3Make(0.0, 0.0, 1.0);
    
    GLKMatrix4 transformMat = GLKMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);
    
    
    //DEBUG code
    rntTransforms transforms[4];
    
    transforms[0].translation.x = translation1[0];
    transforms[0].translation.y = translation1[1];
    transforms[0].translation.z = translation1[2];
    
    transforms[1].translation.x = translation2[0];
    transforms[1].translation.y = translation2[1];
    transforms[1].translation.z = translation2[2];
    
    transforms[2].translation.x = -1.0*translation1[0];
    transforms[2].translation.y = -1.0*translation1[1];
    transforms[2].translation.z = -1.0*translation1[2];

    transforms[3].translation.x = -1.0*translation2[0];
    transforms[3].translation.y = -1.0*translation2[1];
    transforms[3].translation.z = -1.0*translation2[2];
   
  
    transforms[0].normal.x =  normal1[0];
    transforms[0].normal.y =  normal1[1];
    transforms[0].normal.z =  normal1[2];
    
    transforms[1].normal.x =  normal2[0];
    transforms[1].normal.y =  normal2[1];
    transforms[1].normal.z =  normal2[2];
    
    transforms[2].normal.x =  -1.0 * normal1[0];
    transforms[2].normal.y =  -1.0 * normal1[1];
    transforms[2].normal.z =  -1.0 * normal1[2];
    
    transforms[3].normal.x =  -1.0 * normal2[0];
    transforms[3].normal.y =  -1.0 * normal2[1];
    transforms[3].normal.z =  -1.0 * normal2[2];
    
    for(i=0;i<4;i++)
    {
        transforms[i].translation =GLKMatrix4MultiplyVector3(transformMat, transforms[i].translation);
        transforms[i].normal =GLKMatrix4MultiplyVector3(transformMat, transforms[i].normal);
    }
    
    //DEBUG ends
    
    
    
    
    int solution = 0;
    
   

    solution = [self solutionBasedOnNormalWithNormal1:normal1
                                          withNormal2:normal2
                                      withPlaneNormal:cameraNormal];
    switch(solution)
    {
        case SOLUTION1:
            [self arrayDataCopyWithLeft:rotation andRight:rotation1 withSize:9 withFactor:1.0];
            [self arrayDataCopyWithLeft:translation andRight:translation1 withSize:3 withFactor:1.0];
            [self arrayDataCopyWithLeft:normal andRight:normal1 withSize:3 withFactor:1.0];
            break;
        case SOLUTION1Neg:
            [self arrayDataCopyWithLeft:rotation andRight:rotation1 withSize:9 withFactor:1.0];
            [self arrayDataCopyWithLeft:translation andRight:translation1 withSize:3 withFactor:-1.0];
            [self arrayDataCopyWithLeft:normal andRight:normal1 withSize:3 withFactor:-1.0];
            break;
        case SOLUTION2:
            [self arrayDataCopyWithLeft:rotation andRight:rotation2 withSize:9 withFactor:1.0];
            [self arrayDataCopyWithLeft:translation andRight:translation2 withSize:3 withFactor:1.0];
            [self arrayDataCopyWithLeft:normal andRight:normal2 withSize:3 withFactor:1.0];
            break;
        case SOLUTION2Neg:
            [self arrayDataCopyWithLeft:rotation andRight:rotation2 withSize:9 withFactor:1.0];
            [self arrayDataCopyWithLeft:translation andRight:translation2 withSize:3 withFactor:-1.0];
            [self arrayDataCopyWithLeft:normal andRight:normal2 withSize:3 withFactor:-1.0];
            break;
            
   
    }
    
    //rotation
    rotation44[0] = rotation[0];
    rotation44[1] = rotation[1];
    rotation44[2] = rotation[2];
    rotation44[3]= 0.0;
    rotation44[4] = rotation[3];
    rotation44[5] = rotation[4];
    rotation44[6] = rotation[5];
    rotation44[7]= 0.0;
    rotation44[8] = rotation[6];
    rotation44[9] = rotation[7];
    rotation44[10] = rotation[8];
    rotation44[11]= 0.0;
    rotation44[12]= 0.0;
    rotation44[13]= 0.0;
    rotation44[14]= 0.0;
    rotation44[15]= 1.0;
    

    GLKMatrix4 rotationMatrix = GLKMatrix4MakeWithArray(rotation44);
   // rotationMatrix =GLKMatrix4Invert(rotationMatrix, &invertible);
    
    
    //GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    //GLKMatrix4 tpuRotationMatrix =  GLKMatrix4Multiply(matrixTP, tmprotMatrix);
    //iPose->rotationMatrix = GLKMatrix4Multiply(rotationMatrixT, tpuRotationMatrix);
    
    
    
    GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);

    positionTP.x = 15.0*translation[0];
    positionTP.y = 15.0*translation[1];
    positionTP.z = 15.0 *translation[2];
    
    positionTP = GLKMatrix4MultiplyVector3(transformMat, positionTP);
    
    iPose->position = positionTP;
    //iPose->ecef.x = normal[0];
    //iPose->ecef.y = normal[1];
    //iPose->ecef.z = normal[2];
 
   // normalR = GLKMatrix4Invert(normalR, &invertible);
    GLKMatrix4 rotationMatrixT = GLKMatrix4Multiply(transformMat, rotationMatrix);
    
    iPose->rotationMatrix = rotationMatrixT;
    //normal changed to 0, 0, 1.
    //GLKMatrix4 normalR = [self computeNormalTransformMatrix:normal];
    
    //normalR = GLKMatrix4Identity;
    //iPose->position = GLKMatrix4MultiplyVector3(normalR, positionTP);
    //iPose->rotationMatrix = GLKMatrix4Multiply(normalR, iPose->rotationMatrix);
    
    
    //User pose matrix in tangent plane
    GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    matrixTP = GLKMatrix4Identity;
    GLKMatrix4 planeRMatrix = GLKMatrix4Multiply(matrixTP, upose.rotationMatrix);
    
    iPose->rotationMatrix =GLKMatrix4Multiply(planeRMatrix, rotationMatrixT);
    
    //matrixTP = GLKMatrix4Identity;
    
    //iPose->position =GLKMatrix4MultiplyVector3(matrixTP, iPose->position);
     iPose->position = GLKMatrix4MultiplyVector3(planeRMatrix, iPose->position);
    //ecef
    
    [self computeInverseRotationMatrixFromPose:&upose];
    iPose->position = GLKMatrix4MultiplyVector3(inverseRotation_teM, iPose->position);
    iPose->ecef = GLKVector3Add(upose.ecef, iPose->position);
    
    
    
    
    
    //iPose->ecef = GLKMatrix4MultiplyVector3(transformMat, iPose->ecef);
    
    //positionTP = GLKMatrix4MultiplyVector3(matrixTP, positionTP);

    //positionTP = GLKMatrix4MultiplyVector3(inverseRotation_teM, positionTP);
 
    //iPose->ecef.x = upose.ecef.x + positionTP.x;
    //iPose->ecef.y = upose.ecef.y + positionTP.y;
    //iPose->ecef.z = upose.ecef.z + positionTP.z;
    
    //hacking iPose->position to store normal .. this is baaaad for readability but..
    //iPose->position.x = normal[0];
    //iPose->position.y = normal[0];
    //iPose->position.z = normal[0];
    
    //iPose->position = GLKMatrix4MultiplyVector3(transformMat, iPose->position);
   
}

- (GLKMatrix4) computeNormalTransformMatrix:(double*)normal
{
    
    //rotate camera onto plane
    GLKVector3 cameraNormal = GLKVector3Make(0.0,0.0, 1.0);
    GLKVector3 planeNormal = GLKVector3Make (normal[0], normal[1], normal[2]);
    
    planeNormal = GLKVector3Normalize(planeNormal);
    
    
    GLKVector3 axis = GLKVector3CrossProduct(cameraNormal, planeNormal);
    axis = GLKVector3Normalize(axis);
    float dotP = GLKVector3DotProduct(cameraNormal, planeNormal);
    
    float l1 = 1.0;
    float l2 = sqrtf(planeNormal.x *planeNormal.x + planeNormal.y * planeNormal.y + planeNormal.z*planeNormal.z);
    
    float angle = acosf(dotP/l1 * l2);
    
    bool invertible;
    
    GLKMatrix4 result =  GLKMatrix4MakeRotation(angle, axis.x,axis.y, axis.z);
    result = GLKMatrix4Invert(result, &invertible);
    
    return result;
    
    
}


@end


