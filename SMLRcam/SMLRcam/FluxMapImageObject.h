//
//  FluxMapImageObject.h
//  Flux
//
//  Created by Kei Turner on 2013-10-18.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FluxMapImageObject : NSObject <MKAnnotation>

@property (nonatomic) double longitude;
@property (nonatomic) double latitude;

@property (nonatomic) int imageID;


@end