//
//  FluxFeatureMatchingQueue.m
//  Flux
//
//  Created by Ryan Martens on 11/20/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingQueue.h"

@implementation FluxFeatureMatchingQueue

- (id)init
{
    if (self = [super init])
    {
        fluxFeatureMatcher = [[FluxFeatureMatcher alloc] init];
    }

    return self;
}

@end
