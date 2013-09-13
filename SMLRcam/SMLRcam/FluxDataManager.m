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

@implementation FluxDataManager

- (id)init
{
    if (self = [super init])
    {
        fluxDataStore = [[FluxDataStore alloc] init];
        currentRequests = [[NSMutableDictionary alloc] init];
        
        [self setupNetworkServices];
    }
    return self;
}

- (void) addDataToStore:(FluxScanImageObject *)metadata withImage:(UIImage *)image
{
    // Add a new image with metadata to both cache objects

    // Begin upload of image to server
    
    // Set up global upload progress count (add new image to overall total)

    // Notify any observers of new content
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDataManagerDidAcquireNewImage object:self];
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
    return nil;
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
    return nil;
}

#pragma mark - Request Queries

// General support for managing outstanding requests (i.e. see which images in bulk request are complete)

#pragma mark - Network Services

- (void)setupNetworkServices{
    networkServices = [[FluxNetworkServices alloc]init];
    [networkServices setDelegate:self];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
         didreturnImage:(UIImage *)image
             forImageID:(int)imageID
{
//    for (NSString *currentKey in [fluxMetadata allKeys])
//    {
//        FluxScanImageObject* currentImageObject = [fluxMetadata objectForKey:currentKey];
//        if (currentImageObject.imageID == imageID)
//        {
//            [fluxImageCache setObject:image forKey:currentImageObject.localThumbID];
//            break;
//        }
//    }
//    [radarView updateRadarWithNewMetaData:fluxMetadata];
//    [annotationsTableView reloadData];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices uploadProgress:(float)bytesSent ofExpectedPacketSize:(float)size{
    //subtract a bit for the end wait
//    progressView.progress = bytesSent/size -0.05;
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUploadImage:(FluxScanImageObject *)updatedImageObject
{
//    progressView.progress = 1;
    
//    NSLog(@"%s: Adding image object %@ to cache.", __func__, updatedImageObject.localID);
//    
//    if ([fluxMetadata objectForKey:updatedImageObject.localID] != nil)
//    {
//        // FluxScanImageObject exists in the local cache. Replace it with updated object.
//        [fluxMetadata setObject:updatedImageObject forKey:updatedImageObject.localID];
//        
//        if ([fluxImageCache objectForKey:updatedImageObject.localID] != nil)
//        {
//            NSLog(@"Image with string ID %@ exists in cache.", updatedImageObject.localID);
//        }
//        else
//        {
//            NSLog(@"Image with string ID %@ does not exist in cache.", updatedImageObject.localID);
//        }
//    }
//    else
//    {
//        NSLog(@"Image with string ID %@ does not exist in local cache!", updatedImageObject.localID);
//    }
    
//    [progressView setProgress:1.0];
//    [self performSelector:@selector(hideProgressView) withObject:nil afterDelay:0.5];
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
