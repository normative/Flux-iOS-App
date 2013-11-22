//
//  FluxCameraFrameGrabTask.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxFeatureMatchingRecord.h"
#import "FluxMatcherWrapper.h"

@protocol FluxCameraFrameGrabTaskDelegate;

@interface FluxCameraFrameGrabTask : NSOperation

@property (nonatomic, strong) FluxFeatureMatchingRecord *matchRecord;
@property (nonatomic, strong) FluxMatcherWrapper *matcherEngine;
@property (nonatomic, assign) id <FluxCameraFrameGrabTaskDelegate> delegate;

- (id)initWithFeatureMatchingRecord:(FluxFeatureMatchingRecord *)record withMatcher:(FluxMatcherWrapper *)matcher
                           delegate:(id<FluxCameraFrameGrabTaskDelegate>) theDelegate;

@end

@protocol FluxCameraFrameGrabTaskDelegate <NSObject>

- (void)cameraFramgeGrabTaskDidFinish:(FluxCameraFrameGrabTask *)cameraFrameGrabTask;

@end