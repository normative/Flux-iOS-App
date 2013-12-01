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
        
//        [self.matcherEngine matchFeatures];
        UIImage *testImage = [self.matcherEngine matchAndDrawFeatures];
        UIImageWriteToSavedPhotosAlbum(testImage, nil, nil, nil);

        // TODO: this does nothing yet until the IRE propagates back to the OpenGL VC
        self.matchRecord.ire.matched = YES;
        self.matchRecord.matched = YES;
        
        NSLog(@"Matching of localID %@ completed in %f seconds", self.matchRecord.ire.localID, [[NSDate date] timeIntervalSinceDate:startTime]);
        
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(featureMatchingTaskDidFinish:) withObject:self waitUntilDone:NO];
    }
}

@end

