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
        _imageType = none;
        _renderOrder = 0;
        _textureIndex = index;
        _used = false;
    }
    
    return self;
}

@end
