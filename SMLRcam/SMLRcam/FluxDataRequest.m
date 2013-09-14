//
//  FluxDataRequest.m
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDataRequest.h"

@implementation FluxDataRequest

- (id)init
{
    if (self = [super init])
    {
        _completedIDs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) whenImageReady:(FluxLocalID *)localID withImage:(UIImage *)image withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.imageReady)
    {
        self.imageReady(localID, image, completeDataRequest);
    }
}

- (void) whenMetadataReady:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.metadataReady)
    {
        self.metadataReady(imageObject, completeDataRequest);
    }
}

- (void) whenNearbyListReady:(NSMutableDictionary *)nearbyList
{
    if (self.nearbyListReady)
    {
        self.nearbyListReady(nearbyList);
    }
}

- (void) whenRequestComplete:(FluxDataRequest *)completeDataRequest
{
    if (self.requestComplete)
    {
        self.requestComplete(completeDataRequest);
    }
}

@end
