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
    theCoordinate.latitude = self.latitude;
    theCoordinate.longitude = self.longitude;
    
    return theCoordinate;
}

#pragma mark - nsobject life cycle

- (id)initWithUserID:(int)userID
   atTimestampString:(NSString *)timestampStr
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
               andQW:(float)qw
               andQX:(float)qx
               andQY:(float)qy
               andQZ:(float)qz;
{
    self = [super init];
    if (self)
    {
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
        self.qw = qw;
        self.qx = qx;
        self.qy = qy;
        self.qz = qz;
        self.localID = [self generateUniqueStringID];
    }
    
    return self;
    
}

- (NSString *)generateUniqueStringID
{
    NSDateFormatter *inputDateFormat = [[NSDateFormatter alloc] init];
    [inputDateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    NSDate *objDate = [inputDateFormat dateFromString:self.timestampString];
    
    NSDateFormatter *outputDateFormat = [[NSDateFormatter alloc] init];
    [outputDateFormat setDateFormat:@"yyyyMMddHHmmss"];
    
    NSString *stringID = [outputDateFormat stringFromDate:objDate];
    return [NSString stringWithFormat:@"%@_%d", stringID, self.userID];
}

- (void)setImageIDFromDateAndUser
{
    NSString *newImageID = [NSString stringWithFormat:@"%@_%d", self.timestampString, self.userID];
    NSLog(@"ImageID: %@", newImageID);

    // Set to -1 now. App code will rely on localID.
    // Numeric imageID will be set by the server on upload completion.
    self.imageID = -1;
}

@end
