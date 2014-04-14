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

- (void) whenImageReady:(FluxLocalID *)localID withImage:(FluxCacheImageObject *)image withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.imageReady)
    {
        self.imageReady(localID, image, completeDataRequest);
    }
}

- (void) whenImageFeaturesReady:(FluxLocalID *)localID withFeatures:(NSData *)features withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.imageFeaturesReady)
    {
        self.imageFeaturesReady(localID, features, completeDataRequest);
    }
}

- (void) whenImageMatchesReady:(FluxLocalID *)localID withMatches:(NSArray *)matches withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.imageMatchesReady)
    {
        self.imageMatchesReady(localID, matches, completeDataRequest);
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

- (void)whenRetryUploadComplete:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.retryUploadComplete)
    {
        self.retryUploadComplete(imageObject, completeDataRequest);
    }
}

- (void) whenRetryUploadInProgress:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)inprogressDataRequest
{
    if (self.retryUploadInProgress)
    {
        self.retryUploadInProgress(imageObject, inprogressDataRequest);
    }
}

- (void)whenDeleteImageComplete:(int)imageID withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.deleteImageCompleteBlock)
    {
        self.deleteImageCompleteBlock(imageID, completeDataRequest);
    }
}

-(void)whenUpdateImagesPrivacyCompleteWithDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.updateImagesPrivacyCompleteBlock)
    {
        self.updateImagesPrivacyCompleteBlock(completeDataRequest);
    }
}

#pragma mark - Users


#pragma mark Registration

- (void)whenUploadUserComplete:(FluxRegistrationUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.uploadUserComplete)
    {
        self.uploadUserComplete(userObject, completeDataRequest);
    }
}

- (void)whenUpdateUserComplete:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.updateUserComplete)
    {
        self.updateUserComplete(userObject, completeDataRequest);
    }
}

-(void)whenLoginUserComplete:(FluxRegistrationUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.loginUserComplete)
    {
        self.loginUserComplete(userObject,completeDataRequest);
    }
}

-(void)whenLogoutComplete:(FluxDataRequest *)completeDataRequest{
    if (self.logoutComplete)
    {
        self.logoutComplete(completeDataRequest);
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

#pragma mark Profile Stuff

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

#pragma mark Social Stuff
- (void) whenUserFollowingRequestsReady:(NSArray *)socialUserObjects withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.userFollowerRequestsReady) {
        self.userFollowerRequestsReady(socialUserObjects, completeDataRequest);
    }
}
- (void) whenUserFollowingsReady:(NSArray *)socialUserObjects withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.userFollowingsReady) {
        self.userFollowingsReady(socialUserObjects, completeDataRequest);
    }
}
- (void) whenUserFollowersReady:(NSArray *)socialUserObjects withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.userFollowersReady) {
        self.userFollowersReady(socialUserObjects, completeDataRequest);
    }
}

- (void) whenUserSearchReady:(NSArray *)socialUserObjects withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.userSearchReady) {
        self.userSearchReady(socialUserObjects, completeDataRequest);
    }
}
- (void) whenUnfollowingUserReady:(int)unfollowedUserID withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.unfollowUserReady) {
        self.unfollowUserReady(unfollowedUserID, completeDataRequest);
    }
}
- (void) whenForceUnfollowingUserReady:(int)removedUserID withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.forceUnfollowUserReady) {
        self.forceUnfollowUserReady(removedUserID, completeDataRequest);
    }
}

- (void) whenSendFollowingRequestReady:(int)userIdForFriendRequest withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.sendFollowerRequestReady) {
        self.sendFollowerRequestReady(userIdForFriendRequest, completeDataRequest);
    }
}
- (void) whenAcceptFollowerRequestReady:(int)newFriendUserID withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.acceptFollowerRequestReady) {
        self.acceptFollowerRequestReady(newFriendUserID, completeDataRequest);
    }
}
- (void) whenIgnoreFollowerRequestReady:(int)ignoreUserID withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.ignoreFollowerRequestReady) {
        self.ignoreFollowerRequestReady(ignoreUserID, completeDataRequest);
    }
}

- (void) whenContactListReady:(NSArray *)contacts withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.contactListReady) {
        self.contactListReady(contacts, completeDataRequest);
    }
}

#pragma mark - Filters

- (void) whenTagsReady:(NSArray *)tagObjects withDataRequest:(FluxDataRequest *)completeDataRequest
{
    if (self.tagsReady)
    {
        self.tagsReady(tagObjects,completeDataRequest);
    }
}

- (void) whenImageCountsReady:(FluxFilterImageCountObject *)countObject withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.imageCountsReady) {
        self.imageCountsReady(countObject, completeDataRequest);
    }
}
- (void) whenTotalImageCountReady:(int)imageCount withDataRequest:(FluxDataRequest *)completeDataRequest{
    if (self.totalImageCountReady) {
        self.totalImageCountReady(imageCount, completeDataRequest);
    }
}


#pragma mark - Other
- (void) whenErrorOccurred:(NSError *)e withDescription:(NSString *)description withDataRequest:(FluxDataRequest *)errorDataRequest{
    if (self.errorOccurred)
    {
        self.errorOccurred(e,description, errorDataRequest);
    }
}

@end
