//
//  FluxTimeSegment.m
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxTimeSegment.h"

@implementation FluxTimeSegment

- (id)initWithType:(timeSegment_type)type andSegments:(NSArray*)segments{
    self = [super init];
    if (self)
    {
        self.timeSegment_type = type;
        self.timeSegments = segments;
    }
    return self;
}

@end
