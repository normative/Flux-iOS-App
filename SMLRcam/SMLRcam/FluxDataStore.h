//
//  FluxDataStore.h
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxNetworkServices.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"

@interface FluxDataStore : NSObject
{
    NSCache *fluxImageCache;
    NSMutableDictionary *fluxMetadata;
    NSMutableDictionary *imageIDMapping;
}

- (void) addImageToStore:(UIImage *)image withImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType;
- (void) addImageToStore:(UIImage *)image withLocalID:(FluxLocalID *)localID withSize:(FluxImageType)imageType;
- (void) addMetadataObject:(FluxScanImageObject *)metadata;
- (NSArray *) doesImageExistForImageID:(FluxImageID)imageID;
- (NSArray *) doesImageExistForLocalID:(FluxLocalID *)localID;
- (UIImage *) getImageWithImageID:(FluxImageID)imageID withSize:(FluxImageType)imageType;
- (UIImage *) getImageWithLocalID:(FluxLocalID *)localID withSize:(FluxImageType)imageType;
- (FluxScanImageObject *) getMetadataWithImageID:(FluxImageID)imageID;
- (FluxScanImageObject *) getMetadataWithLocalID:(FluxLocalID *)localID;
- (void) setImageIDMapping:(FluxImageID)imageID forLocalID:(FluxLocalID *)localID;

@end
