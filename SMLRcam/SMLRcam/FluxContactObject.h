//
//  FluxContactObject.h
//  Flux
//
//  Created by Denis Delorme on 2/24/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxContactObject : NSObject

@property (nonatomic) int userID;
@property (nonatomic, strong) NSString *alias_name;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *display_name;
@property (nonatomic, strong) NSString *profile_pic_URL;
@property (nonatomic) int friendState;
@property (nonatomic) BOOL amFollower;
@property (nonatomic) BOOL isFollowing;

@end
