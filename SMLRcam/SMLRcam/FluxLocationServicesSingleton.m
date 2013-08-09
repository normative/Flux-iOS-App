//
//  FluxLocationServicesSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-08.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxLocationServicesSingleton.h"

@implementation FluxLocationServicesSingleton

@synthesize delegate;

+ (id)sharedManager {
    static FluxLocationServicesSingleton *sharedFluxLocationServicesSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFluxLocationServicesSingleton = [[self alloc] init];
    });
    return sharedFluxLocationServicesSingleton;
}

- (id)init {
    if (self = [super init]) {
        
        // Create the manager object
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        
        // This is the most important property to set for the manager. It ultimately determines how the manager will
        // attempt to acquire location and thus, the amount of power that will be consumed.
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        
        // When "tracking" the user, the distance filter can be used to control the frequency with which location measurements
        // are delivered by the manager. If the change in distance is less than the filter, a location will not be delivered.
        locationManager.distanceFilter = kCLDistanceFilterNone;
        
        if ([CLLocationManager headingAvailable]) {
            locationManager.headingFilter = 5;
        }
    }
    return self;
}

- (void)startLocating{
    [locationManager startUpdatingLocation];
    
    if ([CLLocationManager headingAvailable]) {
        [locationManager startUpdatingHeading];
    }
}
- (void)endLocating{
    [locationManager stopUpdatingLocation];
    
    if ([CLLocationManager headingAvailable]) {
        [locationManager stopUpdatingHeading];
    }
}


#pragma mark - LocationManager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //set it to most recent for now
    self.location = [locations lastObject];
    
    if ([delegate respondsToSelector:@selector(LocationManager:didUpdateLocation:)]) {
        [delegate LocationManager:self didUpdateLocation:self.location];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    
    // Use the true heading if it is valid.
    self.heading = ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading);
    
    if ([delegate respondsToSelector:@selector(LocationManager:didUpdateHeading:)]) {
        [delegate LocationManager:self didUpdateHeading:self.heading];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    if ([error code] != kCLErrorLocationUnknown)
    {
        [self endLocating];
    }
}

@end



