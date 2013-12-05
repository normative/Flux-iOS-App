//
//  FluxDataRequest.h
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxDataFilter.h"
#import "FluxDataStore.h"
#import "FluxNetworkServices.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"
#import "FluxTagObject.h"

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
} FluxDataRequestType;

@class FluxDataRequest;

typedef void (^ImageReadyBlock)(FluxLocalID *, UIImage *, FluxDataRequest *);
typedef void (^MetadataReadyBlock)(FluxScanImageObject *, FluxDataRequest *);
typedef void (^NearbyListReadyBlock)(NSArray *);
typedef void (^WideAreaListReadyBlock)(NSArray *);
typedef void (^RequestCompleteBlock)(FluxDataRequest *);
typedef void (^UploadInProgressBlock)(FluxScanImageObject *, FluxDataRequest *);
typedef void (^UploadCompleteBlock)(FluxScanImageObject *, FluxDataRequest *);
typedef void (^UploadUserCompleteBlock)(FluxUserObject *, FluxDataRequest *);
typedef void (^LoginUserCompleteBlock)(NSString*, FluxDataRequest *);
typedef void (^UserReadyBlock)(FluxUserObject*, FluxDataRequest *);
typedef void (^UserProfilePicReadyBlock)(UIImage*,int, FluxDataRequest *);
typedef void (^TagsReadyBlock)(NSArray *, FluxDataRequest *);
typedef void (^ErrorBlock)(NSError *, FluxDataRequest *);

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
@property (nonatomic, strong) NSArray *requestedIDs;
@property (nonatomic, strong) NSMutableArray *completedIDs;

// Upload properties
@property (nonatomic, weak) FluxLocalID *uploadLocalID;
@property (nonatomic) long long totalByteSize;
@property (nonatomic) long long bytesUploaded;

// Callback for single image retrieved (either from cache or download)
@property (strong) ImageReadyBlock imageReady;

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

// Callback for successful upload of user + image metadata
@property (strong) UploadUserCompleteBlock uploadUserComplete;

// Callback for successful user login
@property (strong) LoginUserCompleteBlock loginUserComplete;

// Callback for successful user profile returned
@property (strong) UserReadyBlock userReady;

// Callback for successful user profile pic returned
@property (strong) UserProfilePicReadyBlock userPicReady;

// Callback for list of tags retrieved
@property (strong) TagsReadyBlock tagsReady;

// Callback for error occurred
@property (strong) ErrorBlock errorOccurred;

- (void) whenImageReady:(FluxLocalID *)localID withImage:(UIImage *)image withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenMetadataReady:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenNearbyListReady:(NSArray *)nearbyList;
- (void) whenWideAreaListReady:(NSArray *)wideList;
- (void) whenRequestComplete:(FluxDataRequest *)completeDataRequest;
- (void) whenUploadComplete:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUploadInProgress:(FluxScanImageObject *)imageObject withDataRequest:(FluxDataRequest *)inprogressDataRequest;
- (void) whenUploadUserComplete:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenLoginUserComplete:(NSString *)token withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUserReady:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenUserProfilePicReady:(UIImage *)profilePic forUserID:(int)userID withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenTagsReady:(NSArray *)tagObjects withDataRequest:(FluxDataRequest *)completeDataRequest;
- (void) whenErrorOccurred:(NSError *)e withDataRequest:(FluxDataRequest *)errorDataRequest;

@end
