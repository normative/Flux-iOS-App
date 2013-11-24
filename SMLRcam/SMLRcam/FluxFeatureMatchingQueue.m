//
//  FluxFeatureMatchingQueue.m
//  Flux
//
//  Created by Ryan Martens on 11/20/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingQueue.h"
#import "FluxCameraFrameElement.h"
#import "FluxFeatureMatchingRecord.h"

#import "FluxOpenGLViewController.h"


@implementation FluxFeatureMatchingQueue

@synthesize pendingOperations = _pendingOperations;

- (PendingOperations *)pendingOperations
{
    if (!_pendingOperations)
    {
        _pendingOperations = [[PendingOperations alloc] init];
    }
    return _pendingOperations;
}

- (id)init
{
    if (self = [super init])
    {
        fluxMatcherEngine = [[FluxMatcherWrapper alloc] init];
    }

    return self;
}

- (void)addMatchRequest:(FluxImageRenderElement *)ireToMatch withOpenGLVC:(FluxOpenGLViewController *)openGLview
{
    // Check to see if already feature match in progress. If so, ignore it.
    if (![self.pendingOperations.featureMatchingInProgress.allKeys containsObject:ireToMatch.localID])
    {
        FluxCameraFrameGrabTask *dependency;
        
        FluxFeatureMatchingRecord *matchRecord = [[FluxFeatureMatchingRecord alloc] init];
        matchRecord.ire = ireToMatch;
        
        // Check to see if there is a current frame that is recent enough
        // Note we use request date rather than frame date, since pending requests don't have a frame date yet.
        // Should be close enough, given the frame rate of the preview.
        NSDate *recentDate = [[[self.pendingOperations.cameraFrameGrabInProgress allKeys] sortedArrayUsingSelector:@selector(compare:)] lastObject];

        // Find reference to most recent frame, if one exists
        if (recentDate && ([recentDate timeIntervalSinceNow] > -3.0))
        {
            dependency = [self.pendingOperations.cameraFrameGrabInProgress objectForKey:recentDate];
            matchRecord.cfe = dependency.cameraRecord;
            
            // Check if dependency is completed already or not (since we keep them in the queue until not used any more)
            if ([dependency isFinished])
            {
                dependency = nil;
            }
        }
        else
        {
            // If not, add a new request and add it as a dependency
            FluxCameraFrameElement *newCfe = [[FluxCameraFrameElement alloc] init];
            FluxCameraFrameGrabTask *cameraFrameTask = [[FluxCameraFrameGrabTask alloc]
                                                        initWithCameraFrameRecord:newCfe
                                                        withMatcher:fluxMatcherEngine
                                                        delegate:self
                                                        withOpenGLVC:openGLview];
            
            dependency = cameraFrameTask;
            matchRecord.cfe = dependency.cameraRecord;
            
            [self.pendingOperations.cameraFrameGrabInProgress setObject:cameraFrameTask forKey:newCfe.cameraRequestDate];
            [self.pendingOperations.cameraFrameGrabQueue addOperation:cameraFrameTask];
        }
        
        FluxFeatureMatchingTask *featureMatchingTask = [[FluxFeatureMatchingTask alloc] initWithFeatureMatchingRecord:matchRecord
                                                                                    withMatcher:fluxMatcherEngine delegate:self];
        
        if (dependency)
        {
            [featureMatchingTask addDependency:dependency];
        }
        
        [self.pendingOperations.featureMatchingInProgress setObject:featureMatchingTask forKey:ireToMatch.localID];
        [self.pendingOperations.featureMatchingQueue addOperation:featureMatchingTask];
        
        // Clean up at end. Need to make sure that at least one featureMatchingTask references the camera task
        // before we attempt to clean up, so we don't delete it prematurely
        [self.pendingOperations cleanUpUnusedCameraFrames];
    }
}

#pragma mark - FluxFeatureMatching Delegate

- (void)featureMatchingTaskDidFinish:(FluxFeatureMatchingTask *)featureMatcher
{
    FluxFeatureMatchingRecord *record = featureMatcher.matchRecord;
    [self.pendingOperations.featureMatchingInProgress removeObjectForKey:record.ire.localID];
}

#pragma mark - FluxCameraFrameGrab Delegate

- (void)cameraFrameGrabTaskDidFinish:(FluxCameraFrameGrabTask *)cameraFrameGrab
{
    // Don't need to do anything. Leave it in the array so that feature matching tasks can use it.
    // Another will eventually delete it from pendingOperations.cameraFrameGrabInProgress once no one is using it.
}

@end
