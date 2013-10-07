//
//  FluxDataFilter.h
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

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
@property (nonatomic, strong) NSString *categories;

- (void)addHashTagToFilter:(NSString*)tag;
- (void)addCategoryToFilter:(NSString*)category;

- (void)removeHashTagFromFilter:(NSString*)tag;
- (void)removeCategoryFromFilter:(NSString*)category;

- (BOOL)isEqualToFilter:(FluxDataFilter*)filter;
- (id)initWithFilter:(FluxDataFilter*)filter;

- (BOOL)containsCategory:(NSString*)category;

@end
