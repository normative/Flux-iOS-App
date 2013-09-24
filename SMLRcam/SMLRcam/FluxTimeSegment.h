//
//  FluxTimeSegment.h
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

//This class is a collection of timeSegments, that also has a type
enum timeSegment_type {
    infinite = 0,
    year = 1,
    month = 2,
    week = 3,
    day = 4
};

@class FluxTimeSegment;
typedef enum timeSegment_type timeSegment_type;


@interface FluxTimeSegment : NSObject

@property (nonatomic) timeSegment_type timeSegment_type;
@property (nonatomic,weak)NSArray*timeSegments;

- (id)initWithType:(timeSegment_type)type andSegments:(NSArray*)segments;

@end
