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
const double retryTimeIfInvalidHomography = 2.0;
// If feature matching fails, it means we likely don't have the same features in the current FOV
const double retryTimeIfInvalidMatch = 10.0;

enum {SOLUTION1 =0, SOLUTION2};


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
        if (self.isCancelled)
            return;

        NSDate *startTime = [NSDate date];
        
        NSLog(@"Matching localID: %@", self.matchRecord.ire.localID);
        
        // Make sure camera frame (scene) and object are both available
        if (!self.matchRecord.hasCameraScene || !self.matchRecord.hasObjectImage)
        {
            self.matchRecord.failed = YES;
            return;
        }
        
        [self.matcherEngine setObjectImage:self.matchRecord.ire.image];
        [self.matcherEngine setSceneImage:self.matchRecord.cfe.cameraFrameImage];
        
        double rotation1[9];
        double translation1[3];
        double normal1[3];
        double rotation2[9];
        double translation2[3];
        double normal2[3];
        
        int result = [self.matcherEngine matchAndCalculateTransformsWithRotationSoln1:rotation1
                                                                 withTranslationSoln1:translation1
                                                                      withNormalSoln1:normal1
                                                                    withRotationSoln2:rotation2
                                                                 withTranslationSoln2:translation2
                                                                      withNormalSoln2:normal2
                                                                       withDebugImage:NO];
        
        if (feature_matching_success == result)
        {
            self.matchRecord.ire.imageMetadata.userHomographyPose = self.matchRecord.cfe.cameraPose;
            
            sensorPose imagePose = self.matchRecord.ire.imageMetadata.imageHomographyPose;
            
            [self computeImagePoseInECEF:&imagePose
                                userPose: self.matchRecord.ire.imageMetadata.userHomographyPose
                            hTranslation1: translation1
                              hRotation1: rotation1
                                hNormal1: normal1
                           hTranslation2:translation2
                              hRotation2:rotation2
                                hNormal2:normal2];
            
            self.matchRecord.ire.imageMetadata.imageHomographyPose = imagePose;
            
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
            
            // Set the next retry time (depends if homography or match failure)
            self.matchRecord.ire.imageMetadata.matchFailureRetryTime = [NSDate dateWithTimeIntervalSinceNow:
                    ((feature_matching_homography_error == result) ? retryTimeIfInvalidHomography : retryTimeIfInvalidMatch)];
        }
        
        NSLog(@"Matching of localID %@ completed in %f seconds", self.matchRecord.ire.localID, [[NSDate date] timeIntervalSinceDate:startTime]);
        
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
    double dotProduct1 = planeNormal.x * normal1[0] + planeNormal.y * normal1[1] + planeNormal.z * normal1[2];
    double dotProduct2 = planeNormal.x * normal2[0] + planeNormal.y * normal2[1] + planeNormal.z * normal2[2];
    
    return (dotProduct1 > dotProduct2) ? SOLUTION1:SOLUTION2;
}


- (void) computeImagePoseInECEF:(sensorPose*)iPose userPose:(sensorPose)upose hTranslation1:(double*)translation1 hRotation1:(double *)rotation1 hNormal1:(double *)normal1 hTranslation2:(double*)translation2 hRotation2:(double *)rotation2 hNormal2:(double *)normal2
{
    float rotation44[16];
    
    double rotation[9];
    double translation[3];
    int solution = 0;
    int i;
    
    GLKMatrix4 matrixTP1 = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    GLKMatrix4 planeRMatrix = GLKMatrix4Multiply(matrixTP1, upose.rotationMatrix);
    //normal plane
    GLKVector3 planeNormalI = GLKVector3Make(0.0, 0.0, 1.0);
    GLKVector3 planeNormalRotated =GLKMatrix4MultiplyVector3(planeRMatrix, planeNormalI);

    solution = [self solutionBasedOnNormalWithNormal1:normal1
                                          withNormal2:normal2
                                      withPlaneNormal:planeNormalRotated];
    
    if(solution ==SOLUTION1)
    {
        for(i=0; i<9;  i++)
            rotation[i] = rotation1[i];
    
        for(i=0; i<3; i++)
            translation[i] = translation1[i];
    }
    else
    {
        for(i=0; i<9;  i++)
            rotation[i] = rotation2[i];
        
        for(i=0; i<3; i++)
            translation[i] = translation2[i];
    }
    
    //rotation
    rotation44[0] = rotation[0];
    rotation44[1] = -1.0 * rotation[1];
    rotation44[2] = -1.0 * rotation[2];
    rotation44[3]= 0.0;
    rotation44[4] = -1.0 * rotation[3];
    rotation44[5] = rotation[4];
    rotation44[6] = rotation[5];
    rotation44[7]= 0.0;
    rotation44[8] = -1.0 *rotation[6];
    rotation44[9] = rotation[7];
    rotation44[10] = rotation[8];
    rotation44[11]= 0.0;
    rotation44[12]= 0.0;
    rotation44[13]= 0.0;
    rotation44[14]= 0.0;
    rotation44[15]= 1.0;
    GLKMatrix4 rotmat1;
    GLKMatrix4 tmprotMatrix;
    GLKMatrix4 rotmat;
    
    rotmat1 = GLKMatrix4MakeWithArray(rotation44);
    GLKMatrix4 transformMat = GLKMatrix4MakeRotation(0.0, 1.0, 0.0, 0.0);
    
    rotmat = GLKMatrix4Multiply(transformMat, rotmat1);
    
    
    tmprotMatrix = GLKMatrix4Multiply(rotmat, upose.rotationMatrix);
    GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
   iPose->rotationMatrix =  GLKMatrix4Multiply(matrixTP, tmprotMatrix);
    
    [self computeInverseRotationMatrixFromPose:&upose];
    GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);

    positionTP.x = translation[0];
    positionTP.y = -1.0 *translation[1];
    positionTP.z = -1.0 * translation[2];
    
    //positionTP = GLKMatrix4MultiplyVector3(transformMat, positionTP);
    
//    positionTP = GLKMatrix4MultiplyVector3(matrixTPYZ, positionTP);
    positionTP = GLKMatrix4MultiplyVector3(inverseRotation_teM, positionTP);
 
    iPose->ecef.x = upose.ecef.x + positionTP.x;
    iPose->ecef.y = upose.ecef.y + positionTP.y;
    iPose->ecef.z = upose.ecef.z + positionTP.z;
    
   
}



@end


