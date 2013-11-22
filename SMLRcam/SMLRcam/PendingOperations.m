//
//  PendingOperations.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "PendingOperations.h"

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
@end
