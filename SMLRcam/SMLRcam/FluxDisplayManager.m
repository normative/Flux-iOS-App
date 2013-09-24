//
//  FluxDisplayManager.m
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDisplayManager.h"

@implementation FluxDisplayManager

- (id)init{
    self = [super init];
    if (self)
    {
        locationManager = [FluxLocationServicesSingleton sharedManager];
        [locationManager startLocating];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePlacemark:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateHeading:) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateLocation:) name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
    }
    
    return self;
}


-(void)didUpdatePlacemark:(NSNotification *)notification
{
    
}

- (void)didUpdateHeading:(NSNotification *)notification{
    //    CLLocationDirection heading = locationManager.heading;
    //    if (locationManager.location != nil) {
    //        ;
    //    }
}

- (void)didUpdateLocation:(NSNotification *)notification{
    self.locationsCoordinate = locationManager.location.coordinate;
}

@end
