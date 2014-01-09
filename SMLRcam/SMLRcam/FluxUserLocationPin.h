//
//  FluxUserLocationPin.h
//  Flux
//
//  Created by Kei Turner on 1/8/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FluxUserLocationPin : NSObject <MKOverlay> {
}
@property (nonatomic, assign) CLLocation *location;
@property (nonatomic, assign) MKMapRect boundingMapRect;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;


@end
