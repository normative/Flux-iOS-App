//
//  FluxMapImageObject.m
//  Flux
//
//  Created by Kei Turner on 2013-10-18.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMapImageObject.h"

@implementation FluxMapImageObject

- (NSString*)title
{
    return @"1 image";
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude = self.latitude;
    theCoordinate.longitude = self.longitude;
    
    return theCoordinate;
}

@end
