//
//  FluxDataStore.h
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxCacheImageObject.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"

@interface FluxDataStore : NSObject <NSCacheDelegate>
{
    NSCache *fluxImageCache;
    NSMutableDictionary *fluxMetadata;
    NSMutableDictionary *imageIDMapping;
    NSMutableDictionary *cachedImageLocalIDList;
}

- (FluxCacheImageObject *) addImageToStore:(UIImage *)image withImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType;
- (FluxCacheImageObject *) addImageToStore:(UIImage *)image withLocalID:(FluxLocalID *)localID withSize:(FluxImageType)imageType;
- (void) addMetadataObject:(FluxScanImageObject *)metadata;
- (NSArray *) doesImageExistForImageID:(FluxImageID)imageID;
- (NSArray *) doesImageExistForLocalID:(FluxLocalID *)localID;
- (FluxCacheImageObject *) getImageWithImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType;
- (FluxCacheImageObject *) getImageWithLocalID:(FluxLocalID *)localID withSize:(FluxImageType)imageType;
- (FluxScanImageObject *) getMetadataWithImageID:(FluxImageID)imageID;
- (FluxScanImageObject *) getMetadataWithLocalID:(FluxLocalID *)localID;
- (void) setImageIDMapping:(FluxImageID)imageID forLocalID:(FluxLocalID *)localID;
- (void)resetAllFeatureMatches;

- (void)debugByShowingCachedImageKeys;
- (void)cleanupNonLocalContentWithLocalIDArray:(NSArray *)localItems;

@end
