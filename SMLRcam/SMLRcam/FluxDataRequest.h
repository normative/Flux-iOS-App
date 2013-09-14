//
//  FluxDataRequest.h
//  Flux
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxDataStore.h"
#import "FluxNetworkServices.h"
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"

enum request_type {
    no_request_specified = 0,
    time_value_request = 1,
    nearby_list_request = 2,
    metadata_request = 3,
    image_request = 4,
    data_upload_request = 5,
};

typedef enum request_type request_type;

typedef void (^ImageReadyBlock)(FluxLocalID *, FluxRequestID *);

// Data request object can store many things (parameters are optional depending on request type).
// It can store callbacks for success, failure, or for different operations.
// It can store arrays of images to download, along with a callback to
// individually process each one (either on cache retrieve or download).

@interface FluxDataRequest : NSObject
{
    // Callback for successful request
    
    // Callback for failed request
    
    // Callback for lower resolution image retrieved (might want to display temporary image)
}

@property (nonatomic) request_type requestType;

@property (nonatomic) image_type imageType;

// Lists of requested and completed image/metadata downloads
@property (nonatomic, strong) NSArray *requestedIDs;
@property (nonatomic, strong) NSMutableArray *completedIDs;

// Callback for single image retrieved (either from cache or download)
@property (strong) ImageReadyBlock imageReady;

- (void) whenImageReady:(FluxLocalID *)localID withRequestID:(FluxRequestID *)requestID;

@end
