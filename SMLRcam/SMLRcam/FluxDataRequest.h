//
//  FluxDataRequest.h
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxCacheImageObject.h"
#import "FluxDataFilter.h"
#import "FluxDataStore.h"
#import "FluxNetworkServices.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"
#import "FluxRegistrationUserObject.h"
#import "FluxTagObject.h"
#import "FluxFilterImageCountObject.h"

typedef enum FluxDataRequestType : NSUInteger {
    no_request_specified = 0,
    time_value_request = 1,
    nearby_list_request = 2,
    metadata_request = 3,
    image_request = 4,
    data_upload_request = 5,
    tag_request = 6,
    wide_Area_list_request = 7,
    login_request = 8,
    profile_request = 9,
    profile_images_request = 10,
    profile_pic_request = 11,
    userCamera_request = 12,
    usernameUniqueness_request = 13,
    followingList_request = 15,
    followerList_request = 16,
    userSearch_request = 17,
    unfollow_request = 19,
    sendFollow_request = 20,
    acceptFollow_request = 21,
    ignoreFollow_request = 22,
    followRequest_request = 24,
    imageCounts_request = 25,
    totalImageCount_request = 26,
    createalias_request = 27,
    contactFromService_request = 28,
    imagePrivacyUpdate_request = 29,
    forceUnfollow_request = 30,
    image_matches_request = 31,
    retry_image_uploads_request = 32,
    send_password_reset_request = 33,
    updateImageCaption_request = 34

    
} FluxDataRequestType;

@class FluxDataRequest;

//images
typedef void (^ImageReadyBlock)(FluxLocalID *, FluxCacheImageObject *, FluxDataRequest *);
typedef void (^MetadataReadyBlock)(FluxScanImageObject *, FluxDataRequest *);
typedef void (^NearbyListReadyBlock)(NSArray *);
typedef void (^WideAreaListReadyBlock)(NSArray *);
typedef void (^RequestCompleteBlock)(FluxDataRequest *);
typedef void (^UploadInProgressBlock)(FluxScanImageObject *, FluxDataRequest *);
typedef void (^UploadCompleteBlock)(FluxScanImageObject *, FluxDataRequest *);
typedef void (^RetryUploadInProgressBlock)(FluxScanImageObject *, FluxDataRequest *);
typedef void (^RetryUploadCompleteBlock)(FluxScanImageObject *, FluxDataRequest *);
typedef void (^DeleteImageCompleteBlock)(int, FluxDataRequest *);
typedef void (^ImageFeaturesReadyBlock)(FluxLocalID *, NSData *, FluxDataRequest *);
typedef void (^ImageMatchesReadyBlock)(FluxLocalID *, NSArray *, FluxDataRequest *);
typedef void (^UpdateImagesPrivacyCompleteBlock)(FluxDataRequest *);
typedef void (^UpdateImageCaptionCompleteBlock)(FluxDataRequest *);

//USERS

//registration / logout
typedef void (^UploadUserCompleteBlock)(FluxRegistrationUserObject *, FluxDataRequest *);
typedef void (^LoginUserCompleteBlock)(FluxRegistrationUserObject*, FluxDataRequest *);
typedef void (^LogoutCompleteBlock)(FluxDataRequest *);
typedef void (^UsernameUniquenessCompleteBlock)(BOOL, NSString*, FluxDataRequest *);
typedef void (^PostCameraCompleteBlock)(int, FluxDataRequest *);
typedef void (^SendPasswordResetCompleteBlock)(FluxDataRequest *);

typedef void (^UpdateUserCompleteBlock)(FluxUserObject *, FluxDataRequest *);
typedef void (^UserReadyBlock)(FluxUserObject*, FluxDataRequest *);
typedef void (^UserProfilePicReadyBlock)(UIImage*,int, FluxDataRequest *);
typedef void (^UserImagesReadyBlock)(NSArray *, FluxDataRequest *);

//social
typedef void (^UserFollowerRequestsReadyBlock)(NSArray *, FluxDataRequest *);
typedef void (^UserFollowingsReadyBlock)(NSArray *, FluxDataRequest *);
typedef void (^UserFollowersReadyBlock)(NSArray *, FluxDataRequest *);
typedef void (^UserSearchReadyBlock)(NSArray *, FluxDataRequest *);

