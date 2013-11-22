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

- (void)addMatchRequest:(FluxImageRenderElement *)ireToMatch
{
    // Check to see if already feature match in progress. If so, ignore it.
    if (![self.pendingOperations.featureMatchingInProgress.allKeys containsObject:ireToMatch.localID])
    {
        FluxCameraFrameGrabTask *dependency;
        
        FluxFeatureMatchingRecord *matchRecord = [[FluxFeatureMatchingRecord alloc] init];
        matchRecord.ire = ireToMatch;
        
        // TODO: Check to see if the current frame is recent enough
        if (1)
        {
            // TODO: Find reference to current frame
            // matchRecord.cfe = New frame's cfe.
        }
        else if (0)
        {
            // TODO: If not, check to see if there are any current requests to add as a dependency
            // dependency = [self.pendingOperations.cameraFrameGrabInProgress objectForKey:some_key_to_reference_it];
            matchRecord.cfe = dependency.cameraRecord;
        }
        else
        {
            // If not, add a new request and add it as a dependency
            NSLog(@"Adding item to camera frame grab queue");
            FluxCameraFrameElement *newCfe = [[FluxCameraFrameElement alloc] init];
            FluxCameraFrameGrabTask *cameraFrameTask = [[FluxCameraFrameGrabTask alloc]
                                                        initWithCameraFrameRecord:newCfe withMatcher:fluxMatcherEngine delegate:self];
            
            dependency = cameraFrameTask;
            
            [self.pendingOperations.cameraFrameGrabInProgress setObject:cameraFrameTask forKey:newCfe.cameraRequestDate];
            [self.pendingOperations.cameraFrameGrabQueue addOperation:cameraFrameTask];
            
        }
        
        NSLog(@"Adding to queue local ID: %@", ireToMatch.localID);
        FluxFeatureMatchingTask *featureMatchingTask = [[FluxFeatureMatchingTask alloc] initWithFeatureMatchingRecord:matchRecord
                                                                                    withMatcher:fluxMatcherEngine delegate:self];
        
        if (dependency)
        {
            [featureMatchingTask addDependency:dependency];
        }
        [self.pendingOperations.featureMatchingInProgress setObject:featureMatchingTask forKey:ireToMatch.localID];
        [self.pendingOperations.featureMatchingQueue addOperation:featureMatchingTask];
    }
}

#pragma mark - FluxFeatureMatching Delegate

- (void)featureMatchingTaskDidFinish:(FluxFeatureMatchingTask *)featureMatcher
{
    FluxFeatureMatchingRecord *record = featureMatcher.matchRecord;
    [self.pendingOperations.featureMatchingInProgress removeObjectForKey:record.ire.localID];

    NSLog(@"Removing from queue local ID: %@", record.ire.localID);
}

#pragma mark - FluxCameraFrameGrab Delegate

- (void)cameraFrameGrabTaskDidFinish:(FluxCameraFrameGrabTask *)cameraFrameGrab
{
    FluxCameraFrameElement *record = cameraFrameGrab.cameraRecord;

    // TODO: update this once we know what key we used to add it
    [self.pendingOperations.cameraFrameGrabInProgress removeObjectForKey:record.cameraFrameDate];
    
    NSLog(@"Removing from camera frame grab queue request for date: %@", record.cameraFrameDate);
}

@end
