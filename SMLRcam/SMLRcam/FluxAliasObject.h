//
//  FluxAliasObject.h
//  Flux
//
//  Created by Denis Delorme on 2/19/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxAliasObject : NSObject

@property (nonatomic, strong) NSString* alias_name;
@property (nonatomic) int userID;
@property (nonatomic) int serviceID;

- (id)initWithName: (NSString *)social_name
      andServiceID: (int)service_id;
@end