typedef void (^UnfollowUserReadyBlock)(int, FluxDataRequest *);
typedef void (^ForceUnfollowUserReadyBlock)(int, FluxDataRequest *);
typedef void (^SendFollowerRequestUserReadyBlock)(int, FluxDataRequest *);
typedef void (^AcceptFollowerRequestUserReadyBlock)(int, FluxDataRequest *);
typedef void (^IgnoreFollowerRequestUserReadyBlock)(int, FluxDataRequest *);
typedef void (^ContactListReadyBlock)(NSArray *, FluxDataRequest *);


//other
typedef void (^TagsReadyBlock)(NSArray *, FluxDataRequest *);
typedef void (^ImageCountsReadyBlock)(FluxFilterImageCountObject *, FluxDataRequest *);
typedef void (^TotalImageCountReadyBlock)(int, FluxDataRequest *);
typedef void (^ErrorBlock)(NSError *,NSString*, FluxDataRequest *);

// Data request object can store many things (parameters are optional depending on request type).
// It can store callbacks for success, failure, or for different operations.
// It can store arrays of images to download, along with a callback to
// individually process each one (either on cache retrieve or download).

@interface FluxDataRequest : NSObject
{
    // Callback for failed request
    
    // Callback for lower resolution image retrieved (might want to display temporary image)
}

@property (nonatomic, strong) FluxRequestID *requestID;
@property (nonatomic) FluxDataRequestType requestType;
@property (nonatomic) FluxImageType imageType;
@property (nonatomic, strong) FluxDataFilter *searchFilter;

// Also need properties to specify sorting order (and sort index)
@property (nonatomic, strong) NSSortDescriptor *sortDescriptor;

// Property to indicate maximum number of entries to return
@property (nonatomic) int maxReturnItems;

// Lists of requested and completed image/metadata downloads
@property (nonatomic, strong) NSMutableArray *requestedIDs;
@property (nonatomic, strong) NSMutableArray *completedIDs;

// Upload properties
@property (nonatomic, weak) FluxLocalID *uploadLocalID;
@property (nonatomic) long long totalByteSize;
@property (nonatomic) long long bytesUploaded;

// Callback for single image retrieved (either from cache or download)
@property (strong) ImageReadyBlock imageReady;

// Callback for single image feature set retrieved
@property (strong) ImageFeaturesReadyBlock imageFeaturesReady;

// Callback for single image feature set retrieved
@property (strong) ImageMatchesReadyBlock imageMatchesReady;

// Callback for single metadata object retrieved (either from cache or download)
@property (strong) MetadataReadyBlock metadataReady;

// Callback for list of images retrieved (from server only)
@property (strong) NearbyListReadyBlock nearbyListReady;

// Callback for map View array of images returned
@property (strong) WideAreaListReadyBlock wideAreaListReady;

// Callback for successful completion of entire request
@property (strong) RequestCompleteBlock requestComplete;

// Callback for successful upload of image + image metadata
@property (strong) UploadCompleteBlock uploadComplete;

// Callback for periodic updates of upload progress
@property (strong) UploadInProgressBlock uploadInProgress;

// Callback for successful upload of previously failed images + metadata
@property (strong) RetryUploadCompleteBlock retryUploadComplete;

// Callback for periodic updates of previously failed uploads progress
@property (strong) RetryUploadInProgressBlock retryUploadInProgress;

@property (strong) DeleteImageCompleteBlock deleteImageCompleteBlock;

@property (strong) UpdateImagesPrivacyCompleteBlock updateImagesPrivacyCompleteBlock;

@property (strong) UpdateImageCaptionCompleteBlock updateImageCaptionCompleteBlock;

// Callback for successful upload of user + image metadata
@property (strong) UploadUserCompleteBlock uploadUserComplete;

// Callback for successful update of user + image
@property (strong) UpdateUserCompleteBlock updateUserComplete;

// Callback for successful user login
@property (strong) LoginUserCompleteBlock loginUserComplete;

// Callback for successful user logout
@property (strong) LogoutCompleteBlock logoutComplete;

// Callback for successful reset password email send
@property (strong) SendPasswordResetCompleteBlock sendPasswordResetComplete;

// Callback for successful usernameUniqueness check
@property (strong) UsernameUniquenessCompleteBlock usernameUniquenessComplete;

// Callback for successful user camera registration
@property (strong) PostCameraCompleteBlock postCameraComplete;

// Callback for successful user profile returned
@property (strong) UserReadyBlock userReady;

// Callback for successful user profile pic returned
@property (strong) UserProfilePicReadyBlock userPicReady;

// Callback for successful user pics returned
@property (strong) UserImagesReadyBlock userImagesReady;

