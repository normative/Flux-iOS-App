//
//  FluxFilterDrawerObject.m
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFilterDrawerObject.h"

@implementation FluxFilterDrawerObject

@synthesize title;


- (id)initWithTitle:(NSString*)atitle andFilterType:(FluxFilterType)type{
self = [super init];
    if (self) {
        self.title = atitle;
        self.filterType = type;
        self.count = 0;
    }
    
    return self;
}

@end
