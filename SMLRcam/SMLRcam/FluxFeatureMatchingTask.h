//
//  FluxFeatureMatchingTask.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxImageRenderElement.h"
#import "FluxMatcherWrapper.h"

@protocol FluxFeatureMatchingTaskDelegate;

@interface FluxFeatureMatchingTask : NSOperation

@property (nonatomic, strong) FluxImageRenderElement *imageRenderElementToMatch;
@property (nonatomic, strong) FluxMatcherWrapper *matcherEngine;
@property (nonatomic, assign) id <FluxFeatureMatchingTaskDelegate> delegate;

- (id)initWithImageRenderElement:(FluxImageRenderElement *)ire withMatcher:(FluxMatcherWrapper *)matcher
                        delegate:(id<FluxFeatureMatchingTaskDelegate>) theDelegate;

@end

@protocol FluxFeatureMatchingTaskDelegate <NSObject>

- (void)featureMatchingTaskDidFinish:(FluxFeatureMatchingTask *)featureMatchingTask;

@end