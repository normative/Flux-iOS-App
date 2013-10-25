//
//  FluxBrowserPhoto.h
//  Flux
//
//  Created by Kei Turner on 10/25/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "IDMPhoto.h"
#import "FluxScanImageObject.h"

@interface FluxBrowserPhoto : IDMPhoto{
    
}

- (id)initWithImageObject:(FluxScanImageObject*)imgObject;

@end
