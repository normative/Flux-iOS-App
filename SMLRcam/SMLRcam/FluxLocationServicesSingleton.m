//
//  FluxLocationServicesSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-08.
//  Copyright (c) 2013 SMLR. All rights reserved.
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
    self.notMoving = 1;
    return self;
}

- (void)startLocating{
    [locationManager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)  name:UIDeviceOrientationDidChangeNotification  object:nil];
    [self orientationChanged:nil];
    
    if ([CLLocationManager headingAvailable]) {
        [locationManager startUpdatingHeading];
    }
    else {
        NSLog(@"No Heading Information Available");
    }
}
- (void)endLocating{
    [locationManager stopUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    if ([CLLocationManager headingAvailable]) {
        [locationManager stopUpdatingHeading];
    }
}

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown)
    {
        // Face-up, face-down, and unknown will preserve the previous frame
        return;
    }
    
    locationManager.headingOrientation = orientation;
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
    
    //log location params
//    NSLog(@"Adding new location  with date: %@ \nAnd Location: %0.15f, %0.15f, %f +/- %f (h), %f (v)",
//          [dateFormat stringFromDate:newLocation.timestamp], newLocation.coordinate.latitude, newLocation.coordinate.longitude,
//          newLocation.altitude, newLocation.horizontalAccuracy, newLocation.verticalAccuracy);
    
    // store all of the measurements, just so we can see what kind of data we might receive
    [locationMeasurements addObject:newLocation];
    
    // truncate data to maximum size of window (i.e. 5 locations)
    while ([locationMeasurements count] > 5)
    {
        [locationMeasurements removeObjectAtIndex:0];
    }
   
    // TODO: add in code here to "correct" the current location based on whatever (Kalman, etc.)
    //  Update newLocation and procede
    
//#warning Overriding location with fixed value
//    // HACK
//    // force location value to eliminate GPS from equation...
////    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.324796, -79.813148);   // Burlington office
////    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.324796, -79.813148);   // Normative office
//    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.325796, -79.813148);   // ??
//    newLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:newLocation.altitude
//                                      horizontalAccuracy:newLocation.horizontalAccuracy verticalAccuracy:newLocation.verticalAccuracy
//                                      course:newLocation.course speed:newLocation.speed timestamp:newLocation.timestamp];
    
    self.location = newLocation;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *walkMode = [defaults objectForKey:@"Walk Mode"];
    
    if (walkMode.intValue == 1)
    {
        self.notMoving = (newLocation.speed > 0.75) ? 0 : 1;
    }
    else
    {
        self.notMoving = 1;
    }
    
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
    self.heading = ((newHeading.trueHeading >= 0) ? newHeading.trueHeading : newHeading.magneticHeading);
    
    // Notify observers of updated heading, if we have a valid heading
    // Since heading is a double, assume that we only have a valid heading if we have a location
    if (self.location != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdateHeading object:self];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Failed with error: %@", [error localizedDescription]);
    // The location "unknown" error simply means the manager is currently unable to get the location.
    if ([error code] != kCLErrorLocationUnknown)
    {
        [self endLocating];
    }
}

#pragma mark - Location geocoding

- (void)reverseGeocodeLocation:(CLLocation*)thelocation
{
    CLGeocoder* theGeocoder = [[CLGeocoder alloc] init];
    
    [theGeocoder reverseGeocodeLocation:thelocation completionHandler:^(NSArray *placemarks, NSError *error)
    {
        if (error)
        {
            if (error.code == kCLErrorNetwork)
            {
                NSLog(@"No internet connection for reverse geolocation");
                //Alert(@"No Internet connection!");
                return;
            }
            else if (error.code == kCLErrorGeocodeFoundPartialResult){
                NSLog(@"Only partial placemark returned");
            }
            else {
                NSLog(@"Error Reverse Geolocating: %@", [error localizedDescription]);
                return;
            }
        }
        
        self.placemark = [placemarks lastObject];
        
        // Notify observers of updated address with placemark
        if (self.placemark != nil)
        {
            NSString *newSubLocality = [self.placemark.addressDictionary valueForKey:@"SubLocality"];
            NSString *newSubAdministrativeArea = [self.placemark.addressDictionary valueForKey:@"SubAdministrativeArea"];
            
            if (![self.subadministativearea isEqualToString: newSubAdministrativeArea] || ![self.sublocality isEqualToString: newSubLocality])
            {
                self.sublocality = newSubLocality;
                self.subadministativearea = newSubAdministrativeArea;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdatePlacemark object:self];
            }
        }
    }];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager{
    return YES;
}


@end



