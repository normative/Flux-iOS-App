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
#import "FluxDisplayManager.h"


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

- (void)testMatchingRoutine
{
    double rotation[9];
    double translation[3];
    
    NSString *fileLocation1 = [[NSBundle mainBundle] pathForResource:@"photo_match_2" ofType:@"jpeg"];
    UIImage* matchImage1 = [[UIImage alloc] initWithContentsOfFile:fileLocation1];
    NSString *fileLocation2 = [[NSBundle mainBundle] pathForResource:@"photo_match_1" ofType:@"jpeg"];
    UIImage* matchImage2 = [[UIImage alloc] initWithContentsOfFile:fileLocation2];

    [fluxMatcherEngine setObjectImage:matchImage1];
    [fluxMatcherEngine setSceneImageNoOrientationChange:matchImage2];

    UIImage *test = [fluxMatcherEngine matchAndDrawFeatures];
    UIImageWriteToSavedPhotosAlbum(test, nil, nil, nil);
    
    if ([fluxMatcherEngine matchAndCalculateTransformsWithRotation:rotation withTranslation:translation withDebugImage:NO] == 0)
    {
    }
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

    if (record.matched)
    {
        // Send notification to trigger new data to trickle into OpenGL View Controller
        NSDictionary *userInfoDict = @{@"matchedLocalID" : record.ire.localID, @"matchedImageObject" : record.ire.imageMetadata};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidMatchImage object:self userInfo:userInfoDict];
    }
    
    [self.pendingOperations.featureMatchingInProgress removeObjectForKey:record.ire.localID];
}

#pragma mark - FluxCameraFrameGrab Delegate

- (void)cameraFrameGrabTaskDidFinish:(FluxCameraFrameGrabTask *)cameraFrameGrab
{
    // Don't need to do anything. Leave it in the array so that feature matching tasks can use it.
    // Another will eventually delete it from pendingOperations.cameraFrameGrabInProgress once no one is using it.
}

@end
