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
NSString* const FluxDataManagerDidDeleteImage = @"FluxDataManagerDidDeleteImage";
NSString* const FluxDataManagerDidDownloadImage = @"FluxDataManagerDidDownloadImage";
NSString* const FluxDataManagerDidUploadImage = @"FluxDataManagerDidUploadImage";
NSString* const FluxDataManagerDidUploadAllImages = @"FluxDataManagerDidUploadAllImages";
NSString* const FluxDataManagerDidCompleteRequest = @"FluxDataManagerDidCompleteRequest";

NSString* const FluxDataManagerKeyDeleteImageImageID = @"FluxDataManagerKeyDeleteImageImageID";
NSString* const FluxDataManagerKeyNewImageLocalID = @"FluxDataManagerKeyNewImageLocalID";
NSString* const FluxDataManagerKeyUploadImageFluxScanImageObject = @"FluxDataManagerKeyUploadImageFluxScanImageObject";

float const minAltitudeRange = 6.0;
//float const altitudeLowRange = 60.0;
//float const altitudeHighRange = 60.0;
float const altitudeMin = -100000;
float const altitudeMax =  100000;

@implementation FluxDataManager
#pragma mark - Class methods

static FluxDataManager *_theFluxDataManager = nil;

+ (NSString*)thisDeviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+ (FluxDataManager *)theFluxDataManager
{
    return _theFluxDataManager;
}

- (id)init
{
    if (self = [super init])
    {
        _isLoggedIn = false;
        _haveAPNSToken = false;
        fluxDataStore = [[FluxDataStore alloc] init];
        currentRequests = [[NSMutableDictionary alloc] init];
        downloadQueueReceivers = [[NSMutableDictionary alloc] init];
        uploadQueueReceivers = [[NSMutableDictionary alloc] init];
        
        [self setupNetworkServices];
    }
    _theFluxDataManager = self;
    return self;
}

- (float) altitudeLowRangeWithVerticalAccuracy:(double)va
{
    return MAX(minAltitudeRange, va);
}

- (float) altitudeHighRangeWithVerticalAccuracy:(double)va
{
    return MAX(minAltitudeRange, va);
}

float const altitudeHighRange = 60.0;
- (FluxRequestID *) uploadImageryData:(FluxScanImageObject *)metadata withImage:(UIImage *)image
                   withDataRequest:(FluxDataRequest *)dataRequest
                   withHistoricalImage:(UIImage *)historicalImg
{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;

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
    [networkServices uploadImage:metadata andImage:image andRequestID:requestID andHistoricalImage:historicalImg];
    
    // Set up global upload progress count (add new image to overall total)
    
    // Notify any observers of new content
    NSDictionary *userInfoDict = @{FluxDataManagerKeyNewImageLocalID : metadata.localID};
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDataManagerDidAcquireNewImage
                                                        object:self userInfo:userInfoDict];
    
    return requestID;
}

- (FluxRequestID *) retryFailedUploadWithFileURL:(NSString*)fileURL andDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = retry_image_uploads_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices retryFailedUploadFromFile:fileURL andRequestID:requestID];
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
                                            andMinAlt:location.altitude - [self altitudeLowRangeWithVerticalAccuracy:location.verticalAccuracy]
                                            andMaxAlt:location.altitude + [self altitudeHighRangeWithVerticalAccuracy:location.verticalAccuracy]
                                       andMaxReturned:dataRequest.maxReturnItems
                                            andFilter:dataRequest.searchFilter
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
                                   andMaxReturned:dataRequest.maxReturnItems andFilter:dataRequest.searchFilter
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

