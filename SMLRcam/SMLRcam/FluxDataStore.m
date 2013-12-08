//
//  FluxDataStore.m
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDataStore.h"

@implementation FluxDataStore

- (id)init
{
    if (self = [super init])
    {
        fluxImageCache = [[NSCache alloc] init];
        fluxMetadata = [[NSMutableDictionary alloc] init];
        imageIDMapping = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) addImageToStore:(UIImage *)image withImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType
{
    if ((image != nil) && (imageID >= 0))
    {
        // Note this currently only supports the case where an image has been uploaded to the server.
        // An upload causes the imageID to be set to a non-negative value. Prior to this time,
        // an image is only referenced by localID.
        FluxLocalID *localID = [imageIDMapping objectForKey:[NSString stringWithFormat:@"%d", imageID]];
        [self addImageToStore:image withLocalID:localID withSize:imageType];
    }
}

- (void) addImageToStore:(UIImage *)image withLocalID:(FluxLocalID *)localID withSize:(FluxImageType)imageType
{
    if ((image != nil) && (localID != nil))
    {
        FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
        if (imageObject != nil)
        {
            [fluxImageCache setObject:image forKey:[imageObject generateImageCacheKeyWithImageType:imageType]];
        }
        else
        {
            NSLog(@"%s: Attempting to add image without metadata object for localID %@", __func__, localID);
        }
    }
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
        [fluxMetadata setValue:metadata forKey:metadata.localID];
    }
    else if (imageObject.imageID < 0 && metadata.imageID >= 0)
    {
        // Server has returned a previously local-only metadata object (assigning an imageID). Update.
        imageObject.imageID = metadata.imageID;
    }
    
    if ((metadata.imageID >= 0) && ([imageIDMapping objectForKey:[NSString stringWithFormat:@"%d",metadata.imageID]] == nil))
    {
        [self setImageIDMapping:metadata.imageID forLocalID:metadata.localID];
    }
}

- (NSArray *) doesImageExistForImageID:(FluxImageID)imageID
{
    NSArray *imageFormats = [NSMutableArray arrayWithObjects:[NSNull null], [NSNull null], [NSNull null],
                                                             [NSNull null], [NSNull null], [NSNull null],
                                                             nil];
    
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
    NSMutableArray *imageFormats = [NSMutableArray arrayWithObjects:[NSNull null], [NSNull null], [NSNull null],
                                                                    [NSNull null], [NSNull null], [NSNull null],
                                                                    nil];
    
    if (localID != nil)
    {
        FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
//        imageFormats[thumb] = [NSNumber numberWithBool:
//                               ([fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:thumb]] != nil)];
//        imageFormats[screen_res] = [NSNumber numberWithBool:
//                                    ([fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:screen_res]] != nil)];
//        imageFormats[full_res] = [NSNumber numberWithBool:
//                                  ([fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:full_res]] != nil)];
        
        // No point searching for them for existence then searching for them again - might as well store the pointers.
        id img = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:thumb]];
        imageFormats[thumb] = (img != nil) ? img : [NSNull null];
        img = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:quarterhd]];
        imageFormats[quarterhd] = (img != nil) ? img : [NSNull null];
        img = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:screen_res]];
        imageFormats[screen_res] = (img != nil) ? img : [NSNull null];
        img = [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:full_res]];
        imageFormats[full_res] = (img != nil) ? img : [NSNull null];
        imageFormats[screen_res] = imageFormats[full_res];
        
        bool foundLowest = false;
        for (int i = (lowest_res + 1); (i < highest_res); i++)
        {
            if (imageFormats[i] != [NSNull null])
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

- (UIImage *) getImageWithImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType
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

- (UIImage *) getImageWithLocalID:(FluxLocalID *)localID withSize:(FluxImageType)imageType
{
    // If key doesn't exist, this will return nil.
    // This means it is either no longer in cache, or didn't exist in the first place
    FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
    return [fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:imageType]];
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
        if (imageObject.imageID >= 0)
        {
            NSLog(@"%s: imageID for localID %@ has previously been set (cid:%d, nid:%d).", __func__, localID, imageObject.imageID, imageID);
        }
        [imageIDMapping setValue:localID forKey:[NSString stringWithFormat:@"%d",imageID]];
    }
}

@end
