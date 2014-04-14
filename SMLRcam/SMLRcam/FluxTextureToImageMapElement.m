//
//  FluxTextureToImageMapElement.m
//  Flux
//
//  Created by Denis Delorme on 10/27/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxTextureToImageMapElement.h"

@implementation FluxTextureToImageMapElement

- (id)initWithSlotIndex:(int)index
{
    self = [super init];
    if (self)
    {
        _localID = @"";
        _requestedImageType = none;
        _storedImageType = none;
        _renderOrder = NSUIntegerMax;
        _textureIndex = index;
        _used = NO;
        _texturedLoaded = NO;
    }
    
    return self;
}

@end
