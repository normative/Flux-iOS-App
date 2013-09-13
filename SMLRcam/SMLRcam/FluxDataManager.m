//
//  FluxDataManager.m
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDataManager.h"

NSString* const FluxDataManagerDidAcquireNewImage = @"FluxDataManagerDidAcquireNewImage";
NSString* const FluxDataManagerDidDownloadImage = @"FluxDataManagerDidDownloadImage";
NSString* const FluxDataManagerDidUploadImage = @"FluxDataManagerDidUploadImage";
NSString* const FluxDataManagerDidUploadAllImages = @"FluxDataManagerDidUploadAllImages";
NSString* const FluxDataManagerDidCompleteRequest = @"FluxDataManagerDidCompleteRequest";

NSString* const FluxDataManagerKeyNewImageLocalID = @"FluxDataManagerKeyNewImageLocalID";

@implementation FluxDataManager

- (id)init
{
    if (self = [super init])
    {
        fluxDataStore = [[FluxDataStore alloc] init];
        currentRequests = [[NSMutableDictionary alloc] init];
        downloadQueueReceivers = [[NSMutableDictionary alloc] init];
        uploadQueueReceivers = [[NSMutableDictionary alloc] init];
        
        [self setupNetworkServices];
    }
    return self;
}

- (FluxRequestID *) addDataToStore:(FluxScanImageObject *)metadata withImage:(UIImage *)image
                   withDataRequest:(FluxDataRequest *)dataRequest
{
    FluxRequestID *requestID =[[FluxRequestID alloc] init];
    
    // Add a new image with metadata to both cache objects
    [fluxDataStore addMetadataObject:metadata];
    [fluxDataStore addImageToStore:image withLocalID:metadata.localID withSize:full_res];
    
    [currentRequests setObject:dataRequest forKey:requestID];
    if ([uploadQueueReceivers objectForKey:metadata.localID] == nil)
    {
        [uploadQueueReceivers setObject:[[NSMutableArray alloc] initWithObjects:requestID, nil] forKey:metadata.localID];
    }
    else
    {
        [[uploadQueueReceivers objectForKey:metadata.localID] addObject:requestID];
    }
    
    // Begin upload of image to server
    [networkServices uploadImage:metadata andImage:image andRequestID:requestID];
    
    // Set up global upload progress count (add new image to overall total)

    // Notify any observers of new content
    NSDictionary *userInfoDict = [[NSDictionary alloc]
                                  initWithObjectsAndKeys:metadata.localID, FluxDataManagerKeyNewImageLocalID, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDataManagerDidAcquireNewImage
                                                        object:self userInfo:userInfoDict];
    
    return requestID;
}

#pragma mark - Item List Queries

- (FluxRequestID *) requestTimeValuesAtLocation:(CLLocationCoordinate2D)coordinate
                                     withRadius:(float)radius withFilter:(FluxDataFilter *)filter
                                withDataRequest:(FluxDataRequest *)dataRequest
{
    return nil;
}

- (FluxRequestID *) requestImageListAtLocation:(CLLocationCoordinate2D)coordinate
                                    withRadius:(float)radius withFilter:(FluxDataFilter *)filter
                               withDataRequest:(FluxDataRequest *)dataRequest
{
    FluxRequestID *requestID =[[FluxRequestID alloc] init];
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    [networkServices getImagesForLocation:coordinate andRadius:radius andRequestID:requestID];
    
    return requestID;
}

#pragma mark - Metadata Queries

- (FluxRequestID *) requestMetadataByImageID:(FluxDataRequest *)dataRequest
{
    return nil;
}

- (FluxRequestID *) requestMetadataByLocalID:(FluxDataRequest *)dataRequest
{
    return nil;
}

#pragma mark - Image Queries

- (FluxRequestID *) requestImagesByImageID:(FluxDataRequest *)dataRequest withSize:(image_type)imageType
{
    return nil;
}

- (FluxRequestID *) requestImagesByLocalID:(FluxDataRequest *)dataRequest withSize:(image_type)imageType
{
    FluxRequestID *requestID =[[FluxRequestID alloc] init];

    [currentRequests setObject:dataRequest forKey:requestID];
    
    NSString *sizeString = @"orientd";
    if (imageType == thumb)
    {
        sizeString = @"thumb";
    }

    for (id curLocalID in dataRequest.requestedIDs)
    {
        if ([downloadQueueReceivers objectForKey:curLocalID] == nil)
        {
            [downloadQueueReceivers setObject:[[NSMutableArray alloc] initWithObjects:requestID, nil] forKey:curLocalID];
        }
        else
        {
            [[downloadQueueReceivers objectForKey:curLocalID] addObject:requestID];
        }
        
        // Begin download of image
        FluxScanImageObject *curImageObj = [fluxDataStore getMetadataWithLocalID:curLocalID];
        [networkServices getImageForID:curImageObj.imageID withStringSize:sizeString andRequestID:requestID];
    }
    
    return requestID;
}

