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
@property (nonatomic)           FluxImageType imageType;
@property (nonatomic, strong)   FluxCacheImageObject *imageCacheObject;
@property (nonatomic)           NSUInteger renderOrder;
@property (nonatomic, readonly) int textureIndex;
@property (nonatomic)           bool used;

- (id)initWithSlotIndex:(int)index;

@end