// Callback for successful friend requests returned
@property (strong) UserFollowerRequestsReadyBlock userFollowerRequestsReady;

// Callback for successful friends list returned
@property (strong) UserFollowingsReadyBlock userFollowingsReady;

// Callback for successful friends list returned
@property (strong) UserFollowersReadyBlock userFollowersReady;

// Callback for successful friends list returned
@property (strong) UserSearchReadyBlock userSearchReady;

// Callback for successful friends list returned
@property (strong) UnfollowUserReadyBlock unfollowUserReady;

// Callback for successful friends list returned
@property (strong) ForceUnfollowUserReadyBlock forceUnfollowUserReady;

// Callback for successful friends list returned
@property (strong) SendFollowerRequestUserReadyBlock sendFollowerRequestReady;
// Callback for successful friends list returned
@property (strong) AcceptFollowerRequestUserReadyBlock acceptFollowerRequestReady;
// Callback for successful friends list returned
@property (strong) IgnoreFollowerRequestUserReadyBlock ignoreFollowerRequestReady;
// Callback for successful contact list returned
@property (strong) ContactListReadyBlock contactListReady;


// Callback for list of tags retrieved
@property (strong) TagsReadyBlock tagsReady;
// Callback for list of tags retrieved
@property (strong) ImageCountsReadyBlock imageCountsReady;
// Callback for list of tags retrieved
@property (strong) TotalImageCountReadyBlock totalImageCountReady;

// Callback for error occurred
@property (strong) ErrorBlock errorOccurred;


//images
- (void) whenImageReady:(FluxLocalID *)localID withImage:(FluxCacheImageObject *)image withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenMetadataReady:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenNearbyListReady:(NSArray *)nearbyList;
- (void) whenWideAreaListReady:(NSArray *)wideList;
- (void) whenRequestComplete:(FluxDataRequest *)completeDataRequest;
- (void) whenUploadComplete:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUploadInProgress:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)inprogressDataRequest;
- (void) whenRetryUploadComplete:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenRetryUploadInProgress:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)inprogressDataRequest;
- (void) whenDeleteImageComplete:(int)imageID withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUpdateImagesPrivacyCompleteWithDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUpdateImageCaptionCompleteWithDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenImageFeaturesReady:(FluxLocalID *)localID withFeatures:(NSData *)features withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenImageMatchesReady:(FluxLocalID *)localID withMatches:(NSArray *)matches withDataRequest:(FluxDataRequest *)completeDataRequest;

//USERS
//registration / logout
- (void) whenUploadUserComplete:(FluxRegistrationUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenLoginUserComplete:(FluxRegistrationUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenLogoutComplete:(FluxDataRequest *)completeDataRequest;
- (void) whenUsernameCheckComplete:(BOOL)unique andSuggestion:(NSString*)suggestion withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenCameraPostCompleteWithID:(int)cameraID andDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenResetPasswordCompleteWithDataRequest:(FluxDataRequest *)completeDataRequest;

//profile stuff
- (void) whenUpdateUserComplete:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUserReady:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUserProfilePicReady:(UIImage *)profilePic forUserID:(int)userID withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUserImagesReady:(NSArray *)profileImageObjects withDataRequest:(FluxDataRequest *)completeDataRequest;

//social stuff
- (void) whenUserFollowingRequestsReady:(NSArray *)socialUserObjects withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUserFollowingsReady:(NSArray *)socialUserObjects withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUserFollowersReady:(NSArray *)socialUserObjects withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUserSearchReady:(NSArray *)socialUserObjects withDataRequest:(FluxDataRequest *)completeDataRequest;

- (void) whenUnfollowingUserReady:(int)unfollowedUserID withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenForceUnfollowingUserReady:(int)removedUserID withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenSendFollowingRequestReady:(int)userIdForFriendRequest withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenAcceptFollowerRequestReady:(int)newFriendUserID withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenIgnoreFollowerRequestReady:(int)ignoreUserID withDataRequest:(FluxDataRequest *)completeDataRequest;

- (void) whenContactListReady:(NSArray *)contacts withDataRequest:(FluxDataRequest *)completeDataRequest;


//Filters
- (void) whenTagsReady:(NSArray *)tagObjects withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenImageCountsReady:(FluxFilterImageCountObject *)countObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenTotalImageCountReady:(int)imageCount withDataRequest:(FluxDataRequest *)completeDataRequest;

//other
- (void) whenErrorOccurred:(NSError *)e withDescription:(NSString*)description withDataRequest:(FluxDataRequest *)errorDataRequest;

@end
