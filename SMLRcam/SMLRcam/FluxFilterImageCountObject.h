//
//  FluxFilterImageCountObject.h
//  Flux
//
//  Created by Kei Turner on 2/18/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxFilterImageCountObject : NSObject

@property (nonatomic) int totalImageCount;
@property (nonatomic) int activeUserImageCount;
@property (nonatomic) int activerUserFriendsImageCount;
@property (nonatomic) int activerUserFollowingsImageCount;

@end
