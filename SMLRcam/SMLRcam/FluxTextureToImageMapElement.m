//
//  FluxTextureToImageMapElement.m
//  Flux
//
//  Created by Denis Delorme on 10/27/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxTextureToImageMapElement.h"

@implementation FluxTextureToImageMapElement

- (id)init
{
    self = [super init];
    if (self)
    {
        _localID = @"";
        _imageType = none;
        _textureIndex = -1;
        _used = false;
    }
    
    return self;
}

@end
