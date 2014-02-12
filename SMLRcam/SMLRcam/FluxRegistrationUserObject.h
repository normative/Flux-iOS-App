//
//  FluxRegistrationUserObject.h
//  Flux
//
//  Created by Kei Turner on 2/6/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxUserObject.h"

@interface FluxRegistrationUserObject : FluxUserObject

@property (nonatomic, strong) NSString*auth_token;
@property (nonatomic, strong) NSString*facebook;
@property (nonatomic, strong) NSDictionary*twitter;
@property (nonatomic, strong) NSString*socialName;
@property (nonatomic, strong) NSString*uniqueSocialName;

@end
