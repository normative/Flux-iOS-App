//
//  FluxScanImageObject.m
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxScanImageObject.h"

@implementation FluxScanImageObject

#pragma mark - getter methods

//
- (NSString*)title
{
    return [NSString stringWithFormat:@"location date: %@", self.timestampString];
}

//
- (NSString*)subtitle
{
    return self.descriptionString;
}

//
- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.longitude = self.latitude;
    theCoordinate.longitude = self.longitude;
    
    return theCoordinate;
}

#pragma mark - nsobject life cycle

- (id)initWithImage:(UIImage*)img
     fromUserWithID:(int)userID
  atTimestampString:(NSString*)timestampStr
        andCameraID:(int)camID
      andCategoryID:(int)catID
withDescriptionString:(NSString*)description
        andlatitude:(float)latitude
       andlongitude:(float)longitude
        andaltitude:(float)altitude
         andHeading:(float)heading
             andYaw:(float)yaw
           andPitch:(float)pitch
            andRoll:(float)roll;
{
    self = [super init];
    if (self)
    {
        self.contentImage = img;
        self.userID = userID;
        self.cameraID = camID;
        self.categoryID = catID;
        self.timestampString = timestampStr;
        self.descriptionString = description;
        self.latitude = latitude;
        self.longitude = longitude;
        self.altitude = altitude;
        self.heading = heading;
        self.yaw = yaw;
        self.pitch = pitch;
        self.roll = roll;
    }
    
    return self;
    
}

@end
