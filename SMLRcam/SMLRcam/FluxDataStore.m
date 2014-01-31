//
//  FluxDataStore.m
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDataStore.h"

NSString* const FluxDataStoreDidEvictImageObjectFromCache = @"FluxDataStoreDidEvictImageObjectFromCache";
NSString* const FluxDataStoreDidEvictImageObjectFromCacheKeyImageType = @"FluxDataStoreDidEvictImageObjectFromCacheKeyImageType";
NSString* const FluxDataStoreDidEvictImageObjectFromCacheKeyLocalID = @"FluxDataStoreDidEvictImageObjectFromCacheKeyLocalID";

@implementation FluxDataStore

- (id)init
{
    if (self = [super init])
    {
        fluxImageCache = [[NSCache alloc] init];
        [fluxImageCache setDelegate:self];
        [fluxImageCache setEvictsObjectsWithDiscardedContent:NO];
        
        fluxMetadata = [[NSMutableDictionary alloc] init];
        imageIDMapping = [[NSMutableDictionary alloc] init];
        
        cachedImageLocalIDList = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (FluxCacheImageObject *) addImageToStore:(UIImage *)image withImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType
{
    if ((image != nil) && (imageID >= 0))
    {
        // Note this currently only supports the case where an image has been uploaded to the server.
        // An upload causes the imageID to be set to a non-negative value. Prior to this time,
        // an image is only referenced by localID.
        FluxLocalID *localID = [imageIDMapping objectForKey:[NSString stringWithFormat:@"%d", imageID]];
        return [self addImageToStore:image withLocalID:localID withSize:imageType];
    }
    return nil;
}

- (FluxCacheImageObject *) addImageToStore:(UIImage *)image withLocalID:(FluxLocalID *)localID withSize:(FluxImageType)imageType
{
    if ((image != nil) && (localID != nil))
    {
        FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
        if (imageObject != nil)
        {
            NSString *imageCacheKey =[imageObject generateImageCacheKeyWithImageType:imageType];
            FluxCacheImageObject *imageCacheObject = [FluxCacheImageObject cacheImageObject:image withID:localID withType:imageType];
            [fluxImageCache setObject:imageCacheObject
                               forKey:imageCacheKey];
            [cachedImageLocalIDList setObject:imageCacheObject forKey:imageCacheKey];
            return imageCacheObject;
        }
        else
        {
            NSLog(@"%s: Attempting to add image without metadata object for localID %@", __func__, localID);
        }
    }
    return nil;
}

- (void) addMetadataObject:(FluxScanImageObject *)metadata
{
    if ((metadata.localID == nil) || (metadata.localID.length == 0))
    {
        if (metadata.imageID >= 0)
        {
            metadata.localID = [metadata generateUniqueStringID];
        }
        else
        {
            NSLog(@"%s: Shouldn't get here. imageID has invalid value and localID not set.", __func__);
        }
    }
    // Don't overwrite if it exists
    FluxScanImageObject *imageObject = [fluxMetadata objectForKey:metadata.localID];
    if (!imageObject)
    {
//        NSLog(@"Metadata for localID %@, imageID %d not found in cache - adding, justCaptured: %d", metadata.localID, metadata.imageID, metadata.justCaptured);
        [fluxMetadata setObject:metadata forKey:metadata.localID];
    }
    else if (imageObject.imageID < 0 && metadata.imageID >= 0)
    {
        // Server has returned a previously local-only metadata object (assigning an imageID). Update.
//        NSLog(@"Changing imageID for localID %@ from %d to %d, justCaptured: %d", metadata.localID, imageObject.imageID, metadata.imageID, imageObject.justCaptured);
        imageObject.imageID = metadata.imageID;
    }
    
    if ((metadata.imageID >= 0) && ([imageIDMapping objectForKey:[NSString stringWithFormat:@"%d",metadata.imageID]] == nil))
    {
        [self setImageIDMapping:metadata.imageID forLocalID:metadata.localID];
    }
}

- (void) addImageFeaturesToStore:(NSString *)features withLocalID:localID
{
    
}

- (NSArray *) doesImageExistForImageID:(FluxImageID)imageID
{
    NSArray *imageFormats = @[@(NO), @(NO), @(NO), @(NO), @(NO), @(NO)];
    
    if (imageID >= 0)
    {
        // Note this currently only supports the case where an image has been uploaded to the server.
        // An upload causes the imageID to be set to a non-negative value. Prior to this time,
        // an image is only referenced by localID.
        FluxLocalID *localID = [imageIDMapping objectForKey:[NSString stringWithFormat:@"%d", imageID]];
        imageFormats = [self doesImageExistForLocalID:localID];
    }

    return imageFormats;
}

- (NSArray *) doesImageExistForLocalID:(FluxLocalID *)localID
{
    NSMutableArray *imageFormats = [NSMutableArray arrayWithObjects:@(NO), @(NO), @(NO), @(NO), @(NO), @(NO), nil];
    
    if (localID != nil)
    {
        FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
        
        // No point searching for them for existence then searching for them again - might as well store the pointers.
        FluxCacheImageObject *imageCacheObj = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:thumb]];
        imageFormats[thumb] = @(imageCacheObj.image != nil);
        imageCacheObj = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:quarterhd]];
        imageFormats[quarterhd] = @(imageCacheObj.image != nil);
        imageCacheObj = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:screen_res]];
        imageFormats[screen_res] = @(imageCacheObj.image != nil);
        imageCacheObj = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:full_res]];
        imageFormats[full_res] = @(imageCacheObj.image != nil);
        imageFormats[screen_res] = imageFormats[full_res];
        
        bool foundLowest = false;
        for (int i = (lowest_res + 1); (i < highest_res); i++)
        {
            if ([imageFormats[i] boolValue])
            {
                if (!foundLowest)
                {
                    foundLowest = true;
                    imageFormats[lowest_res] = imageFormats[i];
                }
                
                imageFormats[highest_res] = imageFormats[i];
            }
        }
    }
    
    return [NSArray arrayWithArray:imageFormats];;
}

