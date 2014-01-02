//
//  FluxFeatureMatchingTask.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxFeatureMatchingRecord.h"
#import "FluxMatcherWrapper.h"

@protocol FluxFeatureMatchingTaskDelegate;

@interface FluxFeatureMatchingTask : NSOperation{
    GLKMatrix4 inverseRotation_teM;
}

@property (nonatomic, strong) FluxFeatureMatchingRecord *matchRecord;
@property (nonatomic, strong) FluxMatcherWrapper *matcherEngine;
@property (nonatomic, assign) id <FluxFeatureMatchingTaskDelegate> delegate;

- (id)initWithFeatureMatchingRecord:(FluxFeatureMatchingRecord *)record withMatcher:(FluxMatcherWrapper *)matcher
                        delegate:(id<FluxFeatureMatchingTaskDelegate>) theDelegate;

@end

@protocol FluxFeatureMatchingTaskDelegate <NSObject>

- (void)featureMatchingTaskDidFinish:(FluxFeatureMatchingTask *)featureMatchingTask;
- (void)featureMatchingTaskWasCancelled:(FluxFeatureMatchingTask *)featureMatchingTask;

@end