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
        _isActiveUserFiltered = NO;
        _isFollowingFiltered = NO;
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
        _isActiveUserFiltered = filter.isActiveUserFiltered;
        _isFollowingFiltered = filter.isFollowingFiltered;
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
    copy.isActiveUserFiltered = self.isActiveUserFiltered;
    copy.isFollowingFiltered = self.isFollowingFiltered;
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
        _isActiveUserFiltered == filter.isActiveUserFiltered &&
        _isFollowingFiltered == filter.isFollowingFiltered
        ) {
        return YES;
    }
    return NO;
}

- (void)addHashTagToFilter:(NSString*)tag{
    self.hashTags = [self addString:tag toFilter:self.hashTags];
}
//removes the tag from the current hashtage list. Does this 3 times for each placement of the "%20" to ensure after deletion the string is always readable
- (void)removeHashTagFromFilter:(NSString*)tag{
    self.hashTags = [self RemoveString:tag fromFilter:self.hashTags];
}

- (NSString*)addString:(NSString*)parameter toFilter:(NSString*)filter{
    if ([filter isEqualToString:@""]) {
        filter = parameter;
    }
    else{
        if ([filter rangeOfString:parameter].location == NSNotFound) {
            filter = [filter stringByAppendingString:[NSString stringWithFormat:@" %@",parameter]];
        }
    }
    return filter;
}

- (NSString*)RemoveString:(NSString*)parameter fromFilter:(NSString*)filter{
    filter = [filter stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@" %@",parameter] withString:@""];
    filter = [filter stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@ ",parameter] withString:@""];
    filter = [filter stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",parameter] withString:@""];
    return filter;
}



- (void)addUsersToFilter:(NSArray*)filteredUsers andType:(FluxFilterType)type{
    if (type == followers_filterType) {
        self.isFollowingFiltered = YES;
    }
}
- (void)removeUsersFromFilter:(NSArray*)filteredUsers andType:(FluxFilterType)type{
    if (type == followers_filterType) {
        self.isFollowingFiltered = NO;
    }
}


@end
