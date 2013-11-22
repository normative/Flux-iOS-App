//
//  FluxFeatureMatchingQueue.h
//  Flux
//
//  Created by Ryan Martens on 11/20/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxCameraFrameGrabTask.h"
#import "FluxFeatureMatchingTask.h"
#import "FluxMatcherWrapper.h"
#import "FluxImageRenderElement.h"
#import "PendingOperations.h"

@interface FluxFeatureMatchingQueue : NSObject <FluxFeatureMatchingTaskDelegate>
{
    FluxMatcherWrapper* fluxMatcherEngine;
}

@property (nonatomic, strong) PendingOperations *pendingOperations;

-(void)addMatchRequest:(FluxImageRenderElement *)ireToMatch;

@end
