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
- (void)LocationManager:(FluxLocationServicesSingleton *)locationSingleton didUpdateHeading:(CLLocationDirection)newHeading;
@end


@interface FluxLocationServicesSingleton : NSObject <CLLocationManagerDelegate>{
    CLLocationManager * locationManager;
    
    id __weak delegate;
    NSMutableArray *locationMeasurements;
}

@property (weak) id <LocationServicesSingletonDelegate> delegate;
@property (nonatomic) CLLocation* location;
@property (nonatomic) CLLocationDirection heading;

+ (id)sharedManager;

- (void)startLocating;
- (void)endLocating;

@end