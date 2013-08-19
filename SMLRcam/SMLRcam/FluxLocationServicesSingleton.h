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

@class FluxLocationServicesSingleton;

@interface FluxLocationServicesSingleton : NSObject <CLLocationManagerDelegate>{
    CLLocationManager * locationManager;
    NSMutableArray *locationMeasurements;
}
@property (nonatomic) CLLocation* location;
@property (nonatomic) CLLocationDirection heading;
@property (nonatomic) CLPlacemark* placemark;

+ (id)sharedManager;

- (void)startLocating;
- (void)endLocating;

- (void)reverseGeocodeLocation:(CLLocation*)thelocation;

@end