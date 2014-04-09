//
//  FluxCameraObject.m
//  Flux
//
//  Created by Kei Turner on 12/9/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxCameraObject.h"
#import "FluxDeviceInfoSingleton.h"


@implementation FluxCameraObject

- (id)initWithdeviceID:(NSString*)theDeviceID model:(NSString *)theModel forUserID:(int)theUserID{
    self = [super init];
    if (self) {
        self.deviceID = theDeviceID;
        self.model = theModel;
        self.userID = theUserID;
    }
    return self;
}

- (NSString *)currAppVersion
{
    return [FluxDeviceInfoSingleton currentAppVersionString];
}

@end