- (FluxScanImageObject *) getMetadataObjectFromCacheWithImageID:(FluxImageID)imageID
{
    return [fluxDataStore getMetadataWithImageID:imageID];
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
        if ([imageExist[dataRequest.imageType] boolValue])
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
            FluxCacheImageObject *cacheImageObj = [fluxDataStore getImageWithLocalID:curLocalID withSize:dataRequest.imageType];
            [dataRequest whenImageReady:curLocalID withImage:cacheImageObj withDataRequest:dataRequest];
        }
        // Now check if request has already been made
        else
        {
            dataRequest.imageType = imageType;      // reset image type to specific rather than relative
            sizeString = (NSString *)fluxImageTypeStrings[imageType];

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
            if (curImageObj.imageID > 0)
            {
                [networkServices getImageFeaturesForID:curImageObj.imageID andRequestID:requestID];
            }
        }
    }
    
    if (completedRequest)
    {
        [self completeRequestWithDataRequest:dataRequest];
    }
    
    return requestID;
}

- (FluxRequestID *) requestImageMatchesByLocalID:(FluxDataRequest *)dataRequest
{
    // TODO: rejig this to process the image match request - shouldn't need the extra queue checking on imagetype, etc.
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = image_matches_request;
    
    [currentRequests setObject:dataRequest forKey:requestID];
    
    FluxLocalID *curLocalID = dataRequest.requestedIDs[0];
    
    // Begin download of image
    FluxScanImageObject *curImageObj = [fluxDataStore getMetadataWithLocalID:curLocalID];
    if (curImageObj.imageID > 0)
    {
        [networkServices getImageMatchesForID:curImageObj.imageID andRequestID:requestID];
//        [networkServices getImageMatchesForID:1152 andRequestID:requestID]; // should return 4 elements
    }
    
    return requestID;
}

#pragma mark - Filters

- (FluxRequestID *) requestTagListAtLocation:(CLLocation *)location
                                  withRadius:(float)radius
                                 andMaxCount:(int)maxCount
                        andAltitudeSensitive:(BOOL)altitudeSensitive
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
                                          andMinAlt:(altitudeSensitive ? (location.altitude - [self altitudeLowRangeWithVerticalAccuracy:location.verticalAccuracy]) : altitudeMin)
                                          andMaxAlt:(altitudeSensitive ? (location.altitude + [self altitudeHighRangeWithVerticalAccuracy:location.verticalAccuracy]) : altitudeMax)
                                     andMaxReturned:maxCount andFilter:dataRequest.searchFilter
                                       andRequestID:requestID];
    }
    
    return requestID;
}

- (FluxRequestID *) requestImageCountstAtLocation:(CLLocation *)location
                                       withRadius:(float)radius
                             andAltitudeSensitive:(BOOL)altitudeSensitive
                                  withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = imageCounts_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getImageCountsForLocationFiltered:location.coordinate
                                             andRadius:radius
                                             andMinAlt:(altitudeSensitive ? (location.altitude - [self altitudeLowRangeWithVerticalAccuracy:location.verticalAccuracy]) : altitudeMin)
                                             andMaxAlt:(altitudeSensitive ? (location.altitude + [self altitudeHighRangeWithVerticalAccuracy:location.verticalAccuracy]) : altitudeMax)
                                             andFilter:[[FluxDataFilter alloc]init]
                                          andRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) requestTotalImageCountAtLocation:(CLLocation *)location
                                          withRadius:(float)radius
                                andAltitudeSensitive:(BOOL)altitudeSensitive
                                     withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = totalImageCount_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getFilteredImageCountForLocation:location.coordinate
                                             andRadius:radius
                                             andMinAlt:(altitudeSensitive ? (location.altitude - [self altitudeLowRangeWithVerticalAccuracy:location.verticalAccuracy]) : altitudeMin)
                                             andMaxAlt:(altitudeSensitive ? (location.altitude + [self altitudeHighRangeWithVerticalAccuracy:location.verticalAccuracy]) : altitudeMax)
                                             andFilter:dataRequest.searchFilter
                                          andRequestID:requestID];
    return requestID;
}

#pragma mark - Users

