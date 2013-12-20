//
//  FluxMappingProvider.m
//  Flux
//
//  Created by Kei Turner on 2013-08-15.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxMappingProvider.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"
#import "FluxTagObject.h"
#import "FluxMapImageObject.h"
#import "FluxCameraObject.h"
#import "FluxProfileImageObject.h"

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
    
    [mapping addAttributeMappingsFromArray:@[@"heading", @"longitude", @"latitude", @"altitude", @"yaw", @"pitch", @"roll", @"qw", @"qx", @"qy", @"qz", @"horiz_accuracy", @"vert_accuracy", @"privacy"]];
    
    return mapping;
}

#pragma mark - User Mapping

+ (RKObjectMapping *)userGETMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxUserObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":                @"userID",
                                                  @"follower_count":     @"followerCount",
                                                  @"following_count":    @"followingCount",
                                                  @"image_count":        @"imageCount",
                                                  @"friend":             @"isFriends",
                                                  @"amifollowing":       @"isFollowing",
                                                  @"aretheyfollowing":   @"isFollower",
                                                  @"has_pic":            @"hasProfilePic"
                                                 }];
    
    [mapping addAttributeMappingsFromArray:@[@"name", @"password", @"username", @"email", @"auth_token", @"bio"]];
    
    return mapping;
}
+ (RKObjectMapping *)userPOSTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromArray:@[@"name", @"password", @"username", @"email", @"auth_token"]];
    
    return mapping;
}

+ (RKObjectMapping *)userImagesGetMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxProfileImageObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":  @"imageID"
                                                  }];
    
    [mapping addAttributeMappingsFromArray:@[@"description"]];
    
    return mapping;
}

+ (RKObjectMapping *)cameraPostMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"userID":            @"user_id",
                                                  @"deviceID":   @"deviceid",
                                                  @"model":    @"model"
                                                  }];
    
    return mapping;
}

+ (RKObjectMapping *)cameraGETMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxCameraObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"user_id":            @"userID",
                                                  @"deviceid":   @"deviceID",
                                                  @"model":    @"model",
                                                  @"id":        @"cameraID"
                                                  }];
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
