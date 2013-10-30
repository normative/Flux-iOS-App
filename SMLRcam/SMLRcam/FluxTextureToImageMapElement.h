//
//  FluxTextureToImageMapElement.h
//  Flux
//
//  Created by Denis Delorme on 10/27/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxScanImageObject.h"

@interface FluxTextureToImageMapElement : NSObject
{
    
}

@property (nonatomic, strong)   FluxLocalID *localID;
@property (nonatomic)           FluxImageType imageType;
@property (nonatomic)           int textureIndex;
@property (nonatomic)           bool used;


@end