#pragma mark Registration
- (FluxRequestID*)uploadNewUser:(FluxRegistrationUserObject *)userObject withImage:(UIImage *)image withDataRequest:(FluxDataRequest *)dataRequest{
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

- (FluxRequestID*)loginUser:(FluxRegistrationUserObject *)userObject withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices loginUser:userObject withRequestID:requestID];
    return requestID;
}

- (FluxRequestID*)logoutWithDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin logout from server
    [networkServices logoutWithRequestID:requestID];
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

- (FluxRequestID*)sendPasswordResetTo:(NSString*)email withRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = send_password_reset_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices sendPasswordResetTo:email andRequestID:requestID];
    return requestID;
}

#pragma mark Profile Stuff

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

- (FluxRequestID *)editPrivacyOfImageWithImageID:(NSArray*)imageIDs to:(BOOL)newPrivacy withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = imagePrivacyUpdate_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices updateImagePrivacyForImages:imageIDs andPrvacy:newPrivacy andRequestID:requestID];
    return requestID;
}

- (FluxRequestID *)editCaptionOfImageWithImageID:(int)imageID withCaption:(NSString*)newCaption withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = updateImageCaption_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices updateImageCaptionForImageWithID:imageID withNewCaption:newCaption andRequestID:requestID];
    return requestID;
}

#pragma mark Social Stuff

- (FluxRequestID *) requestFollowingRequestsForUserWithDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = followRequest_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getFollowerRequestsForUserWithRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) requestFollowingListForID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = followingList_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getFollowingListForUserWithID:userID withRequestID:requestID];
    return requestID;
}
- (FluxRequestID *) requestFollowerListForID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = followerList_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getFollowerListForUserWithID:userID withRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) updateAPNsDeviceTokenWithRequest:(FluxDataRequest *)dataRequest
{
    FluxRequestID *requestID = dataRequest.requestID;
    if (self.haveAPNSToken)
    {
        dataRequest.requestType = data_upload_request;
        [currentRequests setObject:dataRequest forKey:requestID];
        // Begin update of device ID to server
        [networkServices updateAPNsDeviceTokenWithRequestID:requestID];
    }
    return requestID;
}

- (FluxRequestID *) requestUsersListQuery:(NSString*)query withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = userSearch_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices getUsersListForQuery:query withRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) unfollowUserWIthID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = unfollow_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices unfollowUserID:userID withRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) forceUnfollowUserWIthID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = unfollow_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices forceUnfollowUserID:userID withRequestID:requestID];
    return requestID;
}

- (FluxRequestID *) sendFollowerRequestToUserWithID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = sendFollow_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices sendFollowRequestToUserWithID:userID withRequestID:requestID];
    return requestID;
}
- (FluxRequestID *) acceptFollowerRequestFromUserWithID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = acceptFollow_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices acceptFollowingRequestFromUserWithID:userID withRequestID:requestID];
    return requestID;
}
- (FluxRequestID *) ignoreFollowerRequestFromUserWithID:(int)userID withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = ignoreFollow_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of image to server
    [networkServices ignoreFollowingRequestFromUserWithID:userID withRequestID:requestID];
    return requestID;
}

-(FluxRequestID *) requestContactsFromService:(int)serviceID withCredentials:(NSDictionary *)credentials withDataRequest:(FluxDataRequest *)dataRequest
{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = contactFromService_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin request of contacts from server
    [networkServices requestContactsFromService:serviceID withCredentials: credentials withRequestID:requestID];
    return requestID;
}

// CONTENT_FLAG: based on postCamera
- (FluxRequestID*)postContentFlagToImage:(FluxImageID)image_id withDataRequest:(FluxDataRequest *)dataRequest{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = data_upload_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // post flag to server
    [networkServices postContentFlagToImage:image_id withRequestID:requestID];
    return requestID;
}


#pragma mark Aliases

