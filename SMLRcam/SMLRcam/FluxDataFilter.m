//
//  FluxDataFilter.m
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDataFilter.h"

@implementation FluxDataFilter

- (id)init
{
    if (self = [super init])
    {
        _timeMin = [NSDate dateWithTimeIntervalSince1970:0];
        _timeMax = [NSDate distantFuture];
        _altMin = -MAXFLOAT;
        _altMax = MAXFLOAT;
        _hashTags = @"";
        _users = @"";
        _categories = @"1%20person%20place%20thing%20event";
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
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    // We'll ignore the zone for now
    FluxDataFilter *copy = [[FluxDataFilter alloc] init];
    copy.timeMin = [self.timeMin copyWithZone:zone];
    copy.timeMax = [self.timeMax copyWithZone:zone];
    copy.altMin = self.altMin;
    copy.altMax = self.altMax;
    copy.hashTags = [self.hashTags copyWithZone:zone];
    copy.users = [self.users copyWithZone:zone];
    copy.categories = [self.categories copyWithZone:zone];
    return copy;
}

- (BOOL)isEqualToFilter:(FluxDataFilter*)filter
{
    if ([_timeMin isEqualToDate:filter.timeMin] &&
        [_timeMax isEqualToDate:filter.timeMax] &&
        _altMin == filter.altMin &&
        _altMax == filter.altMax &&
        [_hashTags isEqualToString:filter.hashTags] &&
        [_users isEqualToString:filter.users] &&
        [_categories isEqualToString:filter.categories]
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

//removes the tag from the current hashtage list. Does this 3 times for each placement of the "%20" to ensure after deletion the string is always readable
- (void)removeHashTagFromFilter:(NSString*)tag{
    _hashTags = [_hashTags stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%20%@",tag] withString:@""];
    _hashTags = [_hashTags stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%%20",tag] withString:@""];
    _hashTags = [_hashTags stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",tag] withString:@""];
}
//removes the category from the current hashtage list. Does this 3 times for each placement of the "%20" to ensure after deletion the string is always readable
- (void)removeCategoryFromFilter:(NSString*)category{
    _categories = [_categories stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%20%@",category] withString:@""];
    _categories = [_categories stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%%20",category] withString:@""];
    _categories = [_categories stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",category] withString:@""];
}

- (BOOL)containsCategory:(NSString*)category{
    if ([_categories rangeOfString:category].location == NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}


@end
