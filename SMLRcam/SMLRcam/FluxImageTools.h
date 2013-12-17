//
//  FluxImageTools.h
//  Flux
//
//  Created by Kei Turner on 10/31/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxImageTools : NSObject

-(UIImage*)blurImage:(UIImage *)img withBlurLevel:(float)blurLevel;


- (UIImage *)resizedImage:(UIImage*)image toSize:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;

@end
