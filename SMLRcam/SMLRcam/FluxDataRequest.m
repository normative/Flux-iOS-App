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

#pragma mark - Images

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

- (void)whenDeleteImageComplete:(int)imageID withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.deleteImageCompleteBlock)
    {
        self.deleteImageCompleteBlock(imageID, completeDataRequest);
    }
}

#pragma mark - Users

- (void)whenUploadUserComplete:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.uploadUserComplete)
    {
        self.uploadUserComplete(userObject, completeDataRequest);
    }
}

-(void)whenLoginUserComplete:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.loginUserComplete)
    {
        self.loginUserComplete(userObject,completeDataRequest);
    }
}

-(void)whenUsernameCheckComplete:(BOOL)unique andSuggestion:(NSString *)suggestion withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.usernameUniquenessComplete)
    {
        self.usernameUniquenessComplete(unique, suggestion, completeDataRequest);
    }
}

-(void)whenCameraPostCompleteWithID:(int)cameraID andDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.postCameraComplete)
    {
        self.postCameraComplete(cameraID, completeDataRequest);
    }
}

-(void)whenUserReady:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.userReady)
    {
        self.userReady(userObject,completeDataRequest);
    }
}

-(void)whenUserProfilePicReady:(UIImage *)profilePic forUserID:(int)userID withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.userPicReady)
    {
        self.userPicReady(profilePic, userID, completeDataRequest);
    }
}

- (void)whenUserImagesReady:(NSArray *)profileImageObjects withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.userImagesReady) {
        self.userImagesReady(profileImageObjects, completeDataRequest);
    }
}

#pragma mark - Other

- (void) whenTagsReady:(NSArray *)tagObjects withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.tagsReady)
    {
        self.tagsReady(tagObjects,completeDataRequest);
    }
}

- (void) whenErrorOccurred:(NSError *)e withDescription:(NSString *)description withDataRequest:(FluxDataRequest *)errorDataRequest{
    if (self.errorOccurred)
    {
        self.errorOccurred(e,description, errorDataRequest);
    }
}

@end
