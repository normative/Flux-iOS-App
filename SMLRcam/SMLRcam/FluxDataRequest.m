//
//  FluxDataRequest.m
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDataRequest.h"

@implementation FluxDataRequest

- (id)init
{
    if (self = [super init])
    {
        _completedIDs = [[NSMutableArray alloc] init];
        _requestID = [[NSUUID alloc] init];
        _maxReturnItems = INT_MAX;
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

- (void) whenNearbyListReady:(NSArray *)nearbyList
{
    if (self.nearbyListReady)
    {
        self.nearbyListReady(nearbyList);
    }
}

- (void) whenWideAreaListReady:(NSArray *)wideList{
    if (self.wideAreaListReady)
    {
        self.wideAreaListReady(wideList);
    }
}

- (void) whenRequestComplete:(FluxDataRequest *)completeDataRequest
{
    if (self.requestComplete)
    {
        self.requestComplete(completeDataRequest);
    }
}

- (void) whenUploadComplete:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.uploadComplete)
    {
        self.uploadComplete(imageObject, completeDataRequest);
    }
}

- (void) whenUploadInProgress:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)inprogressDataRequest
{
    if (self.uploadInProgress)
    {
        self.uploadInProgress(imageObject, inprogressDataRequest);
    }
}

- (void) whenTagsReady:(NSArray *)tagObjects withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.tagsReady)
    {
        self.tagsReady(tagObjects,completeDataRequest);
    }
}

- (void) whenErrorOccurred:(NSError *)e withDataRequest:(FluxDataRequest *)errorDataRequest
{
    if (self.errorOccurred)
    {
        self.errorOccurred(e, errorDataRequest);
    }
}

@end