- (FluxCacheImageObject *) getImageWithImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType
{
    if (imageID >= 0)
    {
        // Note this currently only supports the case where an image has been uploaded to the server.
        // An upload causes the imageID to be set to a non-negative value. Prior to this time,
        // an image is only referenced by localID.
        FluxLocalID *localID = [imageIDMapping objectForKey:[NSString stringWithFormat:@"%d", imageID]];
        return [self getImageWithLocalID:localID withSize:imageType];
    }
    else
    {
        return nil;
    }
}

- (FluxCacheImageObject *) getImageWithLocalID:(FluxLocalID *)localID withSize:(FluxImageType)imageType
{
    // If key doesn't exist, this will return nil.
    // This means it is either no longer in cache, or didn't exist in the first place
    FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
    FluxCacheImageObject *imageCacheObj = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:imageType]];
    
    if ([imageCacheObj beginContentAccess])
    {
        return imageCacheObj;
    }
    else
    {
        return nil;
    }
}

- (FluxScanImageObject *) getMetadataWithImageID:(FluxImageID)imageID
{
    if (imageID >= 0)
    {
        // Note this currently only supports the case where an image has been uploaded to the server.
        // An upload causes the imageID to be set to a non-negative value. Prior to this time,
        // an image is only referenced by localID.
        FluxLocalID *localID = [imageIDMapping objectForKey:[NSString stringWithFormat:@"%d", imageID]];
        return [self getMetadataWithLocalID:localID];
    }
    return nil;
}

- (FluxScanImageObject *) getMetadataWithLocalID:(FluxLocalID *)localID
{
    // If key doesn't exist, this will return nil
    return [fluxMetadata objectForKey:localID];
}

// This needs to be called when a new object has been downloaded from the server and is being
// added to the cache (both localID and imageID are known)
// and also when an object upload has been completed to the server (where imageID was initially unknown).
- (void) setImageIDMapping:(FluxImageID)imageID forLocalID:(FluxLocalID *)localID
{
    FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
    if (imageObject != nil)
    {
//        if (imageObject.imageID >= 0)
//        {
//            NSLog(@"%s: imageID for localID %@ has previously been set (cid:%d, nid:%d).", __func__, localID, imageObject.imageID, imageID);
//        }
        [imageIDMapping setValue:localID forKey:[NSString stringWithFormat:@"%d",imageID]];
    }
}

