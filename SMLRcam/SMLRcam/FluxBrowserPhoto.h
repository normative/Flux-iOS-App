//
//  FluxBrowserPhoto.h
//  Flux
//
//  Created by Kei Turner on 10/25/2013.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "IDMPhoto.h"
#import "FluxScanImageObject.h"

@interface FluxBrowserPhoto : IDMPhoto{

}

@property(nonatomic) int userID;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString*timestring;

- (id)initWithImageObject:(FluxScanImageObject*)imgObject;

@end
