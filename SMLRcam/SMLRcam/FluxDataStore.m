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
    }
    return self;
}

- (void) addImageToStore:(UIImage *)image withImageID:(FluxImageID *)imageID withSize:(image_type)imageType
{
    
}

- (void) addImageToStore:(UIImage *)image withLocalID:(NSString *)localID withSize:(image_type)imageType
{
    
}

- (void) addMetadataObject:(FluxScanImageObject *)metadata
{
    
}

- (image_exist) doesImageExistForImageID:(FluxImageID *)imageID
{
    image_exist imageFormats = {NO, NO, NO};

    return imageFormats;
}

- (image_exist) doesImageExistForLocalID:(NSString *)localID
{
    image_exist imageFormats = {NO, NO, NO};

    return imageFormats;
}

- (UIImage *) getImageWithImageID:(FluxImageID *)imageID withSize:(image_type)imageType
{
    return nil;
}

- (UIImage *) getImageWithLocalID:(NSString *)localID withSize:(image_type)imageType
{
    return nil;
}

- (FluxScanImageObject *) getMetadataWithImageID:(FluxImageID *)imageID
{
    return nil;
}

- (FluxScanImageObject *) getMetadataWithLocalID:(NSString *)localID
{
    return nil;
}

@end
