//
//  FluxAPIInteraction.h
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"
#import "FluxRegistrationUserObject.h"
#import "FluxCameraObject.h"
#import <CoreLocation/CoreLocation.h>
#import "RKObjectManager.h"

typedef NSUUID FluxRequestID;

extern NSString* const FluxProductionServerURL;
extern NSString* const FluxTestServerURL;

@class FluxNetworkServices;
@protocol NetworkServicesDelegate <NSObject>
@optional
//images
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImage:(UIImage *)image forImageID:(int)imageID
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageMetadata:(FluxScanImageObject *)imageObject
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageList:(NSArray *)imageList
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUploadImage:(FluxScanImageObject *)updatedImageObject
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices uploadProgress:(long long)bytesSent
            ofExpectedPacketSize:(long long)size andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailWithError:(NSError*)e andNaturalString:(NSString*)string
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailImageDownloadWithError:(NSError*)e andNaturalString:(NSString*)string
           andRequestID:(FluxRequestID *)requestID andImageID:(FluxImageID)imageID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didDeleteImageWithID:(int)imageID
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageFeatures:(NSData *)features forImageID:(int)imageID
           andRequestID:(FluxRequestID *)requestID;

//maps
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnMapList:(NSArray*)imageList
           andRequestID:(FluxRequestID *)requestID;

//USERS

//registration/logout
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didCreateUser:(FluxRegistrationUserObject*)userObject
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didLoginUser:(FluxRegistrationUserObject*)userObject
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didCheckUsernameUniqueness:(BOOL)unique andSuggestion:(NSString*)suggestion
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didPostCameraWithID:(int)camID andRequestID:(FluxRequestID *)requestID;

//profile stuff
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUpdateUser:(FluxUserObject*)userObject
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnUser:(FluxUserObject *)user
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnProfileImage:(UIImage *)image forUserID:(int)user
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnImageListForUser:(NSArray*)images
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didLogoutWithRequestID:(FluxRequestID *)requestID;

//social stuff
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnFriendListForUser:(NSArray*)friends
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnFollowingListForUser:(NSArray*)followings
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnFollowerListForUser:(NSArray*)followers
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnUsersListForQuery:(NSArray*)users
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFollowUserWithID:(int)userID
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUnfollowUserWithID:(int)userID
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didSendFriendRequestToUserWithID:(int)userID
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didAcceptFriendRequestFromUserWithID:(int)userID
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didIgnoreFriendRequestFromUserWithID:(int)userID
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUnfriendUserWithID:(int)userID
           andRequestID:(FluxRequestID *)requestID;

//tags
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnTagList:(NSArray*)tagList
           andRequestID:(FluxRequestID *)requestID;

@end

@interface FluxNetworkServices : NSObject{
    RKObjectManager *objectManager;
    __weak id <NetworkServicesDelegate> delegate;
}
@property (nonatomic, weak) id <NetworkServicesDelegate> delegate;
@property (nonatomic, strong)NSString*serverString;
//@property (nonatomic, getter = get_token) NSString *token;


#pragma mark - image methods

/**
 returns the raw image given an imageID
 **/
- (void)getImageForID:(int)imageID withStringSize:(NSString *)sizeString andRequestID:(FluxRequestID *)requestID;

/**
 returns an image object given an imageID
 **/
- (void)getImageMetadataForID:(int)imageID andRequestID:(FluxRequestID *)requestID;

/**
 returns an NSDictionary list of images at a given location within a given radius
 **/
- (void)getImagesForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius andRequestID:(FluxRequestID *)requestID;

/**
 returns an NSDictionary list of images filtered based on provided details
 **/
- (void)getImagesForLocationFiltered:(CLLocationCoordinate2D)location
                           andRadius:(float)radius
                           andMinAlt:(float)altMin
                           andMaxAlt:(float)altMax
                     andMinTimestamp:(NSDate *)timeMin
                     andMaxTimestamp:(NSDate *)timeMax
                         andHashTags:(NSString *)hashTags
                            andUsers:(NSString *)users
                         andMaxCount:(int)maxCount
                        andRequestID:(FluxRequestID *)requestID;

/**
 returns an NSDictionary list of images for mapView filtered based on provided details
 **/
- (void)getMapImagesForLocationFiltered:(CLLocationCoordinate2D)location
                           andRadius:(float)radius
                           andMinAlt:(float)altMin
                           andMaxAlt:(float)altMax
                     andMinTimestamp:(NSDate *)timeMin
                     andMaxTimestamp:(NSDate *)timeMax
                         andHashTags:(NSString *)hashTags
                            andUsers:(NSString *)users
                         andMaxCount:(int)maxCount
                        andRequestID:(FluxRequestID *)requestID;

