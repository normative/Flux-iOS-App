//
//  FluxScanImageObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxScanImageObject : NSObject


//image itself
@property (nonatomic, weak)UIImage *contentImage;


//location
@property (nonatomic) float longitude;
@property (nonatomic) float latitude;
@property (nonatomic) float altitude;

//orientation
@property (nonatomic) float yaw;
@property (nonatomic) float pitch;
@property (nonatomic) float roll;
@property (nonatomic) float heading;


//other
@property (nonatomic, weak) NSString* timestampString;
@property (nonatomic, weak) NSString* descriptionString;
@property (nonatomic) int categoryID;
@property (nonatomic) int cameraID;
@property (nonatomic) int imageID;
@property (nonatomic) int userID;

@end
