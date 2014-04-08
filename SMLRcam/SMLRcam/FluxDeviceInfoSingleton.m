//
//  FluxDeviceInfoSingleton.m
//  Flux
//
//  Created by Denis Delorme on 2/24/14.
//  Copyright (c) 2014 SMLR. All rights reserved.
//

#import "FluxDeviceInfoSingleton.h"
#import "FluxCameraModel.h"
#import <AVFoundation/AVFoundation.h>
#import <sys/utsname.h>

const NSString *fluxDeviceModelStrings[] = {
    @"unknown",     // unknown
    @"x86_64",      // simulator
    @"iPad2,1",     // iPad 2
    @"iPad2,2",     // iPad 2
    @"iPad2,3",     // iPad 2
    @"iPad2,4",     // iPad 2
    @"iPad3,1",     // iPad 3
    @"iPad3,2",     // iPad 3
    @"iPad3,3",     // iPad 3
    @"iPad3,4",     // iPad 4
    @"iPad3,5",     // iPad 4
    @"iPad3,6",     // iPad 4
    @"iPad4,1",     // iPad Air
    @"iPad4,2",     // iPad Air
    
    @"iPad2,5",     // iPad mini 1G
    @"iPad2,6",     // iPad mini 1G
    @"iPad2,7",     // iPad mini 1G
    @"iPad4,4",     // iPad mini 2G (Retina)
    @"iPad4,5",     // iPad mini 2G (Retina)

    @"iPhone4,1",   // iPhone 4s
    @"iPhone5,1",   // iPhone 5
    @"iPhone5,2",   // iPhone 5  CDMA+GSM
    @"iPhone5,3",   // iPhone 5c
    @"iPhone5,4",   // iPhone 5c
    @"iPhone6,1",   // iPhone 5s
    @"iPhone6,2"    // iPhone 5s
};

typedef enum {
    fdm_unknown,     // unknown
    fdm_x86_64,      // simulator
    fdm_iPad2_1,     // iPad 2
    fdm_iPad2_2,     // iPad 2
    fdm_iPad2_3,     // iPad 2
    fdm_iPad2_4,     // iPad 2
    fdm_iPad3_1,     // iPad 3
    fdm_iPad3_2,     // iPad 3
    fdm_iPad3_3,     // iPad 3
    fdm_iPad3_4,     // iPad 4
    fdm_iPad3_5,     // iPad 4
    fdm_iPad3_6,     // iPad 4
    fdm_iPad4_1,     // iPad Air
    fdm_iPad4_2,     // iPad Air
    
    fdm_iPad2_5,     // iPad mini 1G
    fdm_iPad2_6,     // iPad mini 1G
    fdm_iPad2_7,     // iPad mini 1G
    fdm_iPad4_4,     // iPad mini 2G (Retina)
    fdm_iPad4_5,     // iPad mini 2G (Retina)
    
    fdm_iPhone4_1,   // iPhone 4s
    fdm_iPhone5_1,   // iPhone 5
    fdm_iPhone5_2,   // iPhone 5  CDMA+GSM
    fdm_iPhone5_3,   // iPhone 5c
    fdm_iPhone5_4,   // iPhone 5c
    fdm_iPhone6_1,   // iPhone 5s
    fdm_iPhone6_2    // iPhone 5s
    
} fluxDeviceModel;


const NSString *FluxDevicePlatformStrings[] = {
    @"unknown",
    @"simulator",
    @"iPad 2G",
    @"iPad 3G",
    @"iPad 4G",
    @"iPad Air",
    @"iPad Mini 1G",
    @"iPad Mini 2G",
    @"iPhone 4s",
    @"iPhone 5",
    @"iPhone 5c",
    @"iPhone 5s"
};


@implementation FluxDeviceInfoSingleton

+ (id)sharedDeviceInfo {
    static FluxDeviceInfoSingleton *sharedFluxDeviceInfoSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFluxDeviceInfoSingleton = [[self alloc] init];
    });
    return sharedFluxDeviceInfoSingleton;
}

+ (NSString *)currentAppVersionString
{
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    return [NSString stringWithFormat:@"%@(%@)",version, build];
}