- (FluxRequestID *) createAliasWithName:(NSString *)name andServiceID:(int) service_id andRequest:(FluxDataRequest *)dataRequest
{
    FluxRequestID *requestID = dataRequest.requestID;
    dataRequest.requestType = createalias_request;
    [currentRequests setObject:dataRequest forKey:requestID];
    // Begin upload of alias to server
    [networkServices createAliasWithName:name andServiceID:service_id andRequestID:requestID];
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
    if (request) {
        [request whenErrorOccurred:e withDescription:string withDataRequest:request];
        
        // Clean up request
        [self completeRequestWithDataRequest:request];
    }
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailImageDownloadWithError:(NSError *)e andNaturalString:(NSString *)string andRequestID:(NSUUID *)requestID andImageID:(FluxImageID)imageID
{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    
    // Clean up other requests tied to this request (in the case of image download)
    FluxScanImageObject *imageObj = [fluxDataStore getMetadataWithImageID:imageID];
    NSMutableArray *completedRequestIDs = [[NSMutableArray alloc] init];
    
    // make a shallow copy of [downloadQueueReceivers objectForKey:imageObj.localID] to iterate through,
    // or go through the pain of setting up locking
    NSMutableArray *enumray = [NSMutableArray arrayWithArray:[downloadQueueReceivers objectForKey:imageObj.localID]];
    
    for (id curRequestID in enumray)
//    for (id curRequestID in [downloadQueueReceivers objectForKey:imageObj.localID])
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
        
        //ZZZZ
        // make a shallow copy of [downloadQueueReceivers objectForKey:imageObj.localID] to iterate through,
        // or go through the pain of setting up locking
        NSMutableArray *enumray = [NSMutableArray arrayWithArray:[downloadQueueReceivers objectForKey:imageObj.localID]];
        
        for (id curRequestID in enumray)
//        for (id curRequestID in [downloadQueueReceivers objectForKey:imageObj.localID])
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
        
        if ([(NSArray *)[downloadQueueReceivers objectForKey:imageObj.localID] count] == 0)
        {
            [downloadQueueReceivers removeObjectForKey:imageObj.localID];
        }
    }
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
         didreturnImageFeatures:(NSData *)features
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
        
        // make a shallow copy of [downloadQueueReceivers objectForKey:imageObj.localID] to iterate through,
        // or go through the pain of setting up locking
        NSMutableArray *enumray = [NSMutableArray arrayWithArray:[downloadQueueReceivers objectForKey:imageObj.localID]];
        
        for (id curRequestID in enumray)
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
        
        if ([(NSArray *)[downloadQueueReceivers objectForKey:imageObj.localID] count] == 0)
        {
            [downloadQueueReceivers removeObjectForKey:imageObj.localID];
        }
    }
}



- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
  didreturnImageMatches:(NSArray *)matches
             forImageID:(int)imageID
           andRequestID:(FluxRequestID *)requestID
{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    FluxScanImageObject *imageObj = [fluxDataStore getMetadataWithImageID:imageID];
    
    // Notify and execute callback
    [request whenImageMatchesReady:imageObj.localID withMatches:matches withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];

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
        NSLog(@"%s: Upload request array has %lu receivers awaiting response.", __func__, (unsigned long)[requestArray count]);
    }

    // Overwrite the data that is currently in the cache
    if (updatedImageObject) {
        [fluxDataStore addMetadataObject:updatedImageObject];
    }
    
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
    
    if (updatedImageObject) {
        [uploadQueueReceivers removeObjectForKey:updatedImageObject.localID];
        
        // Notify any observers
        NSDictionary *userInfoDict = @{FluxDataManagerKeyUploadImageFluxScanImageObject : updatedImageObject};
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDataManagerDidUploadImage object:self userInfo:userInfoDict];
    }
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices retryUploadProgress:(long long)bytesSent ofExpectedPacketSize:(long long)size andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request setBytesUploaded:bytesSent];
    [request setTotalByteSize:size];
    [request whenRetryUploadInProgress:[fluxDataStore getMetadataWithLocalID:request.uploadLocalID] withDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReUploadImage:(FluxScanImageObject *)updatedImageObject andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenRetryUploadComplete:updatedImageObject withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didDeleteImageWithID:(int)imageID andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenDeleteImageComplete:imageID withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
    
    // Notify any observers
    NSDictionary *userInfoDict = @{FluxDataManagerKeyDeleteImageImageID : @(imageID)};
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDataManagerDidDeleteImage object:self userInfo:userInfoDict];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUpdateImagePrivacysWithRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUpdateImagesPrivacyCompleteWithDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUpdateImageCaptionWithRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUpdateImageCaptionCompleteWithDataRequest:request];
    
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

