//
//  FluxConnectionObject.h
//  Flux
//
//  Created by Kei Turner on 2/7/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

extern int const FluxConnectionState_friend;
extern int const FluxConnectionState_follow;
extern int const FluxConnectionState_followANDFriend;

extern int const FluxFriendState_ignore;
extern int const FluxFriendState_accept;

@interface FluxConnectionObject : NSObject

@property (nonatomic) int connectionID;
@property (nonatomic) int userID;
@property (nonatomic) int connectionsUserID;
@property (nonatomic) int connetionType;


@property (nonatomic) int friendState;
@property (nonatomic) BOOL amFollowing;
@end
