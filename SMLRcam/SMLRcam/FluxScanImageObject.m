//
//  FluxScanImageObject.m
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxScanImageObject.h"
#import <sys/utsname.h>

NSDateFormatter *__fluxScanImageObjectDateFormatter = nil;
NSDateFormatter *__fluxScanImageObjectLocalIDDateFormatter = nil;
NSDateFormatter *__fluxScanImageObjectSubTitleDateFormatter = nil;

@implementation FluxScanImageObject

const NSString *fluxImageTypeStrings[] = {
    @"none",
    @"thumbcrop",
    @"quarterhdcrop",
    @"screen",
    @"oriented",
    @"highest",
    @"binfeatures"
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


- (id)init{
    self = [super init];
    if (self)
    {
        _timestampString = nil;
        _justCaptured = 0;      // default to pull from cloud (typical case)
        if (!__fluxScanImageObjectDateFormatter)
        {
            __fluxScanImageObjectDateFormatter = [[NSDateFormatter alloc]init];
            NSTimeZone *tz = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
            [__fluxScanImageObjectDateFormatter setTimeZone:tz];
            [__fluxScanImageObjectDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];

            _timestamp = [NSDate date];
            _timestampString = [__fluxScanImageObjectDateFormatter stringFromDate:_timestamp];
            NSLog(@"timestamp: %@, timestampstr: %@", self.timestamp, self.timestampString);
        }
        
        if (!__fluxScanImageObjectLocalIDDateFormatter)
        {
            __fluxScanImageObjectLocalIDDateFormatter = [[NSDateFormatter alloc] init];
            [__fluxScanImageObjectLocalIDDateFormatter setDateFormat:@"yyyyMMddHHmmssSSS"];

        }
        
        if (!__fluxScanImageObjectSubTitleDateFormatter)
        {
            __fluxScanImageObjectSubTitleDateFormatter = [[NSDateFormatter alloc] init];
            [__fluxScanImageObjectSubTitleDateFormatter setDateFormat:@"yyyy-MM-dd"];
        }
    }
    
    return self;
}

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
    return [__fluxScanImageObjectSubTitleDateFormatter stringFromDate:self.timestamp];
}

- (NSString *)timestampString
{
    if (!_timestampString)
    {
        if (_timestamp)
        {
            NSLog(@"_timestampString null, timestamp not");
            _timestampString = [__fluxScanImageObjectDateFormatter stringFromDate:self.timestamp];
        }
    }
    return _timestampString;
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude = self.latitude;
    theCoordinate.longitude = self.longitude;
    
    return theCoordinate;
}

#pragma mark -- utility / class methods

+ (FluxCameraModelEnum)cameraModelFromModelStr:(NSString *)cameraModelStr
{
    FluxCameraModelEnum cameraModel = unknown_cam;
    
    int stridx = 0;
    
    // i
    for (int i = 1; (i < (sizeof(fluxCameraModelStrings) / sizeof(NSString *))); i++)
    {
        if ([cameraModelStr compare:(NSString *)fluxCameraModelStrings[i] options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            stridx = i;
            break;
        }
    }
    
    switch (stridx)
    {
        case 1:     // iPhone 4     ??
            cameraModel = iphone4;
            break;
        case 2:     // iPhone 4s    ??
            cameraModel = iphone4s;
            break;
        case 3:     // iPhone 5
        case 4:     // iPhone 5 CDMA+GSM
            cameraModel = iphone5;
            break;
        case 5:     // iPhone 5c
            cameraModel = iphone5c;
            break;
        case 6:     // iPhone 5s
            cameraModel = iphone5s;
            break;
        default:    // unknown - anything else is an iPhone 5 for now...
            cameraModel = iphone5;
            break;
    }
    
    return cameraModel;
}

#pragma mark - setter methods

- (void) setCameraModelStr:(NSString *)cameraModelStr
{
    _cameraModelStr = cameraModelStr;
    
    _cameraModel = [FluxScanImageObject cameraModelFromModelStr:cameraModelStr];
    
    int stridx = 0;
    
    // i
    for (int i = 1; (i < (sizeof(fluxCameraModelStrings) / sizeof(NSString *))); i++)
    {
        if ([cameraModelStr compare:(NSString *)fluxCameraModelStrings[i] options:NSCaseInsensitiveSearch] == NSOrderedSame)
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

- (void)setTimestampString:(NSString *)newTimestampString
{
    _timestampString = newTimestampString;
    _timestamp = [__fluxScanImageObjectDateFormatter dateFromString:newTimestampString];
}

#pragma mark - nsobject life cycle

- (id)initWithUserID:(int)userID
//   atTimestampString:(NSString *)timestampStr
         atTimestamp:(NSDate *)timeStamp
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
    self = [self init];
    if (self)
    {
        self.userID = userID;
        self.cameraID = camID;
        self.cameraModelStr = [self deviceName];
        self.categoryID = catID;
        self.timestamp = timeStamp;
        // use the variable rather than the property to skip the setter
        _timestampString = [__fluxScanImageObjectDateFormatter stringFromDate:timeStamp];
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
        self.numFeatureMatchAttempts = 0;
        self.numFeatureMatchCancels = 0;
        self.numFeatureMatchFailHomographyErrors = 0;
        self.numFeatureMatchFailMatchErrors = 0;
        self.cumulativeFeatureMatchTime = 0.0;
        self.location_data_type = location_data_default;
        self.features = nil;
        self.featureFetchFailed = NO;
        self.justCaptured = 1;      // assume this method is called only when newly captured image record needs to be created
        
        NSLog(@"timestamp: %@, timestampstr: %@", self.timestamp, self.timestampString);
    }
    
    return self;
}

- (NSString *)generateUniqueStringID
{
    NSString *stringID = [__fluxScanImageObjectLocalIDDateFormatter stringFromDate:self.timestamp];
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
