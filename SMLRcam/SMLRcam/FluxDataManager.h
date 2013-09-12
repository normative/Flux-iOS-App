//
//  FluxDataManager.h
//  Flux
//
//  Created by Ryan Martens on 9/12/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxDataRequest.h"
#import "FluxDataStore.h"
#import "FluxNetworkServices.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"

@interface FluxDataManager : NSObject <NetworkServicesDelegate>
{
    FluxDataStore *fluxDataStore;
    FluxNetworkServices *networkServices;
    NSMutableDictionary *currentRequests;
}

@end
