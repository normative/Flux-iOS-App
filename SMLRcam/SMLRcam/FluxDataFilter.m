//
//  FluxDataFilter.m
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDataFilter.h"

@implementation FluxDataFilter

- (id)init
{
    if (self = [super init])
    {
        _timeMin = nil;
        _timeMax = nil;
        _altMin = -MAXFLOAT;
        _altMax = MAXFLOAT;
        _hashTags = @"''";
        _users = @"''";
        _categories = @"''";
        
        _maxReturnItems = INT_MAX;
    }
    return self;
}

@end
