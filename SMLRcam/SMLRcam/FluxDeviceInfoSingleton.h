//
//  FluxDeviceInfoSingleton.h
//  Flux
//
//  Created by Denis Delorme on 2/24/14.
//  Copyright (c) 2014 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxCameraModel.h"
#import "FluxScanImageObject.h"

typedef enum {
    fdp_unknown,
    fdp_simulator,
    fdp_iPad2,
    fdp_iPad3,
    fdp_iPad4,
    fdp_iPadAir,
    fdp_iPadMini1,
    fdp_iPadMini2,
    fdp_iPhone4s,
    fdp_iPhone5,
    fdp_iPhone5c,
    fdp_iPhone5s
} FluxDevicePlatform;

extern const NSString *FluxDevicePlatformStrings[];

@interface FluxDeviceInfoSingleton : NSObject

@property (strong, nonatomic) NSString *deviceModelStr;
@property (strong, nonatomic) NSString *platformStr;
@property (strong, nonatomic) FluxCameraModel *cameraModel;
@property (nonatomic) int  renderTextureCount;
@property (nonatomic) bool isFeatureMatching;
@property (nonatomic) int  cacheCountLimit;
@property (nonatomic) FluxImageType highestResToQuery;
@property (strong, nonatomic) NSString *captureResolution;

+ (id)sharedDeviceInfo;
+ (NSString *)currentAppVersionString;

- (FluxCameraModel *) cameraModelForDeviceModelString:(NSString *)deviceModelString;

@end
