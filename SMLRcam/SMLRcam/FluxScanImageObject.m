//
//  FluxScanImageObject.m
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxScanImageObject.h"

@implementation FluxScanImageObject

#pragma mark - getter methods


- (NSString*)title
{
    return @"1 image";
}

- (NSString*)subtitle
{
    NSDateFormatter *outputDateFormat = [[NSDateFormatter alloc] init];
    [outputDateFormat setDateFormat:@"yyyy-MM-dd"];
    
    return [outputDateFormat stringFromDate:self.timestamp];
}

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
         andlatitude:(double)latitude
        andlongitude:(double)longitude
         andaltitude:(double)altitude
          andHeading:(double)heading
              andYaw:(double)yaw
            andPitch:(double)pitch
             andRoll:(double)roll
               andQW:(double)qw
               andQX:(double)qx
               andQY:(double)qy
               andQZ:(double)qz
    andHorizAccuracy:(double)horiz_accuracy
     andVertAccuracy:(double)vert_accuracy;
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
        self.horiz_accuracy = horiz_accuracy;
        self.vert_accuracy = vert_accuracy;
        self.localID = [self generateUniqueStringID];
        self.matched = NO;
        self.matchFailed = NO;
    }
    
    return self;
    
}

- (NSString *)generateUniqueStringID
{    
    NSDateFormatter *outputDateFormat = [[NSDateFormatter alloc] init];
    [outputDateFormat setDateFormat:@"yyyyMMddHHmmss"];
    
    NSString *stringID = [outputDateFormat stringFromDate:self.timestamp];
    return [NSString stringWithFormat:@"%@_%d", stringID, self.userID];
}

- (NSString *) generateImageCacheKeyWithImageType:(FluxImageType)imageType
{
    if (self.localID != nil)
    {
        return [self.localID stringByAppendingFormat:@"_%d",imageType];
    }
    return nil;
}

@end
