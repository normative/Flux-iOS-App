//
//  FluxFeatureMatchingTask.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingTask.h"
#import "FluxTransformUtilities.h"

// Time interval after which to retry feature matching

// If homography fails, it means we had good correspondence with features, but no valid matched box
const double retryTimeIfInvalidHomographyIfDisplayed = 1.5;
const double retryTimeIfInvalidHomographyIfNotDisplayed = 5.0;
// If feature matching fails, it means we likely don't have the same features in the current FOV
const double retryTimeIfInvalidMatchIfDisplayed = 3.0;
const double retryTimeIfInvalidMatchIfNotDisplayed = 5.0;

//enum {SOLUTION1 = 0, SOLUTION2, SOLUTION1Neg, SOLUTION2Neg};


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
        [self.matcherEngine setObjectImage:self.matchRecord.objectImageCacheObject.image];
        
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
                                                                  withDebugImage:self.matchRecord.outputDebugImages //Debugging of images
                                                                     withImageID:self.matchRecord.ire.imageMetadata.imageID];
            
            if (feature_matching_success == result)
            {
                
                self.matchRecord.ire.imageMetadata.userHomographyPose = self.matchRecord.cfe.cameraPose;
                
                sensorPose imagePosePnP = self.matchRecord.ire.imageMetadata.imageHomographyPosePnP;
                sensorPose uhPose = self.matchRecord.ire.imageMetadata.userHomographyPose;

//                [self computeImagePoseInECEF:&imagePosePnP
                [FluxTransformUtilities computeImagePoseInECEF: &imagePosePnP
                                                      userPose: &uhPose
                                                 hTranslation1: translation1
                                                    hRotation1: rotation1
                                                      hNormal1: normal1
                                                 hTranslation2: translation1
                                                    hRotation2: rotation1
                                                      hNormal2: normal1];
                
                self.matchRecord.ire.imageMetadata.imageHomographyPosePnP = imagePosePnP;

                // store R & t for later use with image-to-image feature matching
                [FluxTransformUtilities deepCopyDoubleTo:self.matchRecord.ire.imageMetadata.matchTransform.rotation fromDoubleArray:rotation1 withSize:9];
                [FluxTransformUtilities deepCopyDoubleTo:self.matchRecord.ire.imageMetadata.matchTransform.translation fromDoubleArray:translation1 withSize:3];

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

@end


