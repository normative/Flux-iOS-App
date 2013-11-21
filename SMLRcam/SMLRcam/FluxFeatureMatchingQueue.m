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
//    NSIndexPath *indexPath = featureMatcher.indexPathInTableView;
//    MatchRecord *theRecord = featureMatcher.matchRecord;

    FluxImageRenderElement *ire = featureMatcher.imageRenderElementToMatch;
    [self.pendingOperations.featureMatchingInProgress removeObjectForKey:ire.localID];

    NSLog(@"Removing from queue local ID: %@", ire.localID);
}

@end
