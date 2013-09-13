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

typedef NSUUID FluxRequestID;

@interface FluxDataManager : NSObject <NetworkServicesDelegate>
{
    FluxDataStore *fluxDataStore;
    FluxNetworkServices *networkServices;
    
    // Dictionary of current (outstanding) FluxDataRequest objects, keyed by FluxRequestID
    NSMutableDictionary *currentRequests;
    
    // For each FluxLocalID key, stores a NSMutableArray of FluxRequestID's waiting on download to complete
    NSMutableDictionary *downloadQueueReceivers;
}

- (void) addDataToStore:(FluxScanImageObject *)metadata withImage:(UIImage *)image;

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
- (FluxRequestID *) requestImagesByImageID:(FluxDataRequest *)dataRequest withSize:(image_type)imageType;
- (FluxRequestID *) requestImagesByLocalID:(FluxDataRequest *)dataRequest withSize:(image_type)imageType;

@end
