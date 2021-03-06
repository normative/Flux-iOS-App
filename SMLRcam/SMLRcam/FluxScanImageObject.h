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
    highest_res = 5,     // keep this at highest allowable resultion + 1
    features = 6
} FluxImageType;

// Used as a bit mask of FluxImageType's for packing
typedef enum {
  FluxImageTypeMaskNone         = 0,
  FluxImageTypeMask_lowest_res  = 1 << lowest_res,
  FluxImageTypeMask_thumb       = 1 << thumb,
  FluxImageTypeMask_quarterhd   = 1 << quarterhd,
  FluxImageTypeMask_screen_res  = 1 << screen_res,
  FluxImageTypeMask_full_res    = 1 << full_res,
  FluxImageTypeMask_highest     = 1 << highest_res,
  FluxImageTypeMask_features    = 1 << features
} FluxImageTypeMask;

extern const NSString *fluxImageTypeStrings[];
extern const NSString *fluxCameraModelStrings[];

typedef enum LocationDataType : NSUInteger {
    location_data_default = 0,
    location_data_valid_ecef = 1,
    location_data_from_homography = 2
} LocationDataType;

@interface FluxScanImageObject : NSObject <MKAnnotation>

// Image and User properties
@property (nonatomic) int devicePlatform;   // leave as int or will have issues with circular dependencies.  Is actually a FluxDevicePlatform.
@property (nonatomic) int cameraID;
@property (nonatomic, strong) NSString *cameraModelStr;
@property (nonatomic) int categoryID;
@property (nonatomic, strong) NSString* descriptionString;
@property (nonatomic) FluxImageID imageID;
@property (nonatomic) int justCaptured;
@property (nonatomic) FluxLocalID *localID;
@property (nonatomic) bool privacy;
@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NSString* timestampString;
@property (nonatomic) FluxImageID userID;
@property (nonatomic, strong) NSString* username;

// Image location/orientation
// Image location/orientation - location
@property (nonatomic) double altitude;
@property (nonatomic) double horiz_accuracy;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double vert_accuracy;
// Image location/orientation - ECEF for kalman estimated values
@property (nonatomic) double ecefX;
@property (nonatomic) double ecefY;
@property (nonatomic) double ecefZ;
// Image location/orientation - Data type to use for projection
@property (nonatomic) LocationDataType location_data_type; //type of location data (default, live, matched)
@property (nonatomic) sensorPose imageHomographyPosePnP;
@property (nonatomic) sensorPose userHomographyPose;
// Image location/orientation - orientation (euler angles)
@property (nonatomic) double yaw;
@property (nonatomic) double pitch;
@property (nonatomic) double roll;
@property (nonatomic) double heading;
@property (nonatomic) double relHeading;
@property (nonatomic) double absHeading;
// Image location/orientation - orientation (quaternions)
@property (nonatomic) double qw;
@property (nonatomic) double qx;
@property (nonatomic) double qy;
@property (nonatomic) double qz;

// Feature matching properties
@property (nonatomic) bool featureFetchFailed;
@property (nonatomic, strong) NSData *features;
@property (nonatomic) bool matched;
@property (nonatomic) bool matchFailed;
@property (nonatomic, strong) NSDate* matchFailureRetryTime;
@property (nonatomic) transformRtn matchTransform;

// Feature matching properties - metrics
@property (nonatomic) NSTimeInterval cumulativeFeatureMatchTime;
@property (nonatomic) NSUInteger numFeatureMatchAttempts;
@property (nonatomic) NSUInteger numFeatureMatchCancels;
@property (nonatomic) NSUInteger numFeatureMatchFailMatchErrors;
@property (nonatomic) NSUInteger numFeatureMatchFailHomographyErrors;

- (id)initWithUserID:(int)userID
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

- (NSString *) generateImageCacheKeyWithImageType:(FluxImageType)imageType;
- (NSString *)generateUniqueStringID;

// MKAnnoation getter methods;
- (NSString *)title;
- (NSString *)subtitle;
- (CLLocationCoordinate2D)coordinate;

@end
