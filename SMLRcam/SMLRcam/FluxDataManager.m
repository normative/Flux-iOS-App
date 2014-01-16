//
//  FluxDataManager.m
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDataManager.h"
#import <sys/utsname.h>

NSString* const FluxDataManagerDidAcquireNewImage = @"FluxDataManagerDidAcquireNewImage";
NSString* const FluxDataManagerDidDownloadImage = @"FluxDataManagerDidDownloadImage";
NSString* const FluxDataManagerDidUploadImage = @"FluxDataManagerDidUploadImage";
NSString* const FluxDataManagerDidUploadAllImages = @"FluxDataManagerDidUploadAllImages";
NSString* const FluxDataManagerDidCompleteRequest = @"FluxDataManagerDidCompleteRequest";

NSString* const FluxDataManagerKeyNewImageLocalID = @"FluxDataManagerKeyNewImageLocalID";

float const altitudeLowRange = 3.0;
float const altitudeHighRange = 3.0;
float const altitudeMin = -100000;
float const altitudeMax =  100000;

@implementation FluxDataManager

#pragma mark - Class methods

+ (NSString*)thisDeviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+ (FluxCameraModel)thisCameraModel
{
    return [FluxScanImageObject cameraModelFromModelStr:[FluxDataManager thisDeviceName]];
}

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
    dataRequest.requestType = data_upload_request;
    
    // Add a new image with metadata to both cache objects
    [fluxDataStore addMetadataObject:metadata];
    [fluxDataStore addImageToStore:image withLocalID:metadata.localID withSize:full_res];
    
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
    
    // Notify any observers of new content
    NSDictionary *userInfoDict = @{FluxDataManagerKeyNewImageLocalID : metadata.localID};
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDataManagerDidAcquireNewImage
                                                        object:self userInfo:userInfoDict];
    
    return requestID;
}

- (void) addCameraDataToStore:(FluxScanImageObject *)metadata withImage:(UIImage *)image{
    [fluxDataStore addMetadataObject:metadata];
    [fluxDataStore addImageToStore:image withLocalID:metadata.localID withSize:full_res];
}



#pragma mark - Item List Queries

- (FluxRequestID *) requestTimeValuesAtLocation:(CLLocationCoordinate2D)coordinate
                                     withRadius:(float)radius
                                withDataRequest:(FluxDataRequest *)dataRequest
{
    return nil;
}

- (FluxRequestID *) requestImageListAtLocation:(CLLocation*)location
                                    withRadius:(float)radius
                               withDataRequest:(FluxDataRequest *)dataRequest
{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = nearby_list_request;
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    // Simple case with no filtering
    if (dataRequest.searchFilter == nil)
    {
        [networkServices getImagesForLocation:location.coordinate andRadius:radius andRequestID:requestID];
    }
    else
    {
        [networkServices getImagesForLocationFiltered:location.coordinate
                                            andRadius:radius
//                                            andMinAlt:dataRequest.searchFilter.altMin
//                                            andMaxAlt:dataRequest.searchFilter.altMax
                                            andMinAlt:location.altitude - altitudeLowRange
                                            andMaxAlt:location.altitude + altitudeHighRange
                                      andMinTimestamp:dataRequest.searchFilter.timeMin
                                      andMaxTimestamp:dataRequest.searchFilter.timeMax
                                          andHashTags:dataRequest.searchFilter.hashTags
                                             andUsers:dataRequest.searchFilter.users
                                        andCategories:dataRequest.searchFilter.categories
                                          andMaxCount:dataRequest.maxReturnItems
                                         andRequestID:requestID];
    }
    
    return requestID;
}

#pragma mark MapView List

- (FluxRequestID *) requestMapImageListAtLocation:(CLLocationCoordinate2D)coordinate
                                       withRadius:(float)radius
                                  withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = wide_Area_list_request;
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    // Simple case with no filtering
    [networkServices getMapImagesForLocationFiltered:coordinate
                                        andRadius:radius
                                        andMinAlt:dataRequest.searchFilter.altMin
                                        andMaxAlt:dataRequest.searchFilter.altMax
                                  andMinTimestamp:dataRequest.searchFilter.timeMin
                                  andMaxTimestamp:dataRequest.searchFilter.timeMax
                                      andHashTags:dataRequest.searchFilter.hashTags
                                         andUsers:dataRequest.searchFilter.users
                                    andCategories:dataRequest.searchFilter.categories
                                      andMaxCount:dataRequest.maxReturnItems
                                     andRequestID:requestID];
    
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