- (void)resetAllFeatureMatches
{
    // Rests all matched quantities
    for (FluxScanImageObject *imageObject in [fluxMetadata allValues])
    {
        imageObject.matched = NO;
        imageObject.matchFailed = NO;
        imageObject.matchFailureRetryTime = nil;
        imageObject.numFeatureMatchAttempts = 0;
        imageObject.numFeatureMatchCancels = 0;
        imageObject.numFeatureMatchFailHomographyErrors = 0;
        imageObject.numFeatureMatchFailMatchErrors = 0;
        imageObject.cumulativeFeatureMatchTime = 0.0;
        
        // Just set the location_data_type to default. Other quantities will be ignored if this is not set.
        imageObject.location_data_type = location_data_default;
    }
}

#pragma mark - NSCache delegate and debugging code

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    // Called when an object is about to be evicted or removed from the cache.
    // It is not possible to modify cache from within the implementation of this delegate method.
    
    FluxLocalID *localID = ((FluxCacheImageObject *)obj).localID;
    FluxImageType imageType = ((FluxCacheImageObject *)obj).imageType;
    FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];

    NSString *imageCacheKey = [imageObject generateImageCacheKeyWithImageType:imageType];
    [cachedImageLocalIDList removeObjectForKey:imageCacheKey];
    
    NSDictionary *userInfoDict = @{FluxDataStoreDidEvictImageObjectFromCacheKeyImageType : @(imageType),
                                   FluxDataStoreDidEvictImageObjectFromCacheKeyLocalID : localID};
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDataStoreDidEvictImageObjectFromCache
                                                        object:self userInfo:userInfoDict];
}

- (void)debugByShowingCachedImageKeys
{
    NSMutableDictionary *cachedIDs = [[NSMutableDictionary alloc] init];
    
    for (FluxLocalID *localID in [fluxMetadata allKeys])
    {
        NSMutableArray *foundImageTypes = [[NSMutableArray alloc] init];
        FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
        for (NSUInteger imageType = thumb; imageType <= full_res; imageType++)
        {
            FluxCacheImageObject *cacheImageObj = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:imageType]];
            if (cacheImageObj && ![cacheImageObj isContentDiscarded])
            {
                [foundImageTypes addObject:[NSNumber numberWithUnsignedInteger:imageType]];
            }
        }

        if ([foundImageTypes count] > 0)
        {
            cachedIDs[localID] = foundImageTypes;
        }
    }
}

- (void)cleanupNonLocalContentWithLocalIDArray:(NSArray *)localItems
{
    // Cleans up the image NSCache for now. Could also clean up metadata structure
    
    // Major problem is that the NSCache is a black box that you can't see inside without changing.
    // Can only verify if something is in the cache by accessing it, and if you access something,
    // you are telling Apple it is something to keep in the cache (possibly LRU-type scheme).
    // Had created a separate data struction (NSMutableDictionary) to keep tabs on what is in the cache
    // but this is quite redundant.
    // Now going to use the existing mechanism we use as part of the FluxImageRenderElement to keep
    // track of what images of type imageType we have in the cache.
    // Note that this will only be updated when we request something (which "should" happen once something
    // is downloaded) and not when we add the image to the cache.
    // Also, when something is booted out of the cache, we will update this structure as well.
    // We can iterate over these items so that we don't actually have to poke the cache to check.
    for (FluxLocalID *localID in [fluxMetadata allKeys])
    {
        if (![localItems containsObject:localID])
        {
            FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
            for (NSUInteger imageType = thumb; imageType <= full_res; imageType++)
            {
                NSString *imageCacheKey = [imageObject generateImageCacheKeyWithImageType:imageType];
                if (cachedImageLocalIDList[imageCacheKey])
                {
                    FluxCacheImageObject *cacheImageObj = cachedImageLocalIDList[imageCacheKey];
                    [cacheImageObj endContentAccess];
                }
            }
        }
    }
}

@end
