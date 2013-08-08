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
- (void)LocationManager:(FluxLocationServicesSingleton *)locationSingleton didUpdateLocation:(CLLocation*)location;
- (void)LocationManager:(FluxLocationServicesSingleton *)locationSingleton didUpdateHeading:(CLLocationDirection)heading;
@end


@interface FluxLocationServicesSingleton : NSObject <CLLocationManagerDelegate>{
    CLLocationManager * locationManager;
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <LocationServicesSingletonDelegate> delegate;
@property (nonatomic, weak) CLLocation* location;
@property (nonatomic) CLLocationDirection heading;

+ (id)sharedManager;

- (void)startLocating;
- (void)endLocating;

@end