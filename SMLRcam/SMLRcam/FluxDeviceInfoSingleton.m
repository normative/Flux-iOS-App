//
//  FluxDeviceInfoSingleton.m
//  Flux
//
//  Created by Denis Delorme on 2/24/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxDeviceInfoSingleton.h"
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
} fluxDevicePlatform;

const NSString *fluxDevicePlatformStrings[] = {
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

+ (id)sharedInfo {
    static FluxDeviceInfoSingleton *sharedFluxDeviceInfoSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFluxDeviceInfoSingleton = [[self alloc] init];
    });
    return sharedFluxDeviceInfoSingleton;
}

- (id)init
{
    NSString *_modelStr;
    NSString *_platformStr;
    bool _featureMatchingIsEnabled = false;
    if (self = [super init])
    {
        // fetch device model and set up everything else
        struct utsname systemInfo;
        uname(&systemInfo);
        
        // model id for DB
        _modelStr = [NSString stringWithCString:systemInfo.machine
                                       encoding:NSUTF8StringEncoding];
        
        fluxDevicePlatform _devPlatform = [self devicePlatformFromModelStr:_modelStr];
        
        // model string for logs
        _platformStr = fluxDevicePlatformStrings[_devPlatform];
        
        // camera model
        // should be able to index off of _devPlatform

        // memory limits / functional restrictions
        //  - number of textures to render
        //  - enable/disable feature matching
        
        // gate feature matching
        switch (_devPlatform)
        {
            case fdp_unknown:
            case fdp_simulator:
            case fdp_iPadMini1:
            case fdp_iPadMini2:
                _featureMatchingIsEnabled = false;
                break;
            default:
                _featureMatchingIsEnabled = true;
                break;
        }
    }
    
    return self;
}


- (fluxDevicePlatform)devicePlatformFromModelStr:(NSString *)cameraModelStr
{
    fluxDevicePlatform devicePlatform = fdp_unknown;
    
    int stridx = 0;
    
    // i
    for (int i = 1; (i < (sizeof(fluxDeviceModelStrings) / sizeof(NSString *))); i++)
    {
        if ([cameraModelStr compare:(NSString *)fluxDeviceModelStrings[i] options:NSCaseInsensitiveSearch] == NSOrderedSame)
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



@end
