//
//  FluxLoggerService.h
//  Flux
//
//  Created by Ryan Martens on 3/4/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxLoggerService : NSObject

@property (nonatomic, strong) NSMutableArray *errorLogData;

+ (id)sharedLoggerService;

@end
