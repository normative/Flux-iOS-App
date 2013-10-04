//
//  FluxScanImageObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-09.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <GLKit/GLKit.h>

typedef NSString FluxLocalID;
typedef int FluxImageID;

typedef enum FluxImageType : NSUInteger {
    none = 0,
    thumb = 1,
    screen_res = 2,
    full_res = 3,
} FluxImageType;

@interface FluxScanImageObject : NSObject <MKAnnotation>

//location
@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@property (nonatomic) double altitude;

//orientation (euler angles)
@property (nonatomic) double yaw;
@property (nonatomic) double pitch;
@property (nonatomic) double roll;
@property (nonatomic) double heading;

// orientation (quaternions)
@property (nonatomic) double qw;
@property (nonatomic) double qx;
@property (nonatomic) double qy;
@property (nonatomic) double qz;

// position accuracy and confidence levels
@property (nonatomic) double horiz_accuracy;
@property (nonatomic) double vert_accuracy;
@property (nonatomic) double location_confidence;

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