- (id)init
{
    if (self = [super init])
    {
        // fetch device model and set up everything else
        struct utsname systemInfo;
        uname(&systemInfo);
        
        // model id for DB
        _deviceModelStr = [NSString stringWithCString:systemInfo.machine
                                       encoding:NSUTF8StringEncoding];
        
        FluxDevicePlatform _devicePlatform = [self devicePlatformForModelStr:_deviceModelStr];
        
        // model string for logs
        _platformStr = (NSString *)FluxDevicePlatformStrings[_devicePlatform];
        
        // camera model
        // should be able to index off of _devPlatform
        _cameraModel = [self getCameraModelForPlatform:_devicePlatform];

        // memory limits & functional restrictions
        
        //  - number of textures to render
        _renderTextureCount = [self calcRenderTextureCountForPlatform:_devicePlatform];

        //  - enable/disable feature matching
        _isFeatureMatching = [self getFeatureMatchingForPlatform:_devicePlatform];
        
        //  - NSCache count limit
        _cacheCountLimit = [self getCacheCountLimitForPlatform:_devicePlatform];
        
        // image query resolution
        _highestResToQuery = [self getHighestResToQueryForPlatform:_devicePlatform];
        
        // resolution to capture imagery at
        _captureResolution = [self getCaptureResForPlatform:_devicePlatform];

    }
    
    NSLog(@"DeviceInfo singleton initialized, device platform = %@", _platformStr);
    
    return self;
}


