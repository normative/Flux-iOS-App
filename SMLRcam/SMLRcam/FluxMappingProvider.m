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

@implementation FluxMappingProvider

+ (RKObjectMapping *)imageGETMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxScanImageObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":   @"imageID",
                                                  @"category_id":     @"categoryID",
                                                  @"created_at":        @"timestampString",
                                                  @"description":   @"descriptionString",
                                                  @"user_id":   @"userID",
                                                  @"camera_id":   @"cameraID"
                                                  }];
    
    [mapping addAttributeMappingsFromArray:@[@"heading", @"longitude", @"latitude", @"altitude", @"yaw", @"pitch", @"roll", @"qw", @"qx", @"qy", @"qz"]];
    
    return mapping;
}

+ (RKObjectMapping *)imagePOSTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addAttributeMappingsFromDictionary:@{
                                                         @"imageID":   @"id",
                                                         @"categoryID":     @"category_id",
                                                         @"timestampString":        @"created_at",
                                                         @"descriptionString":   @"description",
                                                         @"cameraID":     @"camera_id",
                                                         @"userID":     @"user_id"
                                                         }];

    
    [mapping addAttributeMappingsFromArray:@[@"heading", @"longitude", @"latitude", @"altitude", @"yaw", @"pitch", @"roll", @"qw", @"qx", @"qy", @"qz"]];
    
    return mapping;
}

+ (RKObjectMapping *)userGETMapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[FluxUserObject class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"id":   @"userID",
                                                  @"firstname":     @"firstName",
                                                  @"lastname":        @"lastName",
                                                  @"nickname":   @"userName",
                                                  @"created_at":        @"dateCreated"
                                                  }];
    
    [mapping addAttributeMappingsFromArray:@[@"privacy"]];
    
    return mapping;
}
+ (RKObjectMapping *)userPOSTMapping{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                         @"firstName":     @"firstname",
                                                         @"lastName":        @"lastname",
                                                         @"userName":   @"nickname",
                                                         @"dateCreated":        @"created_at",
                                                         @"userID":   @"id"
                                                         }];
    
    [mapping addAttributeMappingsFromArray:@[@"privacy"]];
    
    return mapping;
}

@end
