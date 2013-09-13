//
//  FluxMappingProvider.h
//  Flux
//
//  Created by Kei Turner on 2013-08-15.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxMappingProvider : NSObject{
    
}

+ (RKObjectMapping *)imageGETMapping;
+ (RKObjectMapping *)imagePOSTMapping;

+ (RKObjectMapping *)userGETMapping;
+ (RKObjectMapping *)userPOSTMapping;

+ (RKObjectMapping *)tagGetMapping;

@end
