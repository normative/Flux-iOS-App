//
//  FluxDataStore.m
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 Normative. All rights reserved.
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

- (void) addImageToStore:(UIImage *)image withImageID:(FluxImageID)imageID withSize:(image_type)imageType
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

- (void) addImageToStore:(UIImage *)image withLocalID:(FluxLocalID *)localID withSize:(image_type)imageType
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
    [fluxMetadata setValue:metadata forKey:metadata.localID];
    
    if ((metadata.imageID >= 0) && ([imageIDMapping objectForKey:[NSString stringWithFormat:@"%d",metadata.imageID]] == nil))
    {
        [self setImageIDMapping:metadata.imageID forLocalID:metadata.localID];
    }
}

- (NSArray *) doesImageExistForImageID:(FluxImageID)imageID
{
    NSArray *imageFormats = [NSMutableArray arrayWithObjects:[NSNumber numberWithBool:NO],
                                    [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO],
                                    [NSNumber numberWithBool:NO], nil];

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
    NSMutableArray *imageFormats = [NSMutableArray arrayWithObjects:[NSNumber numberWithBool:NO],
                                    [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO],
                                    [NSNumber numberWithBool:NO], nil];
    
    if (localID != nil)
    {
        FluxScanImageObject *imageObject = [fluxMetadata objectForKey:localID];
        imageFormats[thumb] = [NSNumber numberWithBool:
                               ([fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:thumb]] != nil)];
        imageFormats[screen_res] = [NSNumber numberWithBool:
                                ([fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:screen_res]] != nil)];
        imageFormats[full_res] = [NSNumber numberWithBool:
                                ([fluxImageCache objectForKey:[imageObject generateImageCacheKeyWithImageType:full_res]] != nil)];
    }
    return [NSArray arrayWithArray:imageFormats];;
}

- (UIImage *) getImageWithImageID:(FluxImageID)imageID withSize:(image_type)imageType
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

- (UIImage *) getImageWithLocalID:(FluxLocalID *)localID withSize:(image_type)imageType
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
            NSLog(@"%s: imageID for localID %@ has previously been set.", __func__, localID);
        }
        [imageIDMapping setValue:localID forKey:[NSString stringWithFormat:@"%d",imageID]];
    }
}

@end
