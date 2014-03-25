//
//  FluxProfileImageObject.h
//  Flux
//
//  Created by Kei Turner on 12/5/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxProfileImageObject : NSObject

@property (nonatomic)int imageID;
@property (nonatomic, strong)NSString* description;
@property (nonatomic, strong)UIImage* image;
@property (nonatomic) Boolean privacy;

@end