#pragma mark Filters

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnTagList:(NSArray *)tagList andRequestID:(NSUUID *)requestID
{
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenTagsReady:tagList withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnImageCounts:(FluxFilterImageCountObject *)countObject andRequestID:(NSUUID *)requestID
{
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenImageCountsReady:countObject withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnTotalImageCount:(int)count andRequestID:(NSUUID *)requestID
{
    // Call callback of requestor
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenTotalImageCountReady:count withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

#pragma mark Users

#pragma mark Registration
-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didCreateUser:(FluxRegistrationUserObject *)userObject andRequestID:(NSUUID *)requestID{
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

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didLoginUser:(FluxRegistrationUserObject *)userObject andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenLoginUserComplete:userObject withDataRequest:request];
    // flag that a user is logged in to be used for device registration
    _isLoggedIn = true;
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didLogoutWithRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenLogoutComplete:request];
    // unflag that a user is logged in to be used for device registration
    _isLoggedIn = false;
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
    
    // flag that a user is logged in to be used for device registration
    _isLoggedIn = true;
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];

    // register/update the APNS device token
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [self updateAPNsDeviceTokenWithRequest:dataRequest];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didSendPasswordResetEmailWithRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenResetPasswordCompleteWithDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

#pragma mark Profile Stuff

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

#pragma mark Social

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnFollowingRequestsForUser:(NSArray *)friendRequests andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUserFollowingRequestsReady:friendRequests withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}


- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnFollowingListForUser:(NSArray *)followings andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUserFollowingsReady:followings withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnFollowerListForUser:(NSArray *)followers andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUserFollowersReady:followers withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnUsersListForQuery:(NSArray *)users andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUserSearchReady:users withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUnfollowUserWithID:(int)userID andRequestID:(FluxRequestID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenUnfollowingUserReady:userID withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didForceUnfollowUserWithID:(int)userID andRequestID:(FluxRequestID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenForceUnfollowingUserReady:userID withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didSendFollowingRequestToUserWithID:(int)userID andRequestID:(FluxRequestID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenSendFollowingRequestReady:userID withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didAcceptFollowingRequestFromUserWithID:(int)userID andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenAcceptFollowerRequestReady:userID withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didIgnoreFollowingRequestFromUserWithID:(int)userID andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenIgnoreFollowerRequestReady:userID withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnContactList:(NSArray *)contacts andRequestID:(NSUUID *)requestID{
    FluxDataRequest *request = [currentRequests objectForKey:requestID];
    [request whenContactListReady:contacts withDataRequest:request];
    
    // Clean up request (nothing else to wait for)
    [self completeRequestWithDataRequest:request];
}


#pragma mark Other

-(NSArray*)failedUploads{
    //creates a file path to save the data packet
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*folderDirectory = [NSString stringWithFormat:@"%@%@",[paths objectAtIndex:0],@"/imageUploadCache"];
    
    //ensures the correct folder exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderDirectory]) {
        // Directory does not exist
        return nil;
    }
    else{
        NSError * error;
        NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderDirectory error:&error];
        if (!error) {
            if (directoryContents) {
                if (directoryContents.count > 0) {
                    return directoryContents;
                }
            }
        }
        return nil;
    }
}

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

- (void)removeUnusedItemsFromImageCache
{
    [fluxDataStore removeUnusedItemsFromImageCache];
}

@end
