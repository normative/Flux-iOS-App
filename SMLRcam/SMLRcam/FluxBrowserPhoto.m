//
//  FluxBrowserPhoto.m
//  Flux
//
//  Created by Kei Turner on 10/25/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxBrowserPhoto.h"
#import "FluxNetworkServices.h"

@implementation FluxBrowserPhoto

- (id)initWithImageObject:(FluxScanImageObject*)imgObject{
    NSString*urlString = [NSString stringWithFormat:@"%@images/%i/image?size=quarterhd",FluxProductionServerURL,imgObject.imageID];
    if (self = [super initWithURL:[NSURL URLWithString:urlString]])
    {
        self.caption = imgObject.descriptionString;
    }
    return self;
}

@end