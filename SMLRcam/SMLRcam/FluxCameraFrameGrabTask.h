//
//  FluxCameraFrameGrabTask.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxMatcherWrapper.h"

@protocol FluxCameraFrameGrabTaskDelegate;

@interface FluxCameraFrameGrabTask : NSOperation

@property (nonatomic, strong) NSDate *frameDate;
@property (nonatomic, strong) FluxMatcherWrapper *matcherEngine;
@property (nonatomic, assign) id <FluxCameraFrameGrabTaskDelegate> delegate;

- (id)initWithDate:(NSDate *)frameDate withMatcher:(FluxMatcherWrapper *)matcher
          delegate:(id<FluxCameraFrameGrabTaskDelegate>) theDelegate;

@end

@protocol FluxCameraFrameGrabTaskDelegate <NSObject>

- (void)cameraFramgeGrabTaskDidFinish:(FluxCameraFrameGrabTask *)cameraFrameGrabTask;

@end