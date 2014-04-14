//
//  FluxTextureToImageMapElement.h
//  Flux
//
//  Created by Denis Delorme on 10/27/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxCacheImageObject.h"
#import "FluxScanImageObject.h"

@interface FluxTextureToImageMapElement : NSObject
{
    
}

@property (nonatomic, strong)   FluxLocalID *localID;
@property (nonatomic)           FluxImageType requestedImageType;
@property (nonatomic)           FluxImageType storedImageType;
@property (nonatomic, strong)   FluxCacheImageObject *imageCacheObject;
@property (nonatomic)           NSUInteger renderOrder;
@property (nonatomic, readonly) int textureIndex;
@property (nonatomic)           bool used;
@property (nonatomic)           bool texturedLoaded;

- (id)initWithSlotIndex:(int)index;

@end
