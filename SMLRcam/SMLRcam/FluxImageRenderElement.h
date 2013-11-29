//
//  FluxImageRenderElement.h
//  Flux
//
//  Created by Denis Delorme on 10/27/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxScanImageObject.h"
#import "FluxOpenGLCommon.h"
#import "FluxTextureToImageMapElement.h"

@interface FluxImageRenderElement : NSObject
{
    
}

@property (nonatomic, strong)   FluxLocalID *localID;
@property (nonatomic, strong)   FluxScanImageObject *imageMetadata;
@property (nonatomic, strong)   NSDate *timestamp;
@property (nonatomic, strong)   NSDate *lastReferenced;
@property (nonatomic, strong)   NSDate *localCaptureTime;
@property (nonatomic, strong)   FluxTextureToImageMapElement *textureMapElement;
@property (nonatomic)           bool dirty;
@property (nonatomic, weak)     UIImage *image;
@property (nonatomic)           FluxImageType imageType;
@property (nonatomic)           FluxImageType imageFetchType;
@property (nonatomic)           sensorPose *imagePose;
//@property (nonatomic)           textureIndex;
@property (nonatomic)           viewParameters tpImageParams;

- (id)initWithImageObject:(FluxScanImageObject *)curImgObj;

@end
