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
    FluxRequestID *requestID = dataRequest.requestID;
    
    // Add a new image with metadata to both cache objects
    [fluxDataStore addMetadataObject:metadata];
    [fluxDataStore addImageToStore:image withLocalID:metadata.localID withSize:full_res];
    
    // Check if upload is enabled
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool pushToCloud = [[defaults objectForKey:@"Network Services"]boolValue];

    if (pushToCloud)
    {
        [dataRequest setUploadLocalID:metadata.localID];

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
    }
    
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
    FluxRequestID *requestID = dataRequest.requestID;
    
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

// Need to add a callback block to arguments
- (void) requestImageByImageID:(int)imageID withSize:(image_type)imageType
{
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setRequestType:image_request];
    [dataRequest setImageType:imageType];
    FluxScanImageObject *imageObj = [fluxDataStore getMetadataWithImageID:imageID];
    if (imageObj != nil)
    {
        NSArray *tempArray = [NSArray arrayWithObject:imageObj.localID];
        [dataRequest setRequestedIDs:tempArray];
        [dataRequest setImageReady:^(FluxLocalID *localID, UIImage *image, FluxDataRequest *completeDataRequest)
         {
             NSLog(@"!!!!!!Yay! We downloaded image %@ with request %@", localID, completeDataRequest.requestID);
         }];
        [self requestImagesByLocalID:dataRequest withSize:imageType];
    }
    else
    {
        NSLog(@"%s: Requested ImageID %d does not exist!", __func__, imageID);
    }
}

- (FluxRequestID *) requestImagesByLocalID:(FluxDataRequest *)dataRequest withSize:(image_type)imageType
{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.imageType = imageType;
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    NSString *sizeString = @"oriented";
    if (imageType == thumb)
    {
        sizeString = @"thumb";
    }

    BOOL completedRequest = NO;

    for (id curLocalID in dataRequest.requestedIDs)
    {
        // First check if image is already in cache
        NSArray *imageExist = [fluxDataStore doesImageExistForLocalID:curLocalID];
        if ([imageExist[imageType] isEqualToNumber:[NSNumber numberWithBool:YES]])
        {
            // If so, we can take immediate action
            if (![[dataRequest completedIDs] containsObject:curLocalID])
            {
                [[dataRequest completedIDs] addObject:curLocalID];
                if ([dataRequest.completedIDs count] == [dataRequest.requestedIDs count])
                {
                    // We have completed the request
                    completedRequest = YES;
                }
            }
            UIImage *image = [fluxDataStore getImageWithLocalID:curLocalID withSize:imageType];
            [dataRequest whenImageReady:curLocalID withImage:image withDataRequest:dataRequest];
        }
        // Now check if request has already been made
        else
        {
            NSMutableArray *downloadRequestsForID = [downloadQueueReceivers objectForKey:curLocalID];
            BOOL validDownloadInProgress = NO;
            
            if (downloadRequestsForID != nil)
            {
                for (id curRequestID in downloadRequestsForID)
                {
                    FluxDataRequest *curRequest = [currentRequests objectForKey:curRequestID];
                    if (curRequest.imageType == imageType)
                    {
                        validDownloadInProgress = YES;
                        break;
                    }
                }
            }

            if (validDownloadInProgress)
            {
                [[downloadQueueReceivers objectForKey:curLocalID] addObject:requestID];
            }
            else
            {
                [downloadQueueReceivers setObject:[[NSMutableArray alloc] initWithObjects:requestID, nil] forKey:curLocalID];
                
                // Begin download of image
                FluxScanImageObject *curImageObj = [fluxDataStore getMetadataWithLocalID:curLocalID];
                [networkServices getImageForID:curImageObj.imageID withStringSize:sizeString andRequestID:requestID];
            }
        }
    }
    
    if (completedRequest)
    {
        [self completeRequestWithDataRequest:dataRequest];
    }
    
    return requestID;
}

#pragma mark - Tag Requests

