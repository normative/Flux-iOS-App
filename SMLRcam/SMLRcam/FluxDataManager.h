//
//  FluxDataManager.h
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 Normative. All rights reserved.
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

// Returns the Request ID if request is successful, otherwise nil
- (FluxRequestID *) requestTimeValuesAtLocation:(CLLocationCoordinate2D)coordinate
                                    withRadius:(float)radius withFilter:(FluxDataFilter *)filter
                                    withDataRequest:(FluxDataRequest *)dataRequest;
//                                        success:(void (^)(NSMutableArray *timeValues, NSMutableArray *timeCount))success;
- (FluxRequestID *) requestImageListAtLocation:(CLLocationCoordinate2D)coordinate
                                    withRadius:(float)radius withFilter:(FluxDataFilter *)filter
                                    withDataRequest:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestMetadataByImageID:(FluxDataRequest *)dataRequest;
- (FluxRequestID *) requestMetadataByLocalID:(FluxDataRequest *)dataRequest;
- (void) requestImageByImageID:(int)imageID withSize:(image_type)imageType;
- (FluxRequestID *) requestImagesByLocalID:(FluxDataRequest *)dataRequest withSize:(image_type)imageType;
- (void) completeRequestWithDataRequest:(FluxDataRequest *)dataRequest;

- (FluxRequestID *) requestTagListAtLocation:(CLLocationCoordinate2D)coordinate
                                    withRadius:(float)radius withFilter:(FluxDataFilter *)filter
                                 andMaxCount:(int)maxCount
                               withDataRequest:(FluxDataRequest *)dataRequest;

@end