- (FluxScanImageObject *) getMetadataObjectFromCacheWithLocalID:(NSString *)localID
{
    return [fluxDataStore getMetadataWithLocalID:localID];
}

- (void)resetAllFeatureMatches
{
    [fluxDataStore resetAllFeatureMatches];
}

#pragma mark - Image Queries

// Need to add a callback block to arguments
- (void) requestImageByImageID:(int)imageID withSize:(FluxImageType)imageType withDataRequest:(FluxDataRequest *)dataRequest
{
    dataRequest.imageType = imageType;

    FluxScanImageObject *imageObj = [fluxDataStore getMetadataWithImageID:imageID];
    if (imageObj != nil)
    {
        NSMutableArray *requestArray = [NSMutableArray arrayWithObject:imageObj.localID];
        [dataRequest setRequestedIDs:requestArray];
        [self requestImagesByLocalID:dataRequest withSize:imageType];
    }
    else
    {
        NSLog(@"%s: Requested ImageID %d does not exist!", __func__, imageID);
        
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:[NSString stringWithFormat:@"Requested ImageID %d does not exist.", imageID] forKey:NSLocalizedDescriptionKey];
        NSError *e = [NSError errorWithDomain:@"Flux" code:200 userInfo:details];
        
        [dataRequest whenErrorOccurred:e withDescription:[NSString stringWithFormat:@"Requested ImageID %d does not exist.", imageID] withDataRequest:dataRequest];
    }
}


- (NSArray *) checkForImagesByLocalID:(FluxLocalID *)localID
{
    return [fluxDataStore doesImageExistForLocalID:localID];
}

- (FluxCacheImageObject *)fetchImageByImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType returnSize:(FluxImageType *)returnType
{
    FluxScanImageObject *imageObj = [fluxDataStore getMetadataWithImageID:imageID];
    if (imageObj != nil)
    {
        return [self fetchImagesByLocalID:imageObj.localID withSize:imageType returnSize:returnType];
    }
    else
    {
        returnType = none;
        return nil;
    }
}

- (FluxCacheImageObject *)fetchImagesByLocalID:(FluxLocalID *)curLocalID withSize:(FluxImageType)imageType returnSize:(FluxImageType *)returnType
{
    FluxCacheImageObject *cacheImageObj = nil;
    FluxImageType itype;

    *returnType = none;
    
    switch (imageType) {
        case lowest_res:
            //  find lowest image res...
            itype = lowest_res + 1;
            while ((cacheImageObj.image == nil) && (itype < highest_res))
            {
                cacheImageObj = [fluxDataStore getImageWithLocalID:curLocalID withSize:itype];
                *returnType = itype++;
            }
            break;
        case highest_res:
            //  find lowest highest res...
            itype = highest_res - 1;
            while ((cacheImageObj.image == nil) && (itype > lowest_res))
            {
                cacheImageObj = [fluxDataStore getImageWithLocalID:curLocalID withSize:itype];
                *returnType = itype--;
            }
            break;
        default:
            // everything else - just return what is asked...
            cacheImageObj = [fluxDataStore getImageWithLocalID:curLocalID withSize:imageType];
            *returnType = imageType;
            break;
    }

    return cacheImageObj;
}


