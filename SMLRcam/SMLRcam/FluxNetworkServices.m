//
//  FluxAPIInteraction.m
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxNetworkServices.h"
#import "FluxScanImageObject.h"
#import "FluxMappingProvider.h"




//serverURL
//#define externServerURL @"http://54.221.222.71/"
#define externServerURL @"http://54.221.254.230/"
#define localServerURL @"http://54.221.222.71/"

@implementation FluxNetworkServices

@synthesize delegate;


- (id)init {
    if (self = [super init]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL isremote = [[defaults objectForKey:@"Server Location"]intValue];
        if (isremote) {
            objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:externServerURL]];
        }
        else{
            objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:localServerURL]];
        }
        
        
        NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
        
        
        //setup descriptors for the user-related calls
        RKResponseDescriptor *userResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping] method:RKRequestMethodAny pathPattern:@"users" keyPath:nil statusCodes:statusCodes];
        
        RKRequestDescriptor *userRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider userPOSTMapping] objectClass:[FluxUserObject class] rootKeyPath:@"user" method:RKRequestMethodPOST];
        
        [objectManager addRequestDescriptor:userRequestDescriptor];
        [objectManager addResponseDescriptor:userResponseDescriptor];
        
        //and again for image-related calls
        RKResponseDescriptor *imageObjectResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:@"images" keyPath:nil statusCodes:statusCodes];
        
        RKRequestDescriptor *imageObjectRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider imagePOSTMapping] objectClass:[FluxScanImageObject class] rootKeyPath:@"image" method:RKRequestMethodPOST];
        
        [objectManager addRequestDescriptor:imageObjectRequestDescriptor];
        [objectManager addResponseDescriptor:imageObjectResponseDescriptor];
        
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [RKObjectMapping addDefaultDateFormatter:dateFormatter];
        
        //general init
        
        //set username and password
        //[objectManager.HTTPClient setAuthorizationHeaderWithUsername:@"username" password:@"password"];
        
        //show network activity indicator
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        //show alert if there is no network connectivity
        [objectManager.HTTPClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if (status == AFNetworkReachabilityStatusNotReachable) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection"
                                                                message:@"You must be connected to the internet to use this app."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }];
        
    }
    return self;
}

//returns the raw image (thumb for now) given an image ID
- (void)getImageForID:(int)imageID{
    NSString*url = [NSString stringWithFormat:@"%@images/%i/image?size=oriented",objectManager.baseURL,imageID];
    
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:nil                                                                                           success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImage:forImageID:)])
            {
                [delegate NetworkServices:self didreturnImage:image forImageID:imageID];
            }
        }
       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
           NSLog(@"Failed with error: %@", [error localizedDescription]);
           if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:)])
           {
               [delegate NetworkServices:self didFailWithError:error];
           }
       }];
    [operation start];
}

//returns the thumb image given an imageID
- (void)getThumbImageForID:(int)imageID{
    NSString*url = [NSString stringWithFormat:@"%@images/%i/image?size=thumb",objectManager.baseURL,imageID];

        
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:nil                                                                                           success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImage:forImageID:)])
            {
                [delegate NetworkServices:self didreturnImage:image forImageID:imageID];
            }
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:)])
            {
                [delegate NetworkServices:self didFailWithError:error];
            }
        }];
    [operation start];
}

- (void)getImageMetadataForID:(int)imageID{
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:[NSString stringWithFormat:@"/images/%i.json",imageID] keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1]]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        
        NSLog(@"Found %i Results",[result count]);
        if ([result count]>0) {
            FluxScanImageObject *imageObject = [result firstObject];
            [imageObject setLocalID:[imageObject generateUniqueStringID]];
            [imageObject setLocalThumbID:[NSString stringWithFormat:@"%@_thumb", imageObject.localID]];
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImageMetadata:)])
            {
                [delegate NetworkServices:self didreturnImageMetadata:imageObject];
            }
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:)])
        {
            [delegate NetworkServices:self didFailWithError:error];
        }
    }];
    [operation start];
}

