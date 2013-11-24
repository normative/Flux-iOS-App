//
//  FluxCameraFrameElement.m
//  Flux
//
//  Created by Ryan Martens on 11/22/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxCameraFrameElement.h"

@implementation FluxCameraFrameElement

- (id)init
{
    if (self = [super init])
    {
        _cameraRequestDate = [NSDate date];
        _frameRequested = YES;
        _frameReady = NO;
        _frameReadyCondition = [[NSCondition alloc] init];
    }
    return self;
}

@end
