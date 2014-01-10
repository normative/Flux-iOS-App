//
//  FluxUserLocationPin.m
//  Flux
//
//  Created by Kei Turner on 1/8/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxUserLocationPin.h"

@implementation FluxUserLocationPin

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self = [super init])
    {
        self.coordinate = coordinate;
    }
    
    return self;
}

@end
