//
//  FluxLocationServicesSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-08.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxLocationServicesSingleton.h"

NSString* const FluxLocationServicesSingletonDidUpdateLocation = @"FluxLocationServicesSingletonDidUpdateLocation";
NSString* const FluxLocationServicesSingletonDidUpdateHeading = @"FluxLocationServicesSingletonDidUpdateHeading";
NSString* const FluxLocationServicesSingletonDidUpdatePlacemark = @"FluxLocationServicesSingletonDidUpdatePlacemark";

@implementation FluxLocationServicesSingleton

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
        if (locationManager == nil)
        {
            return nil;
        }
        locationManager.delegate = self;
        
        // This is the most important property to set for the manager. It ultimately determines how the manager will
        // attempt to acquire location and thus, the amount of power that will be consumed.
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        
        // When "tracking" the user, the distance filter can be used to control the frequency with which location measurements
        // are delivered by the manager. If the change in distance is less than the filter, a location will not be delivered.
        locationManager.distanceFilter = kCLDistanceFilterNone;
        
        // This will drain battery faster, but for now, we want to make sure that we continue to get frequent updates
        locationManager.pausesLocationUpdatesAutomatically = NO;
        
        locationMeasurements = [[NSMutableArray alloc] init];
        
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
    else {
        NSLog(@"No Heading Information Available");
    }
}
- (void)endLocating{
#warning Don't stop updating location now. Need to keep reference count to figure out when to disable.
    return;
    
    [locationManager stopUpdatingLocation];
    
    if ([CLLocationManager headingAvailable]) {
        [locationManager stopUpdatingHeading];
    }
}


#pragma mark - LocationManager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocations{
    // Grab last entry for now, since we should be getting all of them
    if ([newLocations count] > 1)
    {
        NSLog(@"Received more than one location (%d)", [newLocations count]);
    }
    CLLocation *newLocation = [newLocations lastObject];

    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0)
    {
        NSLog(@"Invalid measurement (horizontalAccuracy=%f)",newLocation.horizontalAccuracy);
        return;
    }
    
    // test that the vertical accuracy does not indicate an invalid measurement
    if (newLocation.verticalAccuracy < 0)
    {
        NSLog(@"Invalid measurement (verticalAccuracy=%f)",newLocation.verticalAccuracy);
        return;
    }
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0)
    {
        NSLog(@"location age too old (%f)",locationAge);
        return;
    }
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    //NSLog(@"Adding new location  with date: %@ \nAnd Location: %0.15f, %0.15f, %f +/- %f (h), %f (v)",
    //      [dateFormat stringFromDate:newLocation.timestamp], newLocation.coordinate.latitude, newLocation.coordinate.longitude,
    //      newLocation.altitude, newLocation.horizontalAccuracy, newLocation.verticalAccuracy);
    
    // store all of the measurements, just so we can see what kind of data we might receive
    [locationMeasurements addObject:newLocation];
    
    // truncate data to maximum size of window (i.e. 5 locations)
    while ([locationMeasurements count] > 5)
    {
        [locationMeasurements removeObjectAtIndex:0];
    }
    
    const double weight_time = 0.5;
    const double weight_accuracy = 0.5;
    
    double corrected_lat = 0.0;
    double corrected_long = 0.0;
    
    NSMutableArray *weights = [[NSMutableArray alloc] initWithCapacity:[locationMeasurements count]];
    CLLocation *temp_location;
    
    NSDate *min_date = [locationMeasurements valueForKeyPath:@"@min.timestamp"];
    NSDate *max_date = [locationMeasurements valueForKeyPath:@"@max.timestamp"];
    NSNumber *min_accuracy = [locationMeasurements valueForKeyPath:@"@min.horizontalAccuracy"];
    NSNumber *max_accuracy = [locationMeasurements valueForKeyPath:@"@max.horizontalAccuracy"];
    //NSLog(@"Min/max times: %@ - %@", [dateFormat stringFromDate:min_date], [dateFormat stringFromDate:max_date]);
    //NSLog(@"Min/max accuracy: %f - %f", [min_accuracy doubleValue], [max_accuracy doubleValue]);
    
    for (int i = 0; i < [locationMeasurements count]; i++) {
        temp_location = [locationMeasurements objectAtIndex:i];
        double time_component = ([max_date timeIntervalSinceDate:min_date] > 0) ?
        ([temp_location.timestamp timeIntervalSinceDate:min_date] /
         [max_date timeIntervalSinceDate:min_date])
        : 1.0;
        double accuracy_component = (([max_accuracy doubleValue] - [min_accuracy doubleValue]) > 0) ?
        (1.0 - ((temp_location.horizontalAccuracy - [min_accuracy doubleValue]) /
                ([max_accuracy doubleValue] - [min_accuracy doubleValue])))
        : 1.0;
        
        double final_weight = (weight_time*time_component) + (weight_accuracy*accuracy_component);
        
        //NSLog(@"%f, %f, %f, %f, %f", time_component, accuracy_component, final_weight,
        //      temp_location.coordinate.latitude, temp_location.coordinate.longitude);
        weights[i] = [NSNumber numberWithDouble:final_weight];
        
        corrected_lat += final_weight * temp_location.coordinate.latitude;
        corrected_long += final_weight * temp_location.coordinate.longitude;
    }
    
    NSNumber *weight_sum = [weights valueForKeyPath:@"@sum.self"];
    if ([weight_sum doubleValue] <= 0.0)
    {
        // we should never get here based on the above logic
        NSLog(@"Zero or negative value for weight factor (%@)", weight_sum);
        return;
    }
    
    corrected_lat /= [weight_sum doubleValue];
    corrected_long /= [weight_sum doubleValue];
    
    // Update the public location information for consumption
    temp_location = [locationMeasurements lastObject];
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(corrected_lat, corrected_long);
    self.location = [[CLLocation alloc] initWithCoordinate:coord altitude:temp_location.altitude horizontalAccuracy:temp_location.horizontalAccuracy verticalAccuracy:temp_location.verticalAccuracy course:temp_location.course speed:temp_location.speed timestamp:temp_location.timestamp];
    
    //NSLog(@"Saved lat/long: %0.15f, %0.15f", self.location.coordinate.latitude,
    //      self.location.coordinate.longitude);

    // Notify observers of updated position
    if (self.location != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdateLocation object:self];
        [self reverseGeocodeLocation:self.location];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading.headingAccuracy < 0)
        return;
    // Use the true heading if it is valid.
    self.heading = ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading);
    
    // Notify observers of updated heading, if we have a valid heading
    // Since heading is a double, assume that we only have a valid heading if we have a location
    if (self.location != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdateHeading object:self];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    if ([error code] != kCLErrorLocationUnknown)
    {
        [self endLocating];
    }
}

#pragma mark - location geocoding
- (void)reverseGeocodeLocation:(CLLocation*)thelocation
{
    CLGeocoder* theGeocoder = [[CLGeocoder alloc] init];
    
    [theGeocoder reverseGeocodeLocation:thelocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error)
        {
            if (error.code == kCLErrorNetwork)
            {
                NSLog(@"No internet connection for reverse geolocation");
                //Alert(@"No Internet connection!");
            }
            else if (error.code == kCLErrorGeocodeFoundPartialResult){
                NSLog(@"Only partial placemark returned");
            }
            else
                NSLog(@"Error Reverse Geolocating: %@", [error localizedDescription]);
        }
        else
        {
            self.placemark = [placemarks lastObject];
            
            // Notify observers of updated address with placemark
            if (self.placemark != nil)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdatePlacemark object:self];
            }
        }
    }];
}

@end



