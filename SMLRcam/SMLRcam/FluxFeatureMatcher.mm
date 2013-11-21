//
//  FluxFeatureMatcher.m
//  Flux
//
//  Created by Ryan Martens on 11/20/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatcher.h"

@implementation FluxFeatureMatcher

- (id)init
{
    if (self = [super init])
    {
        fluxMatcher = [[FluxMatcherWrapper alloc] init];
    }
    
    return self;
}

@end
