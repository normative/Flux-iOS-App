//
//  FluxCameraFrameGrabTask.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxCameraFrameGrabTask.h"


@implementation FluxCameraFrameGrabTask

@synthesize delegate = _delegate;

#pragma mark - Life Cycle

- (id)initWithFeatureMatchingRecord:(FluxFeatureMatchingRecord *)record withMatcher:(FluxMatcherWrapper *)matcher delegate:(id<FluxCameraFrameGrabTaskDelegate>)theDelegate
{
    if (self = [super init])
    {
        self.matchRecord = record;
        self.delegate = theDelegate;
        self.matcherEngine = matcher;
    }
    return self;
}

#pragma mark - Camera frame grab

- (void)main
{
    @autoreleasepool
    {
        if (self.isCancelled)
            return;
        
        // TODO: Grab current camera frame
        
        NSLog(@"Grabbing current camera frame");
        
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(cameraFrameGrabTaskDidFinish:) withObject:self waitUntilDone:NO];
    }
}

@end


