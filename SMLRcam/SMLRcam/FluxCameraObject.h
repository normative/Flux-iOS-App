//
//  FluxCameraObject.h
//  Flux
//
//  Created by Kei Turner on 12/9/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxCameraObject : NSObject

@property (nonatomic, strong)NSString*deviceID;
@property (nonatomic, strong)NSString*model;
@property (nonatomic)int userID;

- (id)initWithdeviceID:(NSString*)theDeviceID
   model:(NSString*)theModel
     forUserID:(int)theUserID;

@end
