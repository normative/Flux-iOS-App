//
//  FluxCacheImageObject.m
//  Flux
//
//  Created by Ryan Martens on 1/6/14.
//  Copyright (c) 2014 SMLR. All rights reserved.
//

#import "FluxCacheImageObject.h"

@implementation FluxCacheImageObject

+ (FluxCacheImageObject *)cacheImageObject:(UIImage *)image withID:(NSString *)localID withType:(FluxImageType)type
{
    FluxCacheImageObject *discardable = [[FluxCacheImageObject alloc] init];
    
    discardable.image = image;
    discardable.accessCount = 1u;
    
    discardable.localID = localID;
    discardable.imageType = type;
    
    return discardable;
}

- (BOOL)beginContentAccess
{
    if (!self.image)
    {
        return NO;
    }
    
    self.accessCount = self.accessCount + 1;
    
    return YES;
}

- (void)endContentAccess
{
    if (self.accessCount)
    {
        self.accessCount = self.accessCount - 1;
    }
}

- (void)discardContentIfPossible
{
    if (!self.accessCount)
    {
        self.image = nil;
    }
}

- (BOOL)isContentDiscarded
{
    return (self.image == nil);
}

@end
