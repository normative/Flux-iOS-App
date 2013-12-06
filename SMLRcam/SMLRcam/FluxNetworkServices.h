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
#import <CoreLocation/CoreLocation.h>
#import "RKObjectManager.h"

typedef NSUUID FluxRequestID;

extern NSString* const FluxProductionServerURL;

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
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailWithError:(NSError*)e
           andRequestID:(FluxRequestID *)requestID;

//maps
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnMapList:(NSArray*)imageList
           andRequestID:(FluxRequestID *)requestID;

//users
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didCreateUser:(FluxUserObject*)userObject
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didLoginUserWithtoken:(NSString*)authToken
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnUser:(FluxUserObject *)user
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnProfileImage:(UIImage *)image forUserID:(int)user
           andRequestID:(FluxRequestID *)requestID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnImageListForUser:(NSArray*)images
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

#pragma mark - image methods

//returns the raw image given an imageID
- (void)getImageForID:(int)imageID withStringSize:(NSString *)sizeString andRequestID:(FluxRequestID *)requestID;

//returns an image object given an imageID
- (void)getImageMetadataForID:(int)imageID andRequestID:(FluxRequestID *)requestID;

//returns an NSDictionary list of images at a given location within a given radius
- (void)getImagesForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius andRequestID:(FluxRequestID *)requestID;

//returns an NSDictionary list of images filtered based on provided details
- (void)getImagesForLocationFiltered:(CLLocationCoordinate2D)location
                           andRadius:(float)radius
                           andMinAlt:(float)altMin
                           andMaxAlt:(float)altMax
                     andMinTimestamp:(NSDate *)timeMin
                     andMaxTimestamp:(NSDate *)timeMax
                         andHashTags:(NSString *)hashTags
                            andUsers:(NSString *)users
                       andCategories:(NSString *)cats
                         andMaxCount:(int)maxCount
                        andRequestID:(FluxRequestID *)requestID;

//returns an NSDictionary list of images for mapView filtered based on provided details
- (void)getMapImagesForLocationFiltered:(CLLocationCoordinate2D)location
                           andRadius:(float)radius
                           andMinAlt:(float)altMin
                           andMaxAlt:(float)altMax
                     andMinTimestamp:(NSDate *)timeMin
                     andMaxTimestamp:(NSDate *)timeMax
                         andHashTags:(NSString *)hashTags
                            andUsers:(NSString *)users
                       andCategories:(NSString *)cats
                         andMaxCount:(int)maxCount
                        andRequestID:(FluxRequestID *)requestID;

// execute the request
- (void)doRequest:(NSURLRequest *)request withResponseDesc:(RKResponseDescriptor *)responseDescriptor andRequestID:(FluxRequestID *)requestID;

//uploads an image. All account info is stored within the FluxScanImageObject
- (void)uploadImage:(FluxScanImageObject*)theImageObject andImage:(UIImage *)theImage andRequestID:(FluxRequestID *)requestID;

#pragma mark  - Users

//returns user for a given userID
- (void)getUserForID:(int)userID withRequestID:(FluxRequestID *)requestID;

- (void)loginUser:(FluxUserObject*)userObject withRequestID:(FluxRequestID *)requestID;

//creates a user with the given object
- (void)createUser:(FluxUserObject*)userObject withImage:(UIImage*)theImage andRequestID:(FluxRequestID *)requestID;

//return's a profile image for a given userID and size
- (void)getUserProfilePicForID:(int)userID withStringSize:(NSString *)sizeString withRequestID:(NSUUID *)requestID;

//return's a user's image list for a given userID
- (void)getImagesListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID;

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
                     andCategories:(NSString *)cats
                       andMaxCount:(int)maxCount
                      andRequestID:(FluxRequestID *)requestID;


#pragma mark  - Other
- (void)deleteLocations;



@end