// execute the request
- (void)doRequest:(NSURLRequest *)request withResponseDesc:(RKResponseDescriptor *)responseDescriptor andRequestID:(FluxRequestID *)requestID;

/**
 uploads an image. All account info is stored within the FluxScanImageObject
 **/
- (void)uploadImage:(FluxScanImageObject*)theImageObject andImage:(UIImage *)theImage andRequestID:(FluxRequestID *)requestID;

/**
 Removes an image from the Flux DB given an imageID.
 **/
- (void)deleteImageWithID:(int)imageID andRequestID:(NSUUID *)requestID;

#pragma mark  Features

/**
 returns NSXMLParser containing image features based on given imageID
 **/

- (void)getImageFeaturesForID:(int)imageID andRequestID:(FluxRequestID *)requestID;

#pragma mark  - Users

#pragma mark  Registration / Logout
/**
 Logs in a given userObject and returns an access token
 **/
- (void)loginUser:(FluxRegistrationUserObject*)userObject withRequestID:(FluxRequestID *)requestID;

/**
 Log out the current user
 **/
- (void)logoutWithRequestID:(FluxRequestID *)requestID;

/**
 checks the 'uniqueness' of a given username and returns a BOOL along with a suggested alternate
 **/
- (void)checkUsernameUniqueness:(NSString*)username withRequestID:(FluxRequestID *)requestID;

/**
 Posts a given camera object to the database.
 **/
- (void)postCamera:(FluxCameraObject*)cameraObject withRequestID:(FluxRequestID *)requestID;

/**
 creates a user with the given object
 **/
- (void)createUser:(FluxRegistrationUserObject*)userObject withImage:(UIImage*)theImage andRequestID:(FluxRequestID *)requestID;

#pragma mark Profiles

/**
returns a complete userObject for a given userID
 **/
- (void)getUserForID:(int)userID withRequestID:(FluxRequestID *)requestID;

/**
 updates a a user profile with the supplied object
 **/
- (void)updateUser:(FluxUserObject*)userObject withImage:(UIImage*)theImage andRequestID:(FluxRequestID *)requestID;

/**
return's a profile image for a given userID and size
 **/
- (void)getUserProfilePicForID:(int)userID withStringSize:(NSString *)sizeString withRequestID:(NSUUID *)requestID;

/**
 return's a user's image list for a given userID
 **/
- (void)getImagesListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID;


#pragma mark Social Stuff
/**
 return's a user's friend list for a given userID
 **/
- (void)getFriendsListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID;

/**
 return's a user's following list for a given userID
 **/
- (void)getFollowingListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID;

/**
 return's a user's follower list for a given userID
 **/
- (void)getFollowerListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID;

/**
 return's a list of users matching a given query
 **/
- (void)getUsersListForQuery:(NSString*)query withRequestID:(NSUUID *)requestID;

/**
 Adds the supplied userID as a follower of the activeUser
 **/
- (void)followUserID:(int)userID withRequestID:(NSUUID *)requestID;

/**
 removes the supplied userID as a follower of the activeUser
 **/
- (void)unfollowUserID:(int)userID withRequestID:(NSUUID *)requestID;

/**
 sends the supplied userID as a friend request from the activeUser
 **/
- (void)sendFriendRequestToUserWithID:(int)userID withRequestID:(NSUUID *)requestID;

/**
 accepts the friend request from the supplied userID from the activeUser
 **/
- (void)acceptFriendRequestFromUserWithID:(int)userID withRequestID:(NSUUID *)requestID;

/**
 ignores the friend request from the supplied userID from the activeUser
 **/
- (void)ignoreFriendRequestFromUserWithID:(int)userID withRequestID:(NSUUID *)requestID;

/**
 removes the supplied userID from the ativeUser's friend list
 **/
- (void)unfriedUserWithID:(int)userID withRequestID:(NSUUID *)requestID;



#pragma mark  - Tags
- (void)getTagsForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius andMaxCount:(int)maxCount andRequestID:(FluxRequestID *)requestID;


//tags filtered
- (void)getTagsForLocationFiltered:(CLLocationCoordinate2D)location
                         andRadius:(float)radius
                         andMinAlt:(float)altMin
                         andMaxAlt:(float)altMax
                   andMinTimestamp:(NSDate *)timeMin
                   andMaxTimestamp:(NSDate *)timeMax
                       andHashTags:(NSString *)hashTags
                          andUsers:(NSString *)users
                       andMaxCount:(int)maxCount
                      andRequestID:(FluxRequestID *)requestID;


#pragma mark  - Other
/**
 Deletes 100m radius around a given location
 **/
- (void)deleteLocations;



@end
