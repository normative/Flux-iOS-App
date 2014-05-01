//
//  FluxDataManager.h
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxDataFilter.h"
#import "FluxDataRequest.h"
#import "FluxDataStore.h"
#import "FluxNetworkServices.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"
#import "FluxCameraObject.h"

extern NSString* const FluxDataManagerDidAcquireNewImage;
extern NSString* const FluxDataManagerDidDeleteImage;
extern NSString* const FluxDataManagerDidDownloadImage;
extern NSString* const FluxDataManagerDidUploadImage;
extern NSString* const FluxDataManagerDidUploadAllImages;
extern NSString* const FluxDataManagerDidCompleteRequest;

extern NSString* const FluxDataManagerKeyDeleteImageImageID;
extern NSString* const FluxDataManagerKeyNewImageLocalID;
extern NSString* const FluxDataManagerKeyUploadImageFluxScanImageObject;

@interface FluxDataManager : NSObject <NetworkServicesDelegate>
{
    FluxDataStore *fluxDataStore;
    FluxNetworkServices *networkServices;
    
    // Dictionary of current (outstanding) FluxDataRequest objects, keyed by FluxRequestID
    NSMutableDictionary *currentRequests;
    
    // For each FluxLocalID key, stores a NSMutableArray of FluxRequestID's waiting on download to complete
    NSMutableDictionary *downloadQueueReceivers;

    // For each FluxLocalID key, stores a NSMutableArray of FluxRequestID's waiting on upload to complete
    NSMutableDictionary *uploadQueueReceivers;
}

@property (nonatomic) bool isLoggedIn;
@property (nonatomic) bool haveAPNSToken;

+ (NSString*)thisDeviceName;
//+ (FluxCameraModelEnum)thisCameraModel;
+ (FluxDataManager *)theFluxDataManager;

- (FluxRequestID *) uploadImageryData:(FluxScanImageObject *)metadata withImage:(UIImage *)image
                      withDataRequest:(FluxDataRequest *)dataRequest
                  withHistoricalImage:(UIImage *)historicalImg;

- (FluxRequestID *) retryFailedUploadWithFileURL:(NSString*)fileURL andDataRequest:(FluxDataRequest *)dataRequest;

//used for image capture
- (void) addCameraDataToStore:(FluxScanImageObject *)metadata withImage:(UIImage *)image;

// non-blocking calls for local cache metadata operations
- (FluxScanImageObject *) getMetadataObjectFromCacheWithLocalID:(FluxLocalID *)localID;
- (FluxScanImageObject *) getMetadataObjectFromCacheWithImageID:(FluxImageID)imageID;

// Reset all cached feature matching quantities
- (void)resetAllFeatureMatches;

// Returns the Request ID if request is successful, otherwise nil
- (FluxRequestID *) requestTimeValuesAtLocation:(CLLocationCoordinate2D)coordinate
                                    withRadius:(float)radius
                                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestImageListAtLocation:(CLLocation *)location
                                    withRadius:(float)radius
                                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestMetadataByImageID:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestMetadataByLocalID:(FluxDataRequest *)dataRequest;
- (void) requestImageByImageID:(int)imageID withSize:(FluxImageType)imageType
                                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestImagesByLocalID:(FluxDataRequest *)dataRequest withSize:(FluxImageType)imageType;
- (void) completeRequestWithDataRequest:(FluxDataRequest *)dataRequest;

//Filters
- (FluxRequestID *) requestTagListAtLocation:(CLLocation *)location
                                  withRadius:(float)radius
                                 andMaxCount:(int)maxCount
                        andAltitudeSensitive:(BOOL)altitudeSensitive
                             withDataRequest:(FluxDataRequest *)dataRequest;

- (FluxRequestID *) requestImageCountstAtLocation:(CLLocation *)location
                                  withRadius:(float)radius
                        andAltitudeSensitive:(BOOL)altitudeSensitive
                             withDataRequest:(FluxDataRequest *)dataRequest;

- (FluxRequestID *) requestTotalImageCountAtLocation:(CLLocation *)location
                                  withRadius:(float)radius
                        andAltitudeSensitive:(BOOL)altitudeSensitive
                             withDataRequest:(FluxDataRequest *)dataRequest;

//Map images
- (FluxRequestID *) requestMapImageListAtLocation:(CLLocationCoordinate2D)location
                                    withRadius:(float)radius
                               withDataRequest:(FluxDataRequest *)dataRequest;

//Other Images
- (NSArray *) checkForImagesByLocalID:(FluxLocalID *)localID;

- (FluxCacheImageObject *)fetchImagesByLocalID:(FluxLocalID *)curLocalID withSize:(FluxImageType)imageType returnSize:(FluxImageType *)returnType;
- (FluxCacheImageObject *)fetchImageByImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType returnSize:(FluxImageType *)returnType;

- (FluxRequestID *)deleteImageWithImageID:(int)imageID withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *)editPrivacyOfImageWithImageID:(NSArray*)imageIDs to:(BOOL)newPrivacy withDataRequest:(FluxDataRequest *)dataRequest;

- (FluxRequestID *) requestImageFeaturesByLocalID:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestImageMatchesByLocalID:(FluxDataRequest *)dataRequest;


//USERS

//registration / LOGOUT
- (FluxRequestID *) uploadNewUser:(FluxRegistrationUserObject *)userObject withImage:(UIImage *)image
                   withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) updateUser:(FluxUserObject *)userObject withImage:(UIImage *)image
                  withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) loginUser:(FluxRegistrationUserObject *)userObject
                  withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) checkUsernameUniqueness:(NSString *)username
              withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) postCamera:(FluxCameraObject *)cameraObject
              withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) updateAPNsDeviceTokenWithRequest:(FluxDataRequest *)dataRequest;

- (FluxRequestID*)logoutWithDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID*)sendPasswordResetTo:(NSString*)email withRequest:(FluxDataRequest *)dataRequest;

//profiles
- (FluxRequestID *) requestUserProfileForID:(int)userID
                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestUserProfilePicForID:(int)userID andSize:(NSString*)size
                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestImageListForUserWithID:(int)userID
                    withDataRequest:(FluxDataRequest *)dataRequest;

//social
- (FluxRequestID *) requestFollowingRequestsForUserWithDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestFollowingListForID:(int)userID
                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestFollowerListForID:(int)userID
                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestUsersListQuery:(NSString*)query
                             withDataRequest:(FluxDataRequest *)dataRequest;


- (FluxRequestID *) unfollowUserWIthID:(int)userID
                             withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *)forceUnfollowUserWIthID:(int)userID
                       withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) sendFollowerRequestToUserWithID:(int)userID
                             withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) acceptFollowerRequestFromUserWithID:(int)userID
                             withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) ignoreFollowerRequestFromUserWithID:(int)userID
                             withDataRequest:(FluxDataRequest *)dataRequest;
-(FluxRequestID *) requestContactsFromService:(int)serviceID
                              withCredentials:(NSDictionary *)credentials
                              withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID*) postContentFlagToImage:(FluxImageID)image_id
                          withDataRequest:(FluxDataRequest *)dataRequest;

//aliases
- (FluxRequestID *) createAliasWithName:(NSString *)name
                           andServiceID:(int) service_id
                             andRequest:(FluxDataRequest *)dataRequest;

- (NSArray*)failedUploads;



- (void)deleteLocations;
- (void)debugByShowingCachedImageKeys;
- (void)cleanupNonLocalContentWithLocalIDArray:(NSArray *)localItems;
- (void)removeUnusedItemsFromImageCache;

@end
