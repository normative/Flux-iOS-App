//
//  FluxMapImageObject.h
//  Flux
//
//  Created by Kei Turner on 2013-10-18.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FluxMapImageObject : NSObject <MKAnnotation>

@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@property (nonatomic) double altitude;
@property (nonatomic) double altitudeDiff;

@property (nonatomic) int imageID;
@property (nonatomic, strong)NSString* theDescription;
@property (nonatomic, strong)UIImage* image;
@property (nonatomic, strong)NSDate* timestamp;


@end