- (FluxDevicePlatform)devicePlatformForModelStr:(NSString *)deviceModelStr
{
    FluxDevicePlatform devicePlatform = fdp_unknown;
    
    int stridx = 0;
    
    // i
    for (int i = 1; (i < (sizeof(fluxDeviceModelStrings) / sizeof(NSString *))); i++)
    {
        if ([deviceModelStr compare:(NSString *)fluxDeviceModelStrings[i] options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            stridx = i;
            break;
        }
    }
    
    switch (stridx)
    {
        case fdm_unknown:     // unknown
            devicePlatform = fdp_unknown;
            break;
        case fdm_x86_64:      // simulator
            devicePlatform = fdp_simulator;
            break;
            
        case fdm_iPad2_1:     // iPad 2
        case fdm_iPad2_2:     // iPad 2
        case fdm_iPad2_3:     // iPad 2
        case fdm_iPad2_4:     // iPad 2
            devicePlatform = fdp_iPad2;
            break;
        case fdm_iPad3_1:     // iPad 3
        case fdm_iPad3_2:     // iPad 3
        case fdm_iPad3_3:     // iPad 3
            devicePlatform = fdp_iPad3;
            break;
        case fdm_iPad3_4:     // iPad 4
        case fdm_iPad3_5:     // iPad 4
        case fdm_iPad3_6:     // iPad 4
            devicePlatform = fdp_iPad4;
            break;
        case fdm_iPad4_1:     // iPad Air
        case fdm_iPad4_2:     // iPad Air
            devicePlatform = fdp_iPadAir;
            break;
        
        case fdm_iPad2_5:     // iPad mini 1G
        case fdm_iPad2_6:     // iPad mini 1G
        case fdm_iPad2_7:     // iPad mini 1G
            devicePlatform = fdp_iPadMini1;
            break;
        case fdm_iPad4_4:     // iPad mini 2G (Retina)
        case fdm_iPad4_5:     // iPad mini 2G (Retina)
            devicePlatform = fdp_iPadMini2;
            break;
        
        case fdm_iPhone4_1:   // iPhone 4s
            devicePlatform = fdp_iPhone4s;
            break;
        case fdm_iPhone5_1:   // iPhone 5
        case fdm_iPhone5_2:   // iPhone 5  CDMA+GSM
            devicePlatform = fdp_iPhone5;
            break;
        case fdm_iPhone5_3:   // iPhone 5c
        case fdm_iPhone5_4:   // iPhone 5c
            devicePlatform = fdp_iPhone5c;
            break;
        case fdm_iPhone6_1:   // iPhone 5s
        case fdm_iPhone6_2:   // iPhone 5s
            devicePlatform = fdp_iPhone5s;
            break;
        
        default:    // unknown - anything else is an iPhone 5 for now...
            devicePlatform = fdp_iPhone5;
            break;
    }
    
    return devicePlatform;
}

- (FluxCameraModel *) getCameraModelForPlatform:(FluxDevicePlatform)devplatform
{
 
    FluxCameraModel *cm = [FluxCameraModel alloc];
  
    switch (devplatform)
    {
        // TODO: iPad camera models need to be defined
        case fdp_iPad2:
        case fdp_iPad3:
        case fdp_iPad4:
        case fdp_iPadAir:
        case fdp_iPadMini1:
        case fdp_iPadMini2:
            cm = [cm initWithPixelSize:0.0000014 andXPixels:1080.0 andYPixels:1080.0 andFocalLength:0.00412];
            break;
        case fdp_iPhone4s:
            cm = [cm initWithPixelSize:0.0000014 andXPixels:1080.0 andYPixels:1080.0 andFocalLength:0.00428];
            break;
        case fdp_iPhone5s:
            cm = [cm initWithPixelSize:0.0000015 andXPixels:1080.0 andYPixels:1080.0 andFocalLength:0.00412];
            break;
        case fdp_unknown:
        case fdp_simulator:
        case fdp_iPhone5:
        case fdp_iPhone5c:
        default:
            cm = [cm initWithPixelSize:0.0000014 andXPixels:1080.0 andYPixels:1080.0 andFocalLength:0.00412];
            break;
    }
    
    return cm;
}

- (int) calcRenderTextureCountForPlatform:(FluxDevicePlatform)devplatform
{
    int tc = 0;
    
    switch (devplatform)
    {
        case fdp_simulator:
        case fdp_iPadAir:
        case fdp_iPadMini2:
        case fdp_iPhone5s:
        case fdp_iPhone5:
        case fdp_iPhone5c:
            tc = 5;
            break;
        case fdp_unknown:
        case fdp_iPad2:
        case fdp_iPad3:
        case fdp_iPad4:
        case fdp_iPadMini1:
        case fdp_iPhone4s:
        default:
            tc = 3;
            break;
    }

    return tc;
}

//  - enable/disable feature matching
- (bool) getFeatureMatchingForPlatform:(FluxDevicePlatform)devplatform
{
    bool fm = true;
    
    switch (devplatform)
    {
        case fdp_simulator:
        case fdp_iPadAir:
        case fdp_iPadMini2:
        case fdp_iPhone5s:
        case fdp_iPhone5:
        case fdp_iPhone5c:
            fm = true;
            break;
        case fdp_unknown:
        case fdp_iPad2:
        case fdp_iPad3:
        case fdp_iPad4:
        case fdp_iPadMini1:
        case fdp_iPhone4s:
        default:
            fm = false;
            break;
    }
    
    return fm;
}

- (int) getCacheCountLimitForPlatform:(FluxDevicePlatform)devplatform
{
    
    int ccl = 100;
    
    switch (devplatform)
    {
            // TODO: iPad camera models need to be defined
        case fdp_simulator:
        case fdp_iPadAir:
        case fdp_iPadMini2:
        case fdp_iPhone5s:
        case fdp_iPhone5:
        case fdp_iPhone5c:
            ccl = 100;
            break;
        case fdp_unknown:
        case fdp_iPad2:
        case fdp_iPad3:
        case fdp_iPad4:
        case fdp_iPadMini1:
        case fdp_iPhone4s:
        default:
            ccl = 10;
            break;
    }
    
    return ccl;
}


//  - enable/disable feature matching
- (FluxImageType) getHighestResToQueryForPlatform:(FluxDevicePlatform)devplatform
{
    FluxImageType hrq = thumb;
    
    switch (devplatform)
    {
        case fdp_simulator:
        case fdp_iPadAir:
        case fdp_iPadMini2:
        case fdp_iPhone5s:
        case fdp_iPhone5:
        case fdp_iPhone5c:
            hrq = quarterhd;
            break;
        case fdp_unknown:
        case fdp_iPad2:
        case fdp_iPad3:
        case fdp_iPad4:
        case fdp_iPadMini1:
        case fdp_iPhone4s:
        default:
            hrq = thumb;
//            hrq = quarterhd;
            break;
    }
    
    return hrq;
}

//  - enable/disable feature matching
- (NSString *) getCaptureResForPlatform:(FluxDevicePlatform)devplatform
{
    NSString *cr = AVCaptureSessionPresetHigh;
    
    switch (devplatform)
    {
        case fdp_simulator:
        case fdp_iPadAir:
        case fdp_iPadMini2:
        case fdp_iPhone5s:
        case fdp_iPhone5:
        case fdp_iPhone5c:
            cr = AVCaptureSessionPresetHigh;
            break;
        case fdp_unknown:
        case fdp_iPad2:
        case fdp_iPad3:
        case fdp_iPad4:
        case fdp_iPadMini1:
        case fdp_iPhone4s:
        default:
            cr = AVCaptureSessionPreset1280x720;
            break;
    }
    
    return cr;
}


- (FluxCameraModel *) cameraModelForDeviceModelString:(NSString *)deviceModelString;
{
    return [self getCameraModelForPlatform:[self devicePlatformForModelStr:(NSString *)deviceModelString]];
}


@end
