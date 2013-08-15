//
//  FluxScanImageObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct {
    double yaw;
    double pitch;
    double roll;
} Attitude;

typedef struct {
    double longitue;
    double latitude;
    double altitude;
} Location;

@interface FluxScanImageObject : NSObject


//image itself
@property (nonatomic, weak)UIImage *contentImage;
@property (nonatomic) int ImageID;

//location
@property (nonatomic) Location location;

//orientation
@property (nonatomic) Attitude attitude;

//other
@property (nonatomic,strong) NSDate* timestampDate;
@property (nonatomic, weak) NSString* userName;
@property (nonatomic, weak) NSString* descriptionString;
@property (nonatomic) int categoryID;

@end
