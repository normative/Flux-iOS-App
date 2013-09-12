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

typedef NSString FluxLocalID;
typedef int FluxImageID;

enum image_types_enum {
    full_res = 0,
    thumb = 1,
    screen_res = 2,
};

struct image_exist_struct {
    BOOL full_res;
    BOOL thumb;
    BOOL screen_res;
};

typedef enum image_types_enum image_type;
typedef struct image_exist_struct image_exist;

@interface FluxDataStore : NSObject
{
    NSCache *fluxImageCache;
    NSMutableDictionary *fluxMetadata;
}

- (void) addImageToStore:(UIImage *)image withImageID:(FluxImageID *)imageID withSize:(image_type)imageType;
- (void) addImageToStore:(UIImage *)image withLocalID:(FluxLocalID *)localID withSize:(image_type)imageType;
- (void) addMetadataObject:(FluxScanImageObject *)metadata;
- (image_exist) doesImageExistForImageID:(FluxImageID *)imageID;
- (image_exist) doesImageExistForLocalID:(FluxLocalID *)localID;
- (UIImage *) getImageWithImageID:(FluxImageID *)imageID withSize:(image_type)imageType;
- (UIImage *) getImageWithLocalID:(FluxLocalID *)localID withSize:(image_type)imageType;
- (FluxScanImageObject *) getMetadataWithImageID:(FluxImageID *)imageID;
- (FluxScanImageObject *) getMetadataWithLocalID:(FluxLocalID *)localID;

//@property (strong) NSCache *fluxImageCache;
//@property (nonatomic, strong) NSMutableDictionary *fluxMetadata;

@end
