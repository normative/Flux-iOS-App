//
//  FluxLocationServicesSingleton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-08.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class FluxLocationServicesSingleton;
@protocol LocationServicesSingletonDelegate <NSObject>
@optional
- (void)LocationManager:(FluxLocationServicesSingleton *)locationSingleton didUpdateLocation:(CLLocation*)newLocation;
- (void)LocationManager:(FluxLocationServicesSingleton *)locationSingleton didUpdateToHeading:(CLLocationDirection)newHeading;
- (void)LocationManager:(FluxLocationServicesSingleton *)locationSingleton didUpdateAddressWithPlacemark:(CLPlacemark*)placemark;
@end


@interface FluxLocationServicesSingleton : NSObject <CLLocationManagerDelegate>{
    CLLocationManager * locationManager;
    __weak id <LocationServicesSingletonDelegate> delegate;
    NSMutableArray *locationMeasurements;
}
@property (nonatomic, weak) id <LocationServicesSingletonDelegate> delegate;
@property (nonatomic, weak) CLLocation* location;
@property (nonatomic) CLLocationDirection heading;
@property (nonatomic,weak) CLPlacemark* placemark;

+ (id)sharedManager;

- (void)startLocating;
- (void)endLocating;

- (void)reverseGeocodeLocation:(CLLocation*)thelocation;

@end