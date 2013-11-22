//
//  FluxFeatureMatchingQueue.m
//  Flux
//
//  Created by Ryan Martens on 11/20/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingQueue.h"

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
        // TODO: Check to see if the current frame is recent enough
        
        // TODO: If not, check to see if there are any current requests to add as a dependency
        
        // TODO: If not, add a new request and add it as a dependency
        
        NSLog(@"Adding to queue local ID: %@", ireToMatch.localID);
        FluxFeatureMatchingTask *featureMatchingTask = [[FluxFeatureMatchingTask alloc] initWithImageRenderElement:ireToMatch
                                                                                    withMatcher:fluxMatcherEngine delegate:self];
        
        [self.pendingOperations.featureMatchingInProgress setObject:featureMatchingTask forKey:ireToMatch.localID];
        [self.pendingOperations.featureMatchingQueue addOperation:featureMatchingTask];
    }
}

#pragma mark - FluxFeatureMatching Delegate

- (void)featureMatchingTaskDidFinish:(FluxFeatureMatchingTask *)featureMatcher
{
    FluxImageRenderElement *ire = featureMatcher.imageRenderElementToMatch;
    [self.pendingOperations.featureMatchingInProgress removeObjectForKey:ire.localID];

    NSLog(@"Removing from queue local ID: %@", ire.localID);
}

#pragma mark - FluxCameraFrameGrab Delegate

- (void)cameraFrameGrabTaskDidFinish:(FluxCameraFrameGrabTask *)cameraFrameGrab
{
    NSDate *frameDate = cameraFrameGrab.frameDate;
    [self.pendingOperations.cameraFrameGrabInProgress removeObjectForKey:frameDate];
    
    NSLog(@"Removing from camera frame grab queue request for date: %@", frameDate);
}

@end
