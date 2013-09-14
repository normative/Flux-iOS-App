//
//  FluxDataRequest.m
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDataRequest.h"

@implementation FluxDataRequest

- (id)init
{
    if (self = [super init])
    {
        _completedIDs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) whenImageReady:(FluxLocalID *)localID withRequestID:(FluxRequestID *)requestID
{
    if (self.imageReady)
    {
        self.imageReady(localID, requestID);
    }
}

@end