- (FluxRequestID *) requestTagListAtLocation:(CLLocationCoordinate2D)coordinate
                                  withRadius:(float)radius withFilter:(FluxDataFilter *)filter
                             andMaxCount:(int)maxCount withDataRequest:(FluxDataRequest *)dataRequest{
    
    FluxRequestID *requestID = dataRequest.requestID;
    
    [dataRequest setRequestType:tag_request];
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    [networkServices getTagsForLocation:coordinate andRadius:radius andMaxCount:maxCount andRequestID:requestID];
    
    return requestID;
}

#pragma mark - Request Queries

// General support for managing outstanding requests (i.e. see which images in bulk request are complete)

- (void) completeRequestWithDataRequest:(FluxDataRequest *)dataRequest
{
    FluxRequestID *requestID = dataRequest.requestID;
    [dataRequest whenRequestComplete:dataRequest];
    [currentRequests removeObjectForKey:requestID];
}

#pragma mark - Network Services

- (void)setupNetworkServices{
    networkServices = [[FluxNetworkServices alloc]init];
    [networkServices setDelegate:self];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageList:(NSMutableDictionary *)imageList
           andRequestID:(FluxRequestID *)requestID
{
    // Need to update all metadata objects even if they exist (in case they change in the future)
#warning This may break things in the future when we add difference between full metadata request
// This will occur when list of metadata only returns critical pieces of metadata object.
// May be easiest to add an update routine that only overwrites these properties.
    // Note that this dictionary will be up to date, but metadata will need to be re-copied from this dictionary
    // when a desired image is loaded (happens after the texture is loaded)
    for (id curKey in [imageList allKeys])
    {
        FluxScanImageObject *curImgObj = [imageList objectForKey:curKey];
        [fluxDataStore addMetadataObject:curImgObj];
    }
    
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenNearbyListReady:imageList];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
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
                (![curRequest.completedIDs containsObject:imageObj.localID]) &&
                (curRequest.imageType == request.imageType))
            {
                // Mark as complete prior to callback
                [curRequest.completedIDs addObject:imageObj.localID];

                // Notify and execute callback
                [curRequest whenImageReady:imageObj.localID withImage:image withDataRequest:request];
                
                // Used to clean up in next step
                if ([curRequest.completedIDs count] == [curRequest.requestedIDs count])
                {
                    // Request is complete
                    [completedRequestIDs addObject:curRequestID];
                }
            }
        }
        
        for (id curRequestID in completedRequestIDs)
        {
            FluxDataRequest *curRequest = [currentRequests objectForKey:curRequestID];
            [self completeRequestWithDataRequest:curRequest];
            [[downloadQueueReceivers objectForKey:imageObj.localID] removeObject:curRequestID];
        }
        
        if ([[downloadQueueReceivers objectForKey:imageObj.localID] count] == 0)
        {
            [downloadQueueReceivers removeObjectForKey:imageObj.localID];
        }
    }
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices uploadProgress:(long long)bytesSent
                    ofExpectedPacketSize:(long long)size andRequestID:(FluxRequestID *)requestID
{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request setCurrentUploadSize:bytesSent];
    [request setTotalUploadSize:size];
    [request whenUploadInProgress:[fluxDataStore getMetadataWithLocalID:request.uploadLocalID] withDataRequest:request];
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
    for (id curRequestID in requestArray)
    {
        FluxDataRequest *curRequest = [currentRequests objectForKey:curRequestID];
        
        // Notify and execute callback
        [curRequest whenUploadComplete:updatedImageObject withDataRequest:curRequest];
    }
    
    // Clear entries from currentRequests and uploadQueueReceivers
    // This is looping, but should only ever delete one item
    for (id curRequestID in requestArray)
    {
        FluxDataRequest *curRequest = [currentRequests objectForKey:curRequestID];
        [self completeRequestWithDataRequest:curRequest];
        [[uploadQueueReceivers objectForKey:updatedImageObject.localID] removeObject:curRequestID];
    }
    
    if ([[uploadQueueReceivers objectForKey:updatedImageObject.localID] count] == 0)
    {
        [uploadQueueReceivers removeObjectForKey:updatedImageObject.localID];
    }
    else
    {
        NSLog(@"%s: Upload Queue Receiver list not empty following upload of ID %@. Should never happen.",
              __func__, updatedImageObject.localID);
    }

}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnTagList:(NSArray *)tagList andRequestID:(NSUUID *)requestID{

    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenTagsReady:tagList withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
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
