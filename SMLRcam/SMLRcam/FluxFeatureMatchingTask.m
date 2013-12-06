//
//  FluxFeatureMatchingTask.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingTask.h"


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
            for (int i=0; i<3; i++)
            {
                self.matchRecord.ire.imageMetadata.imageHomographyPose.translation[i] = translation[i];
            }
            for (int i=0; i<9; i++)
            {
                self.matchRecord.ire.imageMetadata.imageHomographyPose.rotation[i] = rotation[i];
            }
            
            // Convert camera pose in WGS-84 coordinate system into camera pose in local tangent plane at time of frame capture
            self.matchRecord.ire.imageMetadata.userHomographyPose.translation[0] = self.matchRecord.cfe.cameraPose.position.x;
            self.matchRecord.ire.imageMetadata.userHomographyPose.translation[1] = self.matchRecord.cfe.cameraPose.position.y;
            self.matchRecord.ire.imageMetadata.userHomographyPose.translation[2] = self.matchRecord.cfe.cameraPose.position.z;
        
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

@end


