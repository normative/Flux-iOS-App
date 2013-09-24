//
//  FluxTimeObject.h
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

//this object is mapped by RestKit
@interface FluxTimeObject : NSObject

@property (nonatomic, weak)NSDate* startDate;
@property (nonatomic, weak)NSDate* endDate;
@property (nonatomic)int count;

@end
