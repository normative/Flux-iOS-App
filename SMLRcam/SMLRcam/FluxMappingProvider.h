//
//  FluxMappingProvider.h
//  Flux
//
//  Created by Kei Turner on 2013-08-15.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxMappingProvider : NSObject{
    
}

+ (RKObjectMapping *)imageGETMapping;
+ (RKObjectMapping *)imagePOSTMapping;

+ (RKObjectMapping *)userGETMapping;
+ (RKObjectMapping *)userRegistrationGETMapping;
+ (RKObjectMapping *)userPOSTMapping;
+ (RKObjectMapping *)userPATCHMapping;

+ (RKObjectMapping *)cameraPostMapping;
+ (RKObjectMapping *)cameraGETMapping;

+ (RKObjectMapping *)connectionGETMapping;
+ (RKObjectMapping *)connectionPOSTMapping;

+ (RKObjectMapping *)aliasPOSTMapping;
+ (RKObjectMapping *)aliasGETMapping;
+ (RKObjectMapping *)contactGETMapping;

+ (RKObjectMapping *)userImagesGetMapping;

+ (RKObjectMapping *)tagGetMapping;

+ (RKObjectMapping *)filterImageCountsGetMapping;

+ (RKObjectMapping *)mapImageGetMapping;

@end
