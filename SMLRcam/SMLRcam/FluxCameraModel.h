//
//  FluxCameraModel.h
//  Flux
//
//  Created by Denis Delorme on 2/25/14.
//  Copyright (c) 2014 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxCameraModel : NSObject

@property (nonatomic) double pixelSize;
@property (nonatomic) double yPixels;
@property (nonatomic) double xPixels;
@property (nonatomic) double focalLength;

- (id) initWithPixelSize:(double) pixSize andXPixels:(double)xPix andYPixels:(double)yPix andFocalLength:(double)focLen;

@end