- (FluxRequestID *) requestImagesByLocalID:(FluxDataRequest *)dataRequest withSize:(FluxImageType)imageType
{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = image_request;
    dataRequest.imageType = imageType;
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    NSString *sizeString;
    switch (imageType) {
        case lowest_res:
            imageType = thumb;
        case thumb:
//            sizeString = @"thumb";
            break;
        case quarterhd:
//            sizeString = @"quarterhd";
            break;
        case screen_res:
        case highest_res:
            imageType = full_res;
        case full_res:
//            sizeString = @"oriented";
            break;
        default:
            imageType = thumb;
//            sizeString = @"thumb";
            break;
    }


    BOOL completedRequest = NO;

    for (id curLocalID in dataRequest.requestedIDs)
    {
        // First check if image is already in cache
        // use dataRequest.imageType for this check because it may be "lowest" or "highest"
        NSArray *imageExist = [fluxDataStore doesImageExistForLocalID:curLocalID];
        if (imageExist[dataRequest.imageType] != [NSNull null])
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
            FluxCacheImageObject *cacheImageObj = imageExist[dataRequest.imageType];
            [dataRequest whenImageReady:curLocalID withImage:cacheImageObj withDataRequest:dataRequest];
        }
        // Now check if request has already been made
        else
        {
            dataRequest.imageType = imageType;      // reset image type to specific rather than relative
            sizeString = fluxImageTypeStrings[imageType];

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
                // simply add the request to the existing record
                [[downloadQueueReceivers objectForKey:curLocalID] addObject:requestID];
            }
            else
            {
                // create a new record
                [downloadQueueReceivers setObject:[[NSMutableArray alloc] initWithObjects:requestID, nil] forKey:curLocalID];
            }
            
            if (!validDownloadInProgress)
            {
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

#pragma mark Features

- (FluxRequestID *) requestImageFeaturesByLocalID:(FluxDataRequest *)dataRequest
{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = image_request;
    FluxImageType imageType = features;
    dataRequest.imageType = imageType;
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    BOOL completedRequest = NO;
    
    for (id curLocalID in dataRequest.requestedIDs)
    {
        // Now check if request has already been made
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
            // simply add the request to the existing record
            [[downloadQueueReceivers objectForKey:curLocalID] addObject:requestID];
        }
        else
        {
            // create a new record
            [downloadQueueReceivers setObject:[[NSMutableArray alloc] initWithObjects:requestID, nil] forKey:curLocalID];
        }
        
        if (!validDownloadInProgress)
        {
            // Begin download of image
            FluxScanImageObject *curImageObj = [fluxDataStore getMetadataWithLocalID:curLocalID];
            [networkServices getImageFeaturesForID:curImageObj.imageID andRequestID:requestID];
        }
    }
    
    if (completedRequest)
    {
        [self completeRequestWithDataRequest:dataRequest];
    }
    
    return requestID;
}



#pragma mark - Tag Requests

- (FluxRequestID *) requestTagListAtLocation:(CLLocation *)location
                                  withRadius:(float)radius
                                 andMaxCount:(int)maxCount
                             withDataRequest:(FluxDataRequest *)dataRequest
{
    
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = tag_request;
    
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    if (dataRequest.searchFilter == nil)
    {
        [networkServices getTagsForLocation:location.coordinate andRadius:radius andMaxCount:maxCount andRequestID:requestID];
    }
    else
    {
        [networkServices getTagsForLocationFiltered:location.coordinate
                                            andRadius:radius
                                            andMinAlt:location.altitude - altitudeLowRange
                                            andMaxAlt:location.altitude + altitudeHighRange
                                      andMinTimestamp:dataRequest.searchFilter.timeMin
                                      andMaxTimestamp:dataRequest.searchFilter.timeMax
                                          andHashTags:dataRequest.searchFilter.hashTags
                                             andUsers:dataRequest.searchFilter.users
                                        andCategories:dataRequest.searchFilter.categories
                                          andMaxCount:maxCount
                                         andRequestID:requestID];
    }
    
    return requestID;
}

#pragma mark - Users
- (FluxRequestID*)uploadNewUser:(FluxUserObject *)userObject withImage:(UIImage *)image withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices createUser:userObject withImage:image andRequestID:requestID];
    return requestID;
}

- (FluxRequestID*)updateUser:(FluxUserObject *)userObject withImage:(UIImage *)image withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices updateUser:userObject withImage:image andRequestID:requestID];
     return requestID;
}

- (FluxRequestID*)loginUser:(FluxUserObject *)userObject withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices loginUser:userObject withRequestID:requestID];
    return requestID;
}

- (FluxRequestID*)checkUsernameUniqueness:(NSString *)username withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices checkUsernameUniqueness:username withRequestID:requestID];
    return requestID;
}

