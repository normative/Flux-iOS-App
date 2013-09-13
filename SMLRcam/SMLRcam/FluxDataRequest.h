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

enum request_types_enum {
    time_value_request = 0,
    nearby_list_request = 1,
    metadata_request = 2,
    image_request = 3,
    data_upload_request = 4,
};

typedef enum request_types_enum request_type;

// Data request object can store many things (parameters are optional depending on request type).
// It can store callbacks for success, failure, or for different operations.
// It can store arrays of images to download, along with a callback to
// individually process each one (either on cache retrieve or download).

@interface FluxDataRequest : NSObject
{
    request_type requestType;
    
    // Dictionary of requested and completed image/metadata downloads, with an image_exist value to store image size
    NSMutableDictionary *requestedIDs;
    NSMutableDictionary *completedIDs;
    
    // Callback for successful request
    
    // Callback for failed request
    
    // Callback for single image retrieved (either from cache or download)
    
    // Callback for lower resolution image retrieved (might want to display temporary image)
}

@end
