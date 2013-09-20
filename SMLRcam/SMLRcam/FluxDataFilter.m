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
        _timeMin = [NSDate dateWithTimeIntervalSince1970:0];
        _timeMax = [NSDate date];
        _altMin = -MAXFLOAT;
        _altMax = MAXFLOAT;
        _hashTags = @"";
        _users = @"";
        _categories = @"1%20person%20place%20thing%20event";
        
        _maxReturnItems = INT_MAX;
        
    }
    return self;
}

-(id)initWithFilter:(FluxDataFilter*)filter
{
    if (self = [super init])
    {
        _timeMin = filter.timeMin;
        _timeMax = filter.timeMax;
        _altMin = filter.altMin;
        _altMax = filter.altMax;
        _hashTags = filter.hashTags;
        _users = filter.users;
        _categories = filter.categories;
        
        _maxReturnItems = filter.maxReturnItems;
        
    }
    return self;
}

- (BOOL)isEqualToFilter:(FluxDataFilter*)filter
{
    if ([_timeMin isEqualToDate:filter.timeMin] &&
        [_timeMax isEqualToDate:filter.timeMax] &&
        _altMin == filter.altMin &&
        _altMax == filter.altMax &&
        [_hashTags isEqualToString:filter.hashTags] &&
        [_users isEqualToString:filter.users] &&
        [_categories isEqualToString:filter.categories] &&
        _maxReturnItems == filter.maxReturnItems
        ) {
        return YES;
    }
    return NO;
}

- (void)addHashTagToFilter:(NSString*)tag{
    if ([_hashTags isEqualToString:@""]) {
        _hashTags = tag;
    }
    else{
        if ([_hashTags rangeOfString:tag].location == NSNotFound) {
            _hashTags = [_hashTags stringByAppendingString:[NSString stringWithFormat:@"%%20%@",tag]];
        }
    }
}
- (void)addCategoryToFilter:(NSString*)category{
    if ([_categories isEqualToString:@""]) {
        _categories = category;
    }
    else{
        if ([_categories rangeOfString:category].location == NSNotFound) {
             _categories = [_categories stringByAppendingString:[NSString stringWithFormat:@"%%20%@",category]];
        }
    }
}

- (void)removeHashTagFromFilter:(NSString*)tag{
    _hashTags = [_hashTags stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%20%@",tag] withString:@""];
}
- (void)removeCategoryFromFilter:(NSString*)category{
    _categories = [_categories stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%20%@",category] withString:@""];
}


@end
