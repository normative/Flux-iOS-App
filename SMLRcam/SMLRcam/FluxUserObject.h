//
//  FluxUserObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxUserObject : NSObject

@property (nonatomic) int userID;
@property (nonatomic, strong) NSString*name;
@property (nonatomic, strong) NSString*username;
@property (nonatomic, strong) NSString*password;
@property (nonatomic, strong) NSString*email;
@property (nonatomic, strong) NSString*bio;
@property (nonatomic, strong) NSString*auth_token;
@property (nonatomic, strong) UIImage*profilePic;


@end
