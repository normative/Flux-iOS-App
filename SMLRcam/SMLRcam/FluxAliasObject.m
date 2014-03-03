//
//  FluxAliasObject.m
//  Flux
//
//  Created by Denis Delorme on 2/19/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxAliasObject.h"

@implementation FluxAliasObject

- (id)initWithName: (NSString *)social_name
      andServiceID: (int)service_id
{
    self = [super init];
    if (self)
    {
        self.userID = 0;
        self.alias_name = social_name;
        self.serviceID = service_id;
    }
    return self;
}
@end
