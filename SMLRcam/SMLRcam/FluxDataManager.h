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

extern NSString* const FluxDataManagerDidAcquireNewImage;
extern NSString* const FluxDataManagerDidDownloadImage;
extern NSString* const FluxDataManagerDidUploadImage;
extern NSString* const FluxDataManagerDidUploadAllImages;
extern NSString* const FluxDataManagerDidCompleteRequest;

extern NSString* const FluxDataManagerKeyNewImageLocalID;

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

- (FluxRequestID *) addDataToStore:(FluxScanImageObject *)metadata withImage:(UIImage *)image
                withDataRequest:(FluxDataRequest *)dataRequest;

//used for image capture
- (void) addCameraDataToStore:(FluxScanImageObject *)metadata withImage:(UIImage *)image;

// Returns the Request ID if request is successful, otherwise nil
- (FluxRequestID *) requestTimeValuesAtLocation:(CLLocationCoordinate2D)coordinate
                                    withRadius:(float)radius
                                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestImageListAtLocation:(CLLocationCoordinate2D)coordinate
                                    withRadius:(float)radius
                                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestMetadataByImageID:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestMetadataByLocalID:(FluxDataRequest *)dataRequest;
- (void) requestImageByImageID:(int)imageID withSize:(FluxImageType)imageType
                                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestImagesByLocalID:(FluxDataRequest *)dataRequest withSize:(FluxImageType)imageType;
- (void) completeRequestWithDataRequest:(FluxDataRequest *)dataRequest;

- (FluxRequestID *) requestTagListAtLocation:(CLLocationCoordinate2D)coordinate
                                  withRadius:(float)radius
                                 andMaxCount:(int)maxCount
                             withDataRequest:(FluxDataRequest *)dataRequest;

- (FluxRequestID *) requestMapImageListAtLocation:(CLLocationCoordinate2D)coordinate
                                    withRadius:(float)radius
                               withDataRequest:(FluxDataRequest *)dataRequest;

- (NSArray *) checkForImagesByLocalID:(FluxLocalID *)localID;

- (UIImage *)fetchImagesByLocalID:(FluxLocalID *)curLocalID withSize:(FluxImageType)imageType returnSize:(FluxImageType *)returnType;

- (FluxRequestID *) uploadNewUser:(FluxUserObject *)userObject withImage:(UIImage *)image
                   withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) loginUser:(FluxUserObject *)userObject
                  withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestUserProfileForID:(int)userID
                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestUserProfilePicForID:(int)userID andSize:(NSString*)size
                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestImageListForUserWithID:(int)userID
                    withDataRequest:(FluxDataRequest *)dataRequest;

- (void)deleteLocations;

@end
