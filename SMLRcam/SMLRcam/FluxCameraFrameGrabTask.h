//
//  FluxCameraFrameGrabTask.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxCameraFrameElement.h"
#import "FluxMatcherWrapper.h"

@class FluxOpenGLViewController;

@protocol FluxCameraFrameGrabTaskDelegate;

@interface FluxCameraFrameGrabTask : NSOperation

@property (nonatomic, strong) FluxCameraFrameElement *cameraRecord;
@property (nonatomic, strong) FluxMatcherWrapper *matcherEngine;
@property (nonatomic, assign) id <FluxCameraFrameGrabTaskDelegate> delegate;
@property (nonatomic, weak) FluxOpenGLViewController *openGLVC;

- (id)initWithCameraFrameRecord:(FluxCameraFrameElement *)record withMatcher:(FluxMatcherWrapper *)matcher
                           delegate:(id<FluxCameraFrameGrabTaskDelegate>) theDelegate
                           withOpenGLVC:(FluxOpenGLViewController *)openGLview;

@end

@protocol FluxCameraFrameGrabTaskDelegate <NSObject>

- (void)cameraFrameGrabTaskDidFinish:(FluxCameraFrameGrabTask *)cameraFrameGrabTask;
- (void)cameraFrameGrabTaskWasCancelled:(FluxCameraFrameGrabTask *)cameraFrameGrabTask;

@end