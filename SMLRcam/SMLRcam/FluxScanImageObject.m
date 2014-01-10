//
//  FluxScanImageObject.m
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxScanImageObject.h"
#import <sys/utsname.h>

@implementation FluxScanImageObject

const NSString *fluxImageTypeStrings[] = {
    @"none",
    @"thumbcrop",
    @"quarterhdcrop",
    @"screen",
    @"oriented",
    @"highest",
    @"features"
};

const NSString *fluxCameraModelStrings[] = {
    @"unknown",     // unknown
    @"iPhone4,1",   // iPhone 4  ??
    @"iPhone4,2",   // iPhone 4s ??
    @"iPhone5,1",   // iPhone 5
    @"iPhone5,2",   // iPhone 5  CDMA+GSM
    @"iPhone5,3",   // iPhone 5c
    @"iPhone6,1"    // iPhone 5s
};

- (NSString*)deviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

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

#pragma mark - setter methods

- (void) setCameraModelStr:(NSString *)cameraModelStr
{
    _cameraModelStr = cameraModelStr;
    
    _cameraModel = unknown_cam;
    
    int stridx = 0;
    
    // i
    for (int i = 1; (i < (sizeof(fluxCameraModelStrings) / sizeof(NSString *))); i++)
    {
        if ([cameraModelStr compare:fluxCameraModelStrings[i] options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            stridx = i;
            break;
        }
    }
    
    switch (stridx)
    {
        case 1:     // iPhone 4     ??
            _cameraModel = iphone4;
            break;
        case 2:     // iPhone 4s    ??
            _cameraModel = iphone4s;
            break;
        case 3:     // iPhone 5
        case 4:     // iPhone 5 CDMA+GSM
            _cameraModel = iphone5;
            break;
        case 5:     // iPhone 5c
            _cameraModel = iphone5c;
            break;
        case 6:     // iPhone 5s
            _cameraModel = iphone5s;
            break;
        default:    // unknown - anything else is an iPhone 5 for now...
            _cameraModel = iphone5;
            break;
    }
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
        self.cameraModelStr = [self deviceName];
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
        self.location_data_type = location_data_default;
        self.features = nil;
        self.featureFetching = false;
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
