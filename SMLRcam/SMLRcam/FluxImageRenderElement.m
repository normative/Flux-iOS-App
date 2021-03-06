//
//  FluxImageRenderElement.m
//  Flux
//
//  Created by Denis Delorme on 10/27/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxImageRenderElement.h"

@implementation FluxImageRenderElement

- (id)init
{
    self = [super init];
    if (self)
    {
        _localID = @"";
        _imageMetadata = nil;
        _lastReferenced = nil;
        _localCaptureTime = nil;
        _imageRenderType = none;
        _imageTypesFetched = FluxImageTypeMaskNone;
        // TODO: this allocation needs to be de-allocated at object destruction time....
        _imagePose = malloc(sizeof(sensorPose));
    }
    
    return self;
}

- (id)initWithImageObject:(FluxScanImageObject *)curImgObj
{
    self = [super init];
    if (self)
    {
        if (curImgObj != nil)
        {
            _localID = curImgObj.localID;
            _imageMetadata = curImgObj;
            _timestamp = curImgObj.timestamp;
            _lastReferenced = [[NSDate alloc]init];
            _localCaptureTime = [[NSDate alloc]initWithTimeIntervalSince1970:0];
            _imageRenderType = none;
            _imageTypesFetched = FluxImageTypeMaskNone;
            _imagePose = malloc(sizeof(sensorPose));
        }
    }
    
    return self;
}

@end
