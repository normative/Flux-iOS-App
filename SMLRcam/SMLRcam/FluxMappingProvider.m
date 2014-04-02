//
//  FluxMappingProvider.m
//  Flux
//
//  Created by Kei Turner on 2013-08-15.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxMappingProvider.h"
#import "FluxScanImageObject.h"
#import "FluxRegistrationUserObject.h"
#import "FluxTagObject.h"
#import "FluxConnectionObject.h"
#import "FluxMapImageObject.h"
#import "FluxCameraObject.h"
#import "FluxProfileImageObject.h"
#import "FluxFilterImageCountObject.h"
#import "FluxAliasObject.h"
#import "FluxContactObject.h"

@implementation FluxMappingProvider

#pragma mark - Image Mapping

+ (RKObjectMapping *)imageGETMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxScanImageObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":            @"imageID",
                                                  @"category_id":   @"categoryID",
                                                  @"time_stamp":    @"timestampString",
                                                  @"description":   @"descriptionString",
                                                  @"user_id":       @"userID",
                                                  @"camera_id":     @"cameraID",
                                                  @"camera_model":  @"cameraModelStr"
                                                 }];
    
    [mapping addAttributeMappingsFromArray:@[@"username",@"heading", @"longitude", @"latitude", @"altitude", @"yaw", @"pitch", @"roll", @"qw", @"qx", @"qy", @"qz"]];
    
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
                                                  @"am_follower":       @"amFollowerFlag",
                                                  @"is_following":   @"isFollowingFlag",
                                                  @"has_pic":            @"hasProfilePic"
                                                 }];
    
    [mapping addAttributeMappingsFromArray:@[@"name", @"password", @"username", @"email", @"bio"]];
    
    return mapping;
}

+ (RKObjectMapping *)userRegistrationGETMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxRegistrationUserObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":                @"userID",
                                                  @"has_pic":            @"hasProfilePic"
                                                  }];
    
    [mapping addAttributeMappingsFromArray:@[@"name", @"password", @"username", @"email", @"auth_token", @"bio"]];
    
    return mapping;
}


+ (RKObjectMapping *)userPOSTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromArray:@[@"name", @"password", @"username", @"email", @"auth_token", @"facebook", @"twitter"]];
    
    return mapping;
}

+ (RKObjectMapping *)userImagesGetMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxProfileImageObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":  @"imageID",
                                                  }];
    
    [mapping addAttributeMappingsFromArray:@[@"description", @"privacy"]];
    
    return mapping;
}

+ (RKObjectMapping *)userImagesPUTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"imageID": @"id"}];
    
    [mapping addAttributeMappingsFromArray:@[@"description", @"privacy"]];
    
    return mapping;
}

+ (RKObjectMapping *)userPATCHMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"password": @"current_password"}];
    
    [mapping addAttributeMappingsFromArray:@[@"name", @"username", @"email", @"bio"]];
    
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

#pragma mark - Social Mapping
+ (RKObjectMapping *)connectionGETMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxConnectionObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"user_id":   @"userID",
                                                  @"connections_id":     @"connectionsUserID",
                                                   @"id":   @"connectionID",
                                                   @"following_state":   @"followingState"
                                                  }];
    return mapping;
}
+ (RKObjectMapping *)connectionPOSTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"userID":            @"user_id",
                                                  @"connectionsUserID":   @"connections_id",
                                                  @"connetionType":   @"connection_type",
                                                  @"followingState":   @"following_state"
                                                  }];
    
    return mapping;
}

#pragma mark Alias Mapping

+ (RKObjectMapping *)aliasGETMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxAliasObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"user_id":     @"userID",
                                                  @"alias_name":  @"alias_name",
                                                  @"service_id":  @"serviceID"
                                                  }];
    return mapping;
}
+ (RKObjectMapping *)aliasPOSTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"userID":      @"user_id",
                                                  @"alias_name":  @"alias_name",
                                                  @"serviceID":   @"service_id"
                                                  }];
    
    return mapping;
}
+ (RKObjectMapping *)contactGETMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxContactObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"user_id":        @"userID",
                                                  @"am_follower":       @"amFollowerFlag",
                                                  @"is_following":   @"isFollowingFlag",
                                                  @"alias_name":   @"aliasName",
                                                  @"display_name":   @"displayName",
                                                  @"profile_pic_URL":   @"profilePicURL",
                                                  @"social_id":      @"socialID"
                                                  }];
    
    [mapping addAttributeMappingsFromArray:@[@"username"]];

    return mapping;
}

#pragma mark - Filters Mapping

+ (RKObjectMapping *)tagGetMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxTagObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"tagtext":   @"tagText",
                                                  @"count":     @"count"
                                                 }];
    return mapping;
}

+ (RKObjectMapping *)filterImageCountsGetMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxFilterImageCountObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"totalimgcount":   @"totalImageCount",
                                                  @"myimgcount":     @"activeUserImageCount",
                                                  @"followingimgcount":   @"activerUserFollowingsImageCount"
                                                  }];
    return mapping;
}

#pragma mark - Map Image Mapping

+ (RKObjectMapping *)mapImageGetMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxMapImageObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":   @"imageID"}];
    
    [mapping addAttributeMappingsFromArray:@[@"longitude", @"latitude", @"altitude"]];
    
    return mapping;
}

@end
