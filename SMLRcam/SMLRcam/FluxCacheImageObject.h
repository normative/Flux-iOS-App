//
//  FluxCacheImageObject.h
//  Flux
//
//  Created by Ryan Martens on 1/6/14.
//  Copyright (c) 2014 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxScanImageObject.h"

@interface FluxCacheImageObject : NSObject <NSDiscardableContent>

@property (nonatomic, strong) UIImage *image;
@property (nonatomic) NSUInteger accessCount;
@property (nonatomic, strong) FluxLocalID *localID;
@property (nonatomic) FluxImageType imageType;

+ (FluxCacheImageObject *)cacheImageObject:(UIImage *)image withID:(FluxLocalID *)localID withType:(FluxImageType)type;

@end
