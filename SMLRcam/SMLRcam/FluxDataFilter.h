//
//  FluxDataFilter.h
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum
FluxFilterType: NSUInteger {
    myPhotos_filterType = 0,
    followers_filterType = 1,
    friends_filterType = 2,
    tags_filterType = 3,
} FluxFilterType;

@interface FluxDataFilter : NSObject
{

}

// Since every request has a location and radius associated with it,
// these are not added to the filter.

@property (nonatomic, strong) NSDate *timeMin;
@property (nonatomic, strong) NSDate *timeMax;
@property (nonatomic) float altMin;
@property (nonatomic) float altMax;
@property (nonatomic, strong) NSString *hashTags;
@property (nonatomic, strong) NSString *users;
@property (nonatomic)BOOL isFriendsFiltered;
@property (nonatomic)BOOL isFollowingFiltered;
@property (nonatomic)BOOL isActiveUserFiltered;

- (void)addHashTagToFilter:(NSString*)tag;
- (void)removeHashTagFromFilter:(NSString*)tag;

- (void)addUsersToFilter:(NSArray*)filteredUsers andType:(FluxFilterType)type;
- (void)removeUsersFromFilter:(NSArray*)filteredUsers andType:(FluxFilterType)type;

- (BOOL)isEqualToFilter:(FluxDataFilter*)filter;
- (id)initWithFilter:(FluxDataFilter*)filter;




@end