#pragma mark - Request Queries

// General support for managing outstanding requests (i.e. see which images in bulk request are complete)

#pragma mark - Network Services

- (void)setupNetworkServices{
    networkServices = [[FluxNetworkServices alloc]init];
    [networkServices setDelegate:self];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageList:(NSMutableDictionary *)imageList
           andRequestID:(FluxRequestID *)requestID
{
    // Need to update all metadata objects even if they exist (in case they change in the future)
    // Note that this dictionary will be up to date, but metadata will need to be re-copied from this dictionary
    // when a desired image is loaded (happens after the texture is loaded)
    for (id curKey in [imageList allKeys])
    {
        FluxScanImageObject *curImgObj = [imageList objectForKey:curKey];
        [fluxDataStore addMetadataObject:curImgObj];
    }
    
    // Call callback of requestor
    
    // Clean up request (nothing else to wait for)
    [currentRequests removeObjectForKey:requestID];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
         didreturnImage:(UIImage *)image
             forImageID:(int)imageID
           andRequestID:(FluxRequestID *)requestID
{
    // This is the request matching the call to download. Note that others may also be waiting.
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    
    // Make sure that imageID matches requested ID
    FluxScanImageObject *imageObj = [fluxDataStore getMetadataWithImageID:imageID];
    
    if (![request.requestedIDs containsObject:imageObj.localID])
    {
        // This ID was not requested
        NSLog(@"%s: Request ID returned not expecting imageID %d", __func__, imageID);
    }
    else
    {
        // We are currently assuming the size in the request is the size returned. Should check this.
        
        
        // Add image to Data Store
        [fluxDataStore addImageToStore:image withLocalID:imageObj.localID withSize:request.imageType];
        
        // Notify and clean up.
        // Note that a single image download may not necessarily complete a request.
        // Also note that multiple requests may be open for each image received.
        // Clean up:
        // - each request in currentRequests dictionary (update received items, check if complete)
        // - requests are identified by downloadQueueReceivers list for current localID
        
        NSMutableArray *completedRequestIDs = [[NSMutableArray alloc] init];
        
        for (id curRequestID in [downloadQueueReceivers objectForKey:imageObj.localID])
        {
            FluxDataRequest *curRequest = [currentRequests objectForKey:curRequestID];
            if (([curRequest.requestedIDs containsObject:imageObj.localID]) &&
                (![curRequest.completedIDs containsObject:imageObj.localID]))
            {
                // Notify and execute callback
                
                // Clean up
                [curRequest.completedIDs addObject:imageObj.localID];
                
                if ([curRequest.completedIDs count] == [curRequest.requestedIDs count])
                {
                    // Request is complete
                    [completedRequestIDs addObject:curRequestID];
                }
            }
        }
        for (id curRequestID in completedRequestIDs)
        {
            [currentRequests removeObjectForKey:curRequestID];
            [[downloadQueueReceivers objectForKey:imageObj.localID] removeObject:curRequestID];
        }
    }
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices uploadProgress:(float)bytesSent ofExpectedPacketSize:(float)size{
    //subtract a bit for the end wait
//    progressView.progress = bytesSent/size -0.05;
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUploadImage:(FluxScanImageObject *)updatedImageObject
           andRequestID:(FluxRequestID *)requestID
{
    // Find the requests objects for this item
    NSMutableArray *requestArray = [uploadQueueReceivers objectForKey:updatedImageObject.localID];
    
    if (![requestArray containsObject:requestID])
    {
        NSLog(@"%s: Request ID mismatch for upload of localID %@", __func__, updatedImageObject.localID);
    }
    
    if ([requestArray count] != 1)
    {
        NSLog(@"%s: Upload request array has %d receivers awaiting response.", __func__, [requestArray count]);
    }

    // Overwrite the data that is currently in the cache
    [fluxDataStore addMetadataObject:updatedImageObject];
    
    // If callbacks exist, call them for each receiver
    
    // Clear entries from currentRequests and uploadQueueReceivers
    // This is looping, but should only ever delete one item
    for (id curRequestID in requestArray)
    {
        [currentRequests removeObjectForKey:curRequestID];
    }
    [uploadQueueReceivers removeObjectForKey:updatedImageObject.localID];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices imageUploadDidFailWithError:(NSError *)e{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Image upload failed with error %d", (int)[e code]]
                                                        message:[e localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    
    
    [UIView animateWithDuration:0.2f
                     animations:^{
//                         [progressView setAlpha:0.0];
                     }
                     completion:^(BOOL finished){
//                         progressView.progress = 0;
                     }];
}

@end
