//
//  FluxLocationServicesSingleton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-08.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString* const FluxLocationServicesSingletonDidUpdateLocation;
extern NSString* const FluxLocationServicesSingletonDidUpdateHeading;
extern NSString* const FluxLocationServicesSingletonDidUpdatePlacemark;

extern NSString* const FluxLocationServicesSingletonKeyLocation;
extern NSString* const FluxLocationServicesSingletonKeyHeading;
extern NSString* const FluxLocationServicesSingletonKeyPlacemark;

@interface FluxLocationServicesSingleton : NSObject <CLLocationManagerDelegate>{
    CLLocationManager * locationManager;
    NSMutableArray *locationMeasurements;
}
@property (nonatomic) CLLocation* location;
@property (nonatomic) CLLocationDirection heading;
@property (nonatomic) CLPlacemark* placemark;

@property (nonatomic) NSString* sublocality;
@property (nonatomic) NSString* subadministativearea;

+ (id)sharedManager;

- (void)startLocating;
- (void)endLocating;
- (void)orientationChanged:(NSNotification *)notification;

- (void)reverseGeocodeLocation:(CLLocation*)thelocation;

@end