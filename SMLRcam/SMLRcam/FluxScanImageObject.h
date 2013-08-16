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

- (id)initWithImage:(UIImage*)img
     fromUserWithID:(int)userID
        andCameraID:(int)camID
      andCategoryID:(int)catID
withDescriptionString:(NSString*)description
        andlatitude:(float)latitude
       andlongitude:(float)longitude
        andaltitude:(float)altitude
         andHeading:(float)heading
             andYaw:(float)yaw
           andPitch:(float)pitch
            andRoll:(float)roll
;

@end
