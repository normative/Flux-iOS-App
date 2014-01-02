//
//  FluxCameraFrameGrabTask.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxCameraFrameGrabTask.h"
#import "FluxOpenGLViewController.h"


@implementation FluxCameraFrameGrabTask

@synthesize delegate = _delegate;

#pragma mark - Life Cycle

- (id)initWithCameraFrameRecord:(FluxCameraFrameElement *)record withMatcher:(FluxMatcherWrapper *)matcher
                        delegate:(id<FluxCameraFrameGrabTaskDelegate>)theDelegate
                        withOpenGLVC:(FluxOpenGLViewController *)openGLview
{
    if (self = [super init])
    {
        self.cameraRecord = record;
        self.delegate = theDelegate;
        self.matcherEngine = matcher;
        self.openGLVC = openGLview;
    }
    return self;
}

#pragma mark - Camera frame grab

- (void)main
{
    @autoreleasepool
    {
        if (self.isCancelled)
        {
            [(NSObject *)self.delegate performSelectorOnMainThread:@selector(cameraFrameGrabTaskWasCancelled::) withObject:self waitUntilDone:NO];
            return;
        }
        
        if (self.openGLVC)
        {
            // Lock before call to make sure that signal is not missed
            // But make sure we unlock quickly to prevent locking up camera preview!
            [self.cameraRecord.frameReadyCondition lock];

            // Make call to grab next camera frame
            [self.openGLVC requestCameraFrame:self.cameraRecord];

            // Wait for signal
            while (!self.cameraRecord.frameReady)
            {
                [self.cameraRecord.frameReadyCondition wait];
            }
            [self.cameraRecord.frameReadyCondition unlock];

            [(NSObject *)self.delegate performSelectorOnMainThread:@selector(cameraFrameGrabTaskDidFinish:) withObject:self waitUntilDone:NO];
        }
    }
}

@end


