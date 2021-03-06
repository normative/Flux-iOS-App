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
@property (nonatomic, strong) NSString *aliasName;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *profilePicURL;
@property (nonatomic, strong) NSString *socialID;
@property (nonatomic, strong) NSArray *emails;
@property (nonatomic, strong) UIImage* profilePic;
@property (nonatomic) int isFollowingFlag;
@property (nonatomic) int amFollowerFlag;
@property (nonatomic) BOOL inviteSending;
@property (nonatomic) BOOL inviteSent;

@end