- (void)getImagesForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius{
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:@"/images/closest.json" keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],location.latitude, location.longitude, radius]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        NSLog(@"Found %i Results",[result count]);
        
        if ([result count] > 0)
        {
            NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
            for (FluxScanImageObject*obj in result.array)
            {
                [obj setLocalID:[obj generateUniqueStringID]];
                [obj setLocalThumbID:[NSString stringWithFormat:@"%@_thumb", obj.localID]];
                [mutableDictionary setObject:obj forKey:[NSNumber numberWithInt:obj.imageID]];
            }
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImageList:)])
            {
                [delegate NetworkServices:self didreturnImageList: mutableDictionary];
            }
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:)])
        {
            [delegate NetworkServices:self didFailWithError:error];
        }
    }];
    [operation start];
}

- (void)getAllImages{
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:@"/images.json" keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1]]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        NSLog(@"Found %i Results",[result count]);
        
        if ([result count] > 0)
        {
            NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
            for (FluxScanImageObject*obj in result.array)
            {
                [obj setLocalID:[obj generateUniqueStringID]];
                [obj setLocalThumbID:[NSString stringWithFormat:@"%@_thumb", obj.localID]];
                [mutableDictionary setObject:obj forKey:[NSNumber numberWithInt:obj.imageID]];
            }
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImageList:)])
            {
                [delegate NetworkServices:self didreturnImageList: mutableDictionary];
            }
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:)])
        {
            [delegate NetworkServices:self didFailWithError:error];
        }
    }];
    [operation start];
}

- (void)uploadImage:(FluxScanImageObject*)theImageObject andImage:(UIImage *)theImage;
{
    // Serialize the Article attributes then attach a file
    NSMutableURLRequest *request = [[RKObjectManager sharedManager] multipartFormRequestWithObject:theImageObject method:RKRequestMethodPOST path:@"/images" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(theImage, 0.7)
                                    name:@"image[image]"
                                fileName:@"photo.jpeg"
                                mimeType:@"image/jpeg"];
    }];
    
    RKObjectRequestOperation *operation = [[RKObjectManager sharedManager] objectRequestOperationWithRequest:request success:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        if ([result count]>0) {
            FluxScanImageObject *imageObject = [result firstObject];
            [imageObject setLocalID:[imageObject generateUniqueStringID]];
            [imageObject setLocalThumbID:[NSString stringWithFormat:@"%@_thumb", imageObject.localID]];
            NSLog(@"Successfully Uploaded Image to account # %i",imageObject.userID);
            if ([delegate respondsToSelector:@selector(NetworkServices:didUploadImage:)])
            {
                [delegate NetworkServices:self didUploadImage:imageObject];
            }
        }
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:)])
        {
            [delegate NetworkServices:self didFailWithError:error];
        }
    }];
    [[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation]; // NOTE: Must be enqueued rather than started
    
//    if ([delegate respondsToSelector:@selector(NetworkServices:uploadProgress:ofExpectedPacketSize:)])
//    {
//        [operation.HTTPRequestOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
//            if (totalBytesExpectedToWrite > 0 && totalBytesExpectedToWrite < NSUIntegerMax) {
//                [delegate NetworkServices:self uploadProgress:(float)totalBytesWritten ofExpectedPacketSize:(float)totalBytesExpectedToWrite];
//            }
//            NSLog(@"bytesWritten: %d, totalBytesWritten: %lld, totalBytesExpectedToWrite: %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
//        }];
//    }
    // monitor upload progress
    
}

- (void)createUser:(FluxUserObject*)user{

    [objectManager postObject:user path:@"/users" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *result){
            if ([result count]>0) {
                
                FluxUserObject*temp = [result firstObject];
                NSLog(@"Successfuly Created userObject %i with details: %@ %@: %@",temp.userID,temp.firstName, temp.lastName,temp.userName);

                if ([delegate respondsToSelector:@selector(NetworkServices:didCreateUser:)])
                {
                    [delegate NetworkServices:self didCreateUser:temp];
                }
        }
    }failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:)])
        {
            [delegate NetworkServices:self didFailWithError:error];
        }
    }];
}

- (void)getUserForID:(int)userID{
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping] method:RKRequestMethodAny pathPattern:[NSString stringWithFormat:@"/users/%i.json",userID] keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1]]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        
        NSLog(@"Found %i Results",[result count]);
        if ([result count]>0) {
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImageMetadata:)])
            {
                [delegate NetworkServices:self didreturnImageMetadata:[result firstObject]];
            }
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:)])
        {
            [delegate NetworkServices:self didFailWithError:error];
        }
    }];
    [operation start];
}



@end
