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
        _categories = @"";
        
        _maxReturnItems = INT_MAX;
        
    }
    return self;
}

- (void)addHashTagToFilter:(NSString*)tag{
    if ([_hashTags isEqualToString:@""]) {
        _hashTags = tag;
    }
    else{
        _hashTags = [_hashTags stringByAppendingString:[NSString stringWithFormat:@"%%20%@",tag]];
    }
}
- (void)addCategoryToFilter:(NSString*)category{
    if ([_categories isEqualToString:@""]) {
        _categories = category;
    }
    else{
        _categories = [_categories stringByAppendingString:[NSString stringWithFormat:@"%%20%@",category]];
    }
}

- (void)removeHashTagFromFilter:(NSString*)tag{
    _hashTags = [_hashTags stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%20%@",tag] withString:@""];
}
- (void)removeCategoryFromFilter:(NSString*)category{
    _categories = [_categories stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%%20%@",category] withString:@""];
}


@end
