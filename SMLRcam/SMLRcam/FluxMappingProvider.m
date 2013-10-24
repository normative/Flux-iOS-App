//
//  FluxMappingProvider.m
//  Flux
//
//  Created by Kei Turner on 2013-08-15.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMappingProvider.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"
#import "FluxTagObject.h"
#import "FluxMapImageObject.h"

@implementation FluxMappingProvider

#pragma mark - Image Mapping

+ (RKObjectMapping *)imageGETMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxScanImageObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":            @"imageID",
                                                  @"category_id":   @"categoryID",
                                                  @"time_stamp":    @"timestamp",
                                                  @"description":   @"descriptionString",
                                                  @"user_id":       @"userID",
                                                  @"camera_id":     @"cameraID",
                                                  @"user":          @"username"
                                                 }];
    
    [mapping addAttributeMappingsFromArray:@[@"heading", @"longitude", @"latitude", @"altitude", @"yaw", @"pitch", @"roll", @"qw", @"qx", @"qy", @"qz"]];
    
    return mapping;
}

+ (RKObjectMapping *)imagePOSTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"imageID":            @"id",
                                                  @"categoryID":         @"category_id",
                                                  @"timestampString":    @"time_stamp",
                                                  @"descriptionString":  @"description",
                                                  @"cameraID":           @"camera_id",
                                                  @"userID":             @"user_id"
                                                 }];
    
    [mapping addAttributeMappingsFromArray:@[@"heading", @"longitude", @"latitude", @"altitude", @"yaw", @"pitch", @"roll", @"qw", @"qx", @"qy", @"qz", @"horiz_accuracy", @"vert_accuracy"]];
    
    return mapping;
}

#pragma mark - User Mapping

+ (RKObjectMapping *)userGETMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxUserObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":            @"userID",
                                                  @"firstname":     @"firstName",
                                                  @"lastname":      @"lastName",
                                                  @"nickname":      @"userName",
                                                  @"created_at":    @"dateCreated"
                                                 }];
    
    [mapping addAttributeMappingsFromArray:@[@"privacy"]];
    
    return mapping;
}
+ (RKObjectMapping *)userPOSTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"firstName":     @"firstname",
                                                  @"lastName":      @"lastname",
                                                  @"userName":      @"nickname",
                                                  @"dateCreated":   @"created_at",
                                                  @"userID":        @"id"
                                                 }];
    
    [mapping addAttributeMappingsFromArray:@[@"privacy"]];
    
    return mapping;
}

#pragma mark - Tag Mapping

+ (RKObjectMapping *)tagGetMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxTagObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"tagtext":   @"tagText",
                                                  @"count":     @"count"
                                                 }];
    return mapping;
}

#pragma mark - Map Image Mapping

+ (RKObjectMapping *)mapImageGetMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxMapImageObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":   @"imageID"}];
    
    [mapping addAttributeMappingsFromArray:@[@"longitude", @"latitude"]];
    
    return mapping;
}

@end
