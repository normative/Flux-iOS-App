//
//  PendingOperations.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "PendingOperations.h"
#import "FluxFeatureMatchingTask.h"
#import "FluxCameraFrameGrabTask.h"

@implementation PendingOperations

@synthesize featureMatchingInProgress = _featureMatchingInProgress;
@synthesize featureMatchingQueue = _featureMatchingQueue;
@synthesize cameraFrameGrabInProgress = _cameraFrameGrabInProgress;
@synthesize cameraFrameGrabQueue = _cameraFrameGrabQueue;

- (NSMutableDictionary *)featureMatchingInProgress
{
    if (!_featureMatchingInProgress)
    {
        _featureMatchingInProgress = [[NSMutableDictionary alloc] init];
    }
    
    return _featureMatchingInProgress;
}

- (NSOperationQueue *)featureMatchingQueue
{
    if (!_featureMatchingQueue)
    {
        _featureMatchingQueue = [[NSOperationQueue alloc] init];
        _featureMatchingQueue.name = @"Feature Matching Queue";
        _featureMatchingQueue.maxConcurrentOperationCount = 1;
    }
    
    return _featureMatchingQueue;
}

- (NSMutableDictionary *)cameraFrameGrabInProgress
{
    if (!_cameraFrameGrabInProgress)
    {
        _cameraFrameGrabInProgress = [[NSMutableDictionary alloc] init];
    }
    
    return _cameraFrameGrabInProgress;
}

- (NSOperationQueue *)cameraFrameGrabQueue
{
    if (!_cameraFrameGrabQueue)
    {
        _cameraFrameGrabQueue = [[NSOperationQueue alloc] init];
        _cameraFrameGrabQueue.name = @"Camera Frame Grab Queue";
        _cameraFrameGrabQueue.maxConcurrentOperationCount = 1;
    }
    
    return _cameraFrameGrabQueue;
}

- (void)cleanUpUnusedCameraFrames
{
    // Get a list of all pending request dates
    NSMutableArray *currentRequestDates = [[NSMutableArray alloc] init];
    
    for (id key in _featureMatchingInProgress)
    {
        FluxFeatureMatchingTask *curTask = _featureMatchingInProgress[key];
        [currentRequestDates addObject:curTask.matchRecord.cfe.cameraRequestDate];
    }
    
    // Examine current camera frame requests. If no longer used get rid of it.
    NSMutableArray *toDeleteList = [[NSMutableArray alloc] init];
    for (id key in _cameraFrameGrabInProgress)
    {
        FluxCameraFrameGrabTask *curTask = _cameraFrameGrabInProgress[key];
        NSDate *curRequestDate = curTask.cameraRecord.cameraRequestDate;
        if (curRequestDate && ![currentRequestDates containsObject:curRequestDate])
        {
            // Remove from list
            [toDeleteList addObject:curRequestDate];
        }
    }
    
    // Actually delete here
    [_cameraFrameGrabInProgress removeObjectsForKeys:toDeleteList];
}

- (void)signalWaitingCameraTasks
{
    for (id key in _cameraFrameGrabInProgress)
    {
        FluxCameraFrameGrabTask *curTask = _cameraFrameGrabInProgress[key];
        if (!curTask.isFinished)
        {
            // Signal in case it is waiting for a new frame that won't come
            [curTask.cameraRecord.frameReadyCondition lock];
            [curTask.cameraRecord.frameReadyCondition signal];
            [curTask.cameraRecord.frameReadyCondition unlock];
        }
    }
}

@end
