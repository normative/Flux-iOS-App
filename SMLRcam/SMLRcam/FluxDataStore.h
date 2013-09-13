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

struct image_exist_struct {
    BOOL thumb;
    BOOL screen_res;
    BOOL full_res;
};

typedef struct image_exist_struct image_exist;

@interface FluxDataStore : NSObject
{
    NSCache *fluxImageCache;
    NSMutableDictionary *fluxMetadata;
    NSMutableDictionary *imageIDMapping;
}

- (void) addImageToStore:(UIImage *)image withImageID:(FluxImageID)imageID withSize:(image_type)imageType;
- (void) addImageToStore:(UIImage *)image withLocalID:(FluxLocalID *)localID withSize:(image_type)imageType;
- (void) addMetadataObject:(FluxScanImageObject *)metadata;
- (image_exist) doesImageExistForImageID:(FluxImageID)imageID;
- (image_exist) doesImageExistForLocalID:(FluxLocalID *)localID;
- (UIImage *) getImageWithImageID:(FluxImageID)imageID withSize:(image_type)imageType;
- (UIImage *) getImageWithLocalID:(FluxLocalID *)localID withSize:(image_type)imageType;
- (FluxScanImageObject *) getMetadataWithImageID:(FluxImageID)imageID;
- (FluxScanImageObject *) getMetadataWithLocalID:(FluxLocalID *)localID;
- (void) setImageIDMapping:(FluxImageID)imageID forLocalID:(FluxLocalID *)localID;

@end
