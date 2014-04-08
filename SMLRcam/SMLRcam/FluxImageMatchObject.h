//
//  FluxImageMatchObject.h
//  Flux
//
//  Created by Denis Delorme on 4/3/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxImageMatchObject : NSObject

@property (nonatomic)uint64_t image_id;
@property (nonatomic)uint64_t matching_id;
@property (nonatomic)double qw;
@property (nonatomic)double qx;
@property (nonatomic)double qy;
@property (nonatomic)double qz;
@property (nonatomic)double t1;
@property (nonatomic)double t2;
@property (nonatomic)double t3;

@end

