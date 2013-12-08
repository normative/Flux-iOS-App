//
//  FluxFeatureMatchingTask.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingTask.h"
#define PI M_PI

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
        
        double rotation[9];
        double translation[3];
        if ([self.matcherEngine matchAndCalculateTransformsWithRotation:rotation withTranslation:translation] == 0)
        {
            self.matchRecord.ire.imageMetadata.userHomographyPose = self.matchRecord.cfe.cameraPose;
            
            sensorPose imagePose = self.matchRecord.ire.imageMetadata.imageHomographyPose;
            
            [self computeImagePoseInECEF:&imagePose
                                userPose: self.matchRecord.ire.imageMetadata.userHomographyPose
                            hTranslation: translation
                               hRotation: rotation];
            
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
            self.matchRecord.ire.imageMetadata.matchFailureTime = [NSDate date];
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
    
    lla_rad.x = sp->position.x*PI/180.0;
    lla_rad.y = sp->position.y*PI/180.0;
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



- (void) computeImagePoseInECEF:(sensorPose*)iPose userPose:(sensorPose)upose hTranslation:(double*)translation hRotation:(double *)rotation
{
    float rotation44[16];
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

    iPose->rotationMatrix = GLKMatrix4MakeWithArray(rotation44);

    //position
    
    [self computeInverseRotationMatrixFromPose:&upose];
    GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);

    positionTP.x = translation[0];
    positionTP.y = translation[1];
    positionTP.z = translation[2];
    positionTP = GLKMatrix4MultiplyVector3(inverseRotation_teM, positionTP);
 
    iPose->ecef.x = upose.ecef.x + positionTP.x;
    iPose->ecef.y = upose.ecef.y + positionTP.y;
    iPose->ecef.z = upose.ecef.z + positionTP.z;
    
   
}



@end


