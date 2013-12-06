//
//  FluxScanImageObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <GLKit/GLKit.h>
#import "FluxOpenGLCommon.h"

typedef NSString FluxLocalID;
typedef int FluxImageID;

typedef enum FluxImageType : NSUInteger {
    lowest_res = 0,
    none = 0,
    thumb = 1,
    quarterhd = 2,
    screen_res = 3,
    full_res = 4,
    highest_res = 5     // keep this at highest allowable resultion + 1
} FluxImageType;

typedef enum LocationDataType : NSUInteger {
    location_data_default = 0,
    location_data_valid_ecef = 1,
    location_data_from_homography = 2
} LocationDataType;

@interface FluxScanImageObject : NSObject <MKAnnotation>

//location
@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@property (nonatomic) double altitude;


//location ecef for kalman estimated values
@property (nonatomic) double ecefX;
@property (nonatomic) double ecefY;
@property (nonatomic) double ecefZ;

//
@property (nonatomic) sensorPose imageHomographyPose;
@property (nonatomic) sensorPose userHomographyPose;

//orientation (euler angles)
@property (nonatomic) double yaw;
@property (nonatomic) double pitch;
@property (nonatomic) double roll;
@property (nonatomic) double heading;
@property (nonatomic) double relHeading;
@property (nonatomic) double absHeading;

// orientation (quaternions)
@property (nonatomic) double qw;
@property (nonatomic) double qx;
@property (nonatomic) double qy;
@property (nonatomic) double qz;

// position accuracy and confidence levels
@property (nonatomic) double horiz_accuracy;
@property (nonatomic) double vert_accuracy;
@property (nonatomic) LocationDataType location_data_type; //type of location data (default, live, matched)

//other
@property (nonatomic, strong) NSString* timestampString;
@property (nonatomic, strong) NSDate* timestamp;

@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* descriptionString;

@property (nonatomic) GLKQuaternion rotation;

@property (nonatomic) int categoryID;
@property (nonatomic) int cameraID;
@property (nonatomic) int imageID;
@property (nonatomic) FluxImageID userID;
@property (nonatomic) FluxLocalID *localID;

@property (nonatomic) bool matched;

- (id)initWithUserID:(int)userID
  atTimestampString:(NSString*)timestampStr
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

- (NSString *) generateImageCacheKeyWithImageType:(FluxImageType)imageType;
- (NSString *)generateUniqueStringID;

// MKAnnoation getter methods;
- (NSString *)title;
- (NSString *)subtitle;
- (CLLocationCoordinate2D)coordinate;

@end
