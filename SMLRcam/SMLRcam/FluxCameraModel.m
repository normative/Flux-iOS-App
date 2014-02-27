//
//  FluxCameraModel.m
//  Flux
//
//  Created by Denis Delorme on 2/25/14.
//  Copyright (c) 2014 SMLR. All rights reserved.
//

#import "FluxCameraModel.h"

@implementation FluxCameraModel

- (id) initWithPixelSize:(double) pixSize andXPixels:(double)xPix andYPixels:(double)yPix andFocalLength:(double)focLen
{
    if (self = [super init])
    {
        _pixelSize = pixSize;
        _xPixels = xPix;
        _yPixels = yPix;
        _focalLength = focLen;
    }
    
    return self;
}


@end
