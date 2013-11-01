//
//  FluxTagObject.m
//  Flux
//
//  Created by Kei Turner on 2013-09-12.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxTagObject.h"

@implementation FluxTagObject

- (BOOL)isEqual:(id)object
{
    //compare nsstirng to tagObject
    if ([object isKindOfClass:[NSString class]]) {
        return [self.tagText isEqualToString:object];
    }
    if ([object isKindOfClass:[self class]]) {
        FluxTagObject*tmp = (FluxTagObject*)object;
        return [self.tagText isEqualToString:tmp.tagText];
    }
    return NO;
}

- (NSUInteger)hash
{
    return (NSUInteger)self;
}

- (void)setIsActive:(BOOL)active{
    self.isChecked = active;
}

@end