- (FluxRequestID*)postCamera:(FluxCameraObject *)cameraObject withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices postCamera:cameraObject withRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) requestUserProfileForID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = profile_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getUserForID:userID withRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) requestUserProfilePicForID:(int)userID andSize:(NSString *)size withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = profile_pic_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getUserProfilePicForID:userID withStringSize:size withRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) requestImageListForUserWithID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = profile_images_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getImagesListForUserWithID:userID withRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) deleteImageWithImageID:(int)imageID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = profile_images_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices deleteImageWithID:imageID andRequestID:requestID];
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

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailWithError:(NSError *)e andNaturalString:(NSString *)string andRequestID:(NSUUID *)requestID
{
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenErrorOccurred:e withDescription:string withDataRequest:request];
    
    // Clean up request
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailImageDownloadWithError:(NSError *)e andNaturalString:(NSString *)string andRequestID:(NSUUID *)requestID andImageID:(FluxImageID)imageID
{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    
    // Clean up other requests tied to this request (in the case of image download)
    FluxScanImageObject *imageObj = [fluxDataStore getMetadataWithImageID:imageID];
    NSMutableArray *completedRequestIDs = [[NSMutableArray alloc] init];
    
    for (id curRequestID in [downloadQueueReceivers objectForKey:imageObj.localID])
    {
        FluxDataRequest *curRequest = [currentRequests objectForKey:curRequestID];
        if (([curRequest.requestedIDs containsObject:imageObj.localID]) &&
            (![curRequest.completedIDs containsObject:imageObj.localID]) &&
            (curRequest.imageType == request.imageType))
        {
            // Call callback of each requestor
            [curRequest whenErrorOccurred:e withDescription:string withDataRequest:curRequest];

            // Delete requested ID from both lists
            [curRequest.requestedIDs removeObject:imageObj.localID];
            [curRequest.completedIDs removeObject:imageObj.localID];
            
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
    
    // In this case, delete no matter what (since we want next request to re-request ID)
    [downloadQueueReceivers removeObjectForKey:imageObj.localID];
}


#pragma mark Images

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageList:(NSArray *)imageList
           andRequestID:(FluxRequestID *)requestID
{
    // Need to update all metadata objects even if they exist (in case they change in the future)
#warning This may break things in the future when we add difference between full metadata request
// This will occur when list of metadata only returns critical pieces of metadata object.
// May be easiest to add an update routine that only overwrites these properties.
    // Note that this dictionary will be up to date, but metadata will need to be re-copied from this dictionary
    // when a desired image is loaded (happens after the texture is loaded)
    for (FluxScanImageObject *curImgObj in imageList)
    {
        [fluxDataStore addMetadataObject:curImgObj];
    }
    
    // Sort list returned, if required
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    if (request.sortDescriptor != nil)
    {
        // Currently assume a single NSSortDescriptor. Possible to add an array of them.
        imageList = [imageList sortedArrayUsingDescriptors:[NSArray arrayWithObject:request.sortDescriptor]];
    }
    
    // Call callback of requestor
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
        FluxCacheImageObject *imageCacheObj = [fluxDataStore addImageToStore:image withLocalID:imageObj.localID withSize:request.imageType];
        
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
                [curRequest whenImageReady:imageObj.localID withImage:imageCacheObj withDataRequest:request];
                
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

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
         didreturnImageFeatures:(NSString *)features
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
        imageObj.features = features;
        
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
                [curRequest whenImageFeaturesReady:imageObj.localID withFeatures:features withDataRequest:request];
                
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
    [request setBytesUploaded:bytesSent];
    [request setTotalByteSize:size];
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
    }
    
    [uploadQueueReceivers removeObjectForKey:updatedImageObject.localID];
}

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didDeleteImageWithID:(int)imageID andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenDeleteImageComplete:imageID withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

#pragma mark Map

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnMapList:(NSArray *)imageList andRequestID:(NSUUID *)requestID
{
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenWideAreaListReady:imageList];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

#pragma mark Tags

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnTagList:(NSArray *)tagList andRequestID:(NSUUID *)requestID
{
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenTagsReady:tagList withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

#pragma mark Users

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didCreateUser:(FluxUserObject *)userObject andRequestID:(NSUUID *)requestID{
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUploadUserComplete:userObject withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUpdateUser:(FluxUserObject *)userObject andRequestID:(NSUUID *)requestID{
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUpdateUserComplete:userObject withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didLoginUser:(FluxUserObject *)userObject andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenLoginUserComplete:userObject withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didCheckUsernameUniqueness:(BOOL)unique andSuggestion:(NSString *)suggestion andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUsernameCheckComplete:unique andSuggestion:suggestion withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didPostCameraWithID:(int)camID andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenCameraPostCompleteWithID:camID andDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnUser:(FluxUserObject *)user andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUserReady:user withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnProfileImage:(UIImage *)image forUserID:(int)user andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUserProfilePicReady:image forUserID:user withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnImageListForUser:(NSArray *)images andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUserImagesReady:images withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

#pragma mark Other

- (void)deleteLocations
{
    [networkServices deleteLocations];
}

- (void)debugByShowingCachedImageKeys
{
    [fluxDataStore debugByShowingCachedImageKeys];
}

- (void)cleanupNonLocalContentWithLocalIDArray:(NSArray *)localItems
{
    [fluxDataStore cleanupNonLocalContentWithLocalIDArray:localItems];
}

@end
