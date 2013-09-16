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

enum image_type {
    none = 0,
    thumb = 1,
    screen_res = 2,
    full_res = 3,
};

typedef enum image_type image_type;

@interface FluxScanImageObject : NSObject <MKAnnotation>

//location
@property (nonatomic) float longitude;
@property (nonatomic) float latitude;
@property (nonatomic) float altitude;

//orientation (euler angles)
@property (nonatomic) float yaw;
@property (nonatomic) float pitch;
@property (nonatomic) float roll;
@property (nonatomic) float heading;

// orientation (quaternions)
@property (nonatomic) float qw;
@property (nonatomic) float qx;
@property (nonatomic) float qy;
@property (nonatomic) float qz;

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
@property (nonatomic) NSString* localThumbID;

- (id)initWithUserID:(int)userID
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
              andRoll:(float)roll
                andQW:(float)qw
                andQX:(float)qx
                andQY:(float)qy
                andQZ:(float)qz;

- (NSString *) generateImageCacheKeyWithImageType:(image_type)imageType;
- (NSString *)generateUniqueStringID;

// MKAnnoation getter methods;
- (NSString *)title;
- (NSString *)subtitle;
- (CLLocationCoordinate2D)coordinate;

@end
