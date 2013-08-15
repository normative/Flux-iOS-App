//
//  FluxAPIInteraction.m
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxAPIInteraction.h"
#import "FluxScanImageObject.h"
#import "FluxMappingProvider.h"




//serverURL
#define serverURL @"http://192.168.0.65/"

@implementation FluxAPIInteraction

@synthesize delegate;


- (id)init {
    if (self = [super init]) {
        
        objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:serverURL]];
        
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
    NSString*url = [NSString stringWithFormat:@"%@images/%i/image",serverURL,imageID];
    
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
        if ([delegate respondsToSelector:@selector(APIInteraction:didreturnImage:)])
        {
            [delegate APIInteraction:self didreturnImage:image];
        }
    }];
    [operation start];
}

//returns the thumb image given an imageID
- (void)getThumbImageForID:(int)imageID{
    NSString*url = [NSString stringWithFormat:@"%@images/%i/image",serverURL,imageID];

        
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request success:^(UIImage *image) {
            if ([delegate respondsToSelector:@selector(APIInteraction:didreturnImage:)])
            {
                [delegate APIInteraction:self didreturnImage:image];
            }
        }];
    [operation start];
}

- (void)getImageMetadataForID:(int)imageID{
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:[NSString stringWithFormat:@"/images/%i.json",imageID] keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",serverURL,[responseDescriptor.pathPattern substringFromIndex:1]]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        
        NSLog(@"Found %i Results",[result count]);
        if ([result count]>0) {
            if ([delegate respondsToSelector:@selector(APIInteraction:didreturnImageMetadata:)])
            {
                [delegate APIInteraction:self didreturnImageMetadata:[result firstObject]];
            }
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
    }];
    [operation start];
}

- (void)getImagesForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius{
    
}

- (void)getAllImages{
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:@"/images.json" keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",serverURL,[responseDescriptor.pathPattern substringFromIndex:1]]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        NSLog(@"Found %i Results",[result count]);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
    }];
    [operation start];
}

- (void)uploadImage:(FluxScanImageObject*)img{
   
    // Serialize the Article attributes then attach a file
    NSMutableURLRequest *request = [[RKObjectManager sharedManager] multipartFormRequestWithObject:img method:RKRequestMethodPOST path:@"/images" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImagePNGRepresentation(img.contentImage)
                                    name:@"image[image]"
                                fileName:@"photo.png"
                                mimeType:@"image/png"];
    }];
    
    RKObjectRequestOperation *operation = [[RKObjectManager sharedManager] objectRequestOperationWithRequest:request success:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        if ([result count]>0) {
            NSLog(@"Successfully Uploaded Image to account # %i",[[result firstObject]userID]);
            if ([delegate respondsToSelector:@selector(APIInteraction:didUploadImage:)])
            {
                [delegate APIInteraction:self didUploadImage:[result firstObject]];
            }
        }
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
    }];

    [[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation]; // NOTE: Must be enqueued rather than started
}

- (void)createUser:(FluxUserObject*)user{

    [objectManager postObject:user path:@"/users" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *result){
            if ([result count]>0) {
                
                FluxUserObject*temp = [result firstObject];
                NSLog(@"Successfuly Created userObject %i with details: %@ %@: %@",temp.userID,temp.firstName, temp.lastName,temp.userName);

                if ([delegate respondsToSelector:@selector(APIInteraction:didCreateUser:)])
                {
                    [delegate APIInteraction:self didCreateUser:temp];
                }
        }
    }failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
    }];
}

- (void)getUserForID:(int)userID{
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping] method:RKRequestMethodAny pathPattern:[NSString stringWithFormat:@"/users/%i.json",userID] keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",serverURL,[responseDescriptor.pathPattern substringFromIndex:1]]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        
        NSLog(@"Found %i Results",[result count]);
        if ([result count]>0) {
            if ([delegate respondsToSelector:@selector(APIInteraction:didreturnImageMetadata:)])
            {
                [delegate APIInteraction:self didreturnImageMetadata:[result firstObject]];
            }
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
    }];
    [operation start];
}



@end
