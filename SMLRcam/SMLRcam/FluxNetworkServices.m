//
//  FluxAPIInteraction.m
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxNetworkServices.h"
#import "FluxScanImageObject.h"
#import "FluxTagObject.h"
#import "FluxMappingProvider.h"
#import "FluxLocationServicesSingleton.h"
#import "UICKeyChainStore.h"



NSString* const FluxProductionServerURL = @"http://54.221.254.230/";
NSString* const FluxTestServerURL = @"http://54.221.222.71/";

//serverURL
//#define externServerURL @"http://54.221.222.71/"
#define productionServerURL @"http://54.221.254.230/"
#define testServerURL @"http://54.221.222.71/"
//#define productionServerURL @"http://192.168.2.18:3001/"

@implementation FluxNetworkServices

@synthesize delegate;

- (NSString *)get_token
{
    if (_token == nil)
    {
        _token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
        NSLog(@"Fetching token key from key chain store");
        if (_token == nil)
            _token = @"";
    }
    
    return _token;
}

- (id)init
{
    if (self = [super init])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL isremote = [[defaults objectForKey:@"Server Location"]intValue];
        if (isremote)
        {
            objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:productionServerURL]];
        }
        else
        {
            objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:testServerURL]];
        }
        
        NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
        
        //setup descriptors for the user-related calls
        RKResponseDescriptor *userResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                                    method:RKRequestMethodAny
                                                                                               pathPattern:@"users"
                                                                                                   keyPath:nil
                                                                                               statusCodes:statusCodes];
        
        RKResponseDescriptor *userLoginResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                                    method:RKRequestMethodAny
                                                                                               pathPattern:@"users/sign_in"
                                                                                                   keyPath:nil
                                                                                               statusCodes:statusCodes];
        
        RKResponseDescriptor *cameraCreationResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider cameraGETMapping]
                                                                                                         method:RKRequestMethodAny
                                                                                                    pathPattern:@"cameras"
                                                                                                        keyPath:nil
                                                                                                    statusCodes:statusCodes];
        
        
        RKRequestDescriptor *cameraRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider cameraPostMapping]
                                                                                           objectClass:[FluxCameraObject class]
                                                                                           rootKeyPath:@"camera"
                                                                                                method:RKRequestMethodPOST];
        
        RKRequestDescriptor *userRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider userPOSTMapping]
                                                                                           objectClass:[FluxUserObject class]
                                                                                           rootKeyPath:@"user"
                                                                                                method:RKRequestMethodPOST];
        
        
        
        [objectManager addRequestDescriptor:userRequestDescriptor];
        [objectManager addRequestDescriptor:cameraRequestDescriptor];
        [objectManager addResponseDescriptor:userResponseDescriptor];
        [objectManager addResponseDescriptor:userLoginResponseDescriptor];
        [objectManager addResponseDescriptor:cameraCreationResponseDescriptor];
        
        //and again for image-related calls
        RKResponseDescriptor *imageObjectResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping]
                                                                                                           method:RKRequestMethodAny
                                                                                                      pathPattern:@"images"
                                                                                                          keyPath:nil
                                                                                                      statusCodes:statusCodes];
        
        RKRequestDescriptor *imageObjectRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider imagePOSTMapping]
                                                                                                  objectClass:[FluxScanImageObject class]
                                                                                                  rootKeyPath:@"image"
                                                                                                       method:RKRequestMethodPOST];
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

//returns the raw image given an image ID
- (void)getImageForID:(int)imageID withStringSize:(NSString *)sizeString andRequestID:(FluxRequestID *)requestID
{
    NSString*url = [NSString stringWithFormat:@"%@images/%i/image?auth_token='%@'&size=%@",objectManager.baseURL,imageID,self.token,sizeString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request
                                                                              imageProcessingBlock:nil
                                                                                           success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
    {
        if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImage:forImageID:andRequestID:)])
        {
            [delegate NetworkServices:self didreturnImage:image forImageID:imageID andRequestID:requestID];
        }
    }
                                                                                           failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
    {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
        {
            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
        }    }];
    [operation start];
}

- (void)getImageMetadataForID:(int)imageID andRequestID:(FluxRequestID *)requestID
{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:[NSString stringWithFormat:@"/images/%i.json?auth_token='%@'",imageID,self.token]
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1]]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
    {
        NSLog(@"%s: Found %i Results",__func__, [result count]);
        if ([result count]>0)
        {
            FluxScanImageObject *imageObject = [result firstObject];
            [imageObject setLocalID:[imageObject generateUniqueStringID]];
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImageMetadata:andRequestID:)])
            {
                [delegate NetworkServices:self didreturnImageMetadata:imageObject andRequestID:requestID];
            }
        }
    }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
        {
            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
        }    }];
    [operation start];
}

- (void)getImagesForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius andRequestID:(FluxRequestID *)requestID
{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/images/closest.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:
                                                          [NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&auth_token='%@'",
                                                                                    objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                                    location.latitude, location.longitude, radius, self.token]]];
    
    [self doRequest:request withResponseDesc:responseDescriptor andRequestID:requestID];
}


- (void)getImagesForLocationFiltered:(CLLocationCoordinate2D)location
                           andRadius:(float)radius
                           andMinAlt:(float)altMin
                           andMaxAlt:(float)altMax
                     andMinTimestamp:(NSDate *)timeMin
                     andMaxTimestamp:(NSDate *)timeMax
                         andHashTags:(NSString *)hashTags
                            andUsers:(NSString *)users
                       andCategories:(NSString *)cats
                         andMaxCount:(int)maxCount
                        andRequestID:(FluxRequestID *)requestID;

{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx

//    example initialization:
//    
//    NSString *hashTags =    @"''";      // escaped-space-delimited (%20) list of hash tags (OR test) eg. "'tag1%20tag2'"
//    NSString *cats =        @"''";      // escaped-space-delimited (%20) list of categories (OR test) eg. "'place%20thing'"
//    NSString *users =       @"''";      // escaped-space-delimited (%20) list of user nicknames (OR test) eg. "'steve%20bob'"
//    float altMin = -10000.0;  //meters
//    float altMax = +10000.0; //meters
//    NSDate *timeMin = [[NSDate alloc] init];
//    timeMin = [NSDate dateWithTimeIntervalSince1970:0];   // a long time ago...
//    NSDate *timeMax = [[NSDate alloc] init];              // now
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSString *timestampMin = [NSString stringWithFormat:@"'%@'", [dateFormatter stringFromDate:timeMin]];
    NSString *timestampMax = [NSString stringWithFormat:@"'%@'", [dateFormatter stringFromDate:timeMax]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:@"/images/filtered.json" keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&altmin=%f&altmax=%f&timemin=%@&timemax=%@&taglist='%@'&userlist='%@'&catlist='%@'&maxcount=%d&auth_token='%@'",
                                                                               objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                               location.latitude, location.longitude, radius,
                                                                               altMin, altMax,
                                                                               timestampMin, timestampMax,
                                                                               hashTags, users, cats, maxCount,self.token]]];

    [self doRequest:request withResponseDesc:responseDescriptor andRequestID:requestID];
    
}

    
    
- (void)doRequest:(NSURLRequest *)request withResponseDesc:(RKResponseDescriptor *)responseDescriptor andRequestID:(FluxRequestID *)requestID
{
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
    {
        NSLog(@"%s: Found %i Standard Images",__func__,[result count]);
        
        if ([result count] > 0)
        {
            NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
            for (FluxScanImageObject*obj in result.array)
            {
                [obj setLocalID:[obj generateUniqueStringID]];
                [mutableArray addObject:obj];
            }
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImageList:andRequestID:)])
            {
                [delegate NetworkServices:self didreturnImageList:[NSArray arrayWithArray:mutableArray] andRequestID:requestID];
            }
        }
    }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
        {
            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
        }    }];
    [operation start];
}

- (void)uploadImage:(FluxScanImageObject*)theImageObject andImage:(UIImage *)theImage andRequestID:(FluxRequestID *)requestID;
{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];

    NSLog(@"Uploading image with positional accuracy: %f, %f", theImageObject.horiz_accuracy, theImageObject.vert_accuracy);
    
    // Serialize the Article attributes then attach a file
    NSMutableURLRequest *request = [[RKObjectManager sharedManager] multipartFormRequestWithObject:theImageObject
                                                                                            method:RKRequestMethodPOST
                                                                                              path:[NSString stringWithFormat:@"/images?auth_token='%@'",self.token]
                                                                                        parameters:nil
                                                                         constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
    {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(theImage, 0.7)
                                    name:@"image[image]"
                                fileName:@"photo.jpeg"
                                mimeType:@"image/jpeg"];
    }];
    
    RKObjectRequestOperation *operation = [[RKObjectManager sharedManager] objectRequestOperationWithRequest:request
                                                                                                     success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
    {
        if ([result count]>0)
        {
            FluxScanImageObject *imageObject = [result firstObject];
            [imageObject setLocalID:[imageObject generateUniqueStringID]];

            if ([delegate respondsToSelector:@selector(NetworkServices:didUploadImage:andRequestID:)])
            {
                [delegate NetworkServices:self didUploadImage:imageObject andRequestID:requestID];
            }
        }
    }
                                           
    failure:^(RKObjectRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
        {
            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
        }    }];
    [[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation]; // NOTE: Must be enqueued rather than started
    
    // monitor upload progress
    if ([delegate respondsToSelector:@selector(NetworkServices:uploadProgress:ofExpectedPacketSize:andRequestID:)])
    {
        [operation.HTTPRequestOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {            
            if (totalBytesExpectedToWrite > 0 && totalBytesExpectedToWrite < NSUIntegerMax) {
                [delegate NetworkServices:self uploadProgress:(long long)bytesWritten
                     ofExpectedPacketSize:(long long)totalBytesExpectedToWrite andRequestID:requestID];
            }
        }];
    }
}

#pragma mark  - Users

- (void)createUser:(FluxUserObject*)userObject withImage:(UIImage *)theImage andRequestID:(NSUUID *)requestID
{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    // Serialize the Article attributes then attach a file
    NSMutableURLRequest *request = [[RKObjectManager sharedManager] multipartFormRequestWithObject:userObject
                                                                                            method:RKRequestMethodPOST
                                                                                              path:[NSString stringWithFormat:@"/users?auth_token='%@'",self.token]
                                                                                        parameters:nil
                                                                         constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
                                    {
                                        [formData appendPartWithFileData:UIImageJPEGRepresentation(theImage, 0.7)
                                                                    name:@"image[image]"
                                                                fileName:@"photo.jpeg"
                                                                mimeType:@"image/jpeg"];
                                    }];
    
    RKObjectRequestOperation *operation = [[RKObjectManager sharedManager] objectRequestOperationWithRequest:request
                                                                                                     success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
                                           {
                                               if ([result count]>0)
                                               {
                                                   FluxUserObject *userObject = [result firstObject];
                                                   NSLog(@"Successfuly Created user %i with details: %@: %@",userObject.userID,userObject.name,userObject.username);
                                                   if ([delegate respondsToSelector:@selector(NetworkServices:didCreateUser:andRequestID:)])
                                                   {
                                                       [delegate NetworkServices:self didCreateUser:userObject andRequestID:requestID];
                                                   }
                                               }
                                           }
                                                                                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
                                           {
                                               NSLog(@"Failed with error: %@", [error localizedDescription]);
                                               if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
                                               {
                                                   [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
                                               }
                                           }];
  
    [[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation]; // NOTE: Must be enqueued rather than started
  
    // monitor upload progress
    if ([delegate respondsToSelector:@selector(NetworkServices:uploadProgress:ofExpectedPacketSize:andRequestID:)])
    {
        [operation.HTTPRequestOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            if (totalBytesExpectedToWrite > 0 && totalBytesExpectedToWrite < NSUIntegerMax) {
                [delegate NetworkServices:self uploadProgress:(long long)totalBytesWritten
                     ofExpectedPacketSize:(long long)totalBytesExpectedToWrite andRequestID:requestID];
            }
        }];
    }
}

-(void)loginUser:(FluxUserObject *)userObject withRequestID:(NSUUID *)requestID{
    [[RKObjectManager sharedManager] postObject:userObject path:@"/users/sign_in" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         if ([result count]>0)
         {
             FluxUserObject*userObj = [result firstObject];
             NSLog(@"Successfuly logged in with userID %i and token %@",userObj.userID,userObj.auth_token);
             if ([delegate respondsToSelector:@selector(NetworkServices:didLoginUser:andRequestID:)])
             {
                 [delegate NetworkServices:self didLoginUser:userObj andRequestID:requestID];
             }
         }
     }
        failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}

- (void)checkUsernameUniqueness:(NSString *)username withRequestID:(NSUUID *)requestID{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@users/suggestuniqueuname?username=%@",objectManager.baseURL,username]]];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                         
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
            NSString* suggestion = [(NSArray*)[JSON valueForKeyPath:@"suggested_name"]firstObject];
            BOOL unique = [(NSString*)[(NSArray*)[JSON valueForKeyPath:@"isunique"]firstObject] boolValue];
            
            
            if ([delegate respondsToSelector:@selector(NetworkServices:didCheckUsernameUniqueness:andSuggestion:andRequestID:)])
            {
               [delegate NetworkServices:self didCheckUsernameUniqueness:unique andSuggestion:suggestion andRequestID:requestID];
            }
        

    }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            NSLog(@"Request Failed with Error: %@, %@", error, error.userInfo);
            if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
            {
                [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
            }
    }];
    
    [operation start];
}

- (void)postCamera:(FluxCameraObject*)cameraObject withRequestID:(FluxRequestID *)requestID{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    [[RKObjectManager sharedManager] postObject:cameraObject path:[NSString stringWithFormat:@"/cameras?auth_token='%@'",self.token] parameters:nil
     success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         FluxCameraObject*cambject = [result firstObject];
         if ([delegate respondsToSelector:@selector(NetworkServices:didPostCameraWithID:andRequestID:)])
         {
             [delegate NetworkServices:self didPostCameraWithID:cambject.cameraID andRequestID:requestID];
         }
     }
        failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}

- (void)getUserForID:(int)userID withRequestID:(NSUUID *)requestID
{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:[NSString stringWithFormat:@"/users/profile/%i?auth_token='%@'",userID, _token]
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1]]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
    {
        NSLog(@"Found %i Results",[result count]);
        if ([result count]>0)
        {
            FluxUserObject*userObj = [result firstObject];
            if ([delegate respondsToSelector:@selector(NetworkServices:didReturnUser:andRequestID:)])
            {
                [delegate NetworkServices:self didReturnUser:userObj andRequestID:requestID];
            }
        }
    }
    failure:^(RKObjectRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
        {
            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
        }    }];
    [operation start];
}

- (void)getUserProfilePicForID:(int)userID withStringSize:(NSString *)sizeString withRequestID:(NSUUID *)requestID{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSString*url = [NSString stringWithFormat:@"%@users/%i/image?size=%@&auth_token='%@'",objectManager.baseURL,userID,sizeString,self.token];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request
                                                                              imageProcessingBlock:nil
       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
      {
          if ([delegate respondsToSelector:@selector(NetworkServices:didReturnProfileImage:forUserID:andRequestID:)])
          {
              [delegate NetworkServices:self didReturnProfileImage:image forUserID:userID andRequestID:requestID];
          }
      }
       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
      {
          NSLog(@"Failed with error: %@", [error localizedDescription]);
          if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
          {
              [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
          }
      }];
    [operation start];
}

- (void)getImagesListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userImagesGetMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/images/getimagelistforuser.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?userid=%i&auth_token='%@'",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],userID,self.token]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %i Results",[result count]);
         if ([result count]>0)
         {
             if ([delegate respondsToSelector:@selector(NetworkServices:didReturnImageListForUser:andRequestID:)])
             {
                 [delegate NetworkServices:self didReturnImageListForUser:result.array andRequestID:requestID];
             }
         }
     }
    failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}


#pragma mark  - Tags

- (void)getTagsForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius andMaxCount:(int)maxCount
              andRequestID:(FluxRequestID *)requestID
{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider tagGetMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/tags/localbycount.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&maxrows=%i&auth_token='%@'",
                                                                               objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                               location.latitude, location.longitude, radius, maxCount, self.token]]];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %i Tags",[result count]);
         
         if ([result count] > 0)
         {
             if ([delegate respondsToSelector:@selector(NetworkServices:didReturnTagList:andRequestID:)])
             {
                 [delegate NetworkServices:self didReturnTagList:result.array andRequestID:requestID];
             }
         }
     }
    failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}

- (void)getTagsForLocationFiltered:(CLLocationCoordinate2D)location
                         andRadius:(float)radius
                         andMinAlt:(float)altMin
                         andMaxAlt:(float)altMax
                   andMinTimestamp:(NSDate *)timeMin
                   andMaxTimestamp:(NSDate *)timeMax
                       andHashTags:(NSString *)hashTags
                          andUsers:(NSString *)users
                     andCategories:(NSString *)cats
                       andMaxCount:(int)maxCount
                      andRequestID:(FluxRequestID *)requestID;
{
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider tagGetMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/tags/localbycountfiltered.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSString *timestampMin = [NSString stringWithFormat:@"'%@'", [dateFormatter stringFromDate:timeMin]];
    NSString *timestampMax = [NSString stringWithFormat:@"'%@'", [dateFormatter stringFromDate:timeMax]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&altmin=%f&altmax=%f&timemin=%@&timemax=%@&taglist='%@'&userlist='%@'&catlist='%@'&maxcount=%d&auth_token='%@'",
                                                                               objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                               location.latitude, location.longitude, radius,
                                                                               altMin, altMax,
                                                                               timestampMin, timestampMax,
                                                                               hashTags, users, cats, maxCount,self.token]]];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %i Tags",[result count]);
         
         if ([result count] > 0)
         {
             if ([delegate respondsToSelector:@selector(NetworkServices:didReturnTagList:andRequestID:)])
             {
                 [delegate NetworkServices:self didReturnTagList:result.array andRequestID:requestID];
             }
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}

#pragma mark - MapView

//returns an NSDictionary list of images for mapView filtered based on provided details
- (void)getMapImagesForLocationFiltered:(CLLocationCoordinate2D)location
                              andRadius:(float)radius
                              andMinAlt:(float)altMin
                              andMaxAlt:(float)altMax
                        andMinTimestamp:(NSDate *)timeMin
                        andMaxTimestamp:(NSDate *)timeMax
                            andHashTags:(NSString *)hashTags
                               andUsers:(NSString *)users
                          andCategories:(NSString *)cats
                            andMaxCount:(int)maxCount
                           andRequestID:(FluxRequestID *)requestID{
    
//    NSString*token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSString *timestampMin = [NSString stringWithFormat:@"'%@'", [dateFormatter stringFromDate:timeMin]];
    NSString *timestampMax = [NSString stringWithFormat:@"'%@'", [dateFormatter stringFromDate:timeMax]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider mapImageGetMapping] method:RKRequestMethodAny pathPattern:@"/images/filteredcontent.json" keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&altmin=%f&altmax=%f&timemin=%@&timemax=%@&taglist='%@'&userlist='%@'&catlist='%@'&maxcount=%d&auth_token='%@'",
                                                                               objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                               location.latitude, location.longitude, radius,
                                                                               altMin, altMax,
                                                                               timestampMin, timestampMax,
                                                                               hashTags, users, cats, maxCount,self.token]]];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %i Map Images",[result count]);         
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnMapList:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnMapList:result.array andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}


#pragma mark  - Other

- (void)deleteLocations
{
    //execute the server call to nuke the area.
    NSLog(@"nuking the current location");

    // Create the manager object
    FluxLocationServicesSingleton *locationManager = [FluxLocationServicesSingleton sharedManager];
    
    CLLocationCoordinate2D location = locationManager.location.coordinate;
    float radius = 100;      // nuke 100m radius
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:@"/images/nuke.json" keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],location.latitude, location.longitude, radius]]];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (!error) {
                                   NSLog(@"Everthing went great, bombs away!");
                               }
                               else{
                                   NSLog(@"Nuke error: %@",[error localizedDescription]);
                               }
                           }];
}

#pragma mark - Error Handling
-(NSString*)readableStringFromError:(NSError*)error{
    id localizedRecoverySuggestionDict = [error.userInfo objectForKey:@"NSLocalizedRecoverySuggestion"];
    if (localizedRecoverySuggestionDict)
    {
        if ([localizedRecoverySuggestionDict isKindOfClass:[NSDictionary class]])
        {
            NSString*string = [(NSDictionary *)localizedRecoverySuggestionDict objectForKey:@"error"];
            if (string) {
                return [string capitalizedString];
            }
            else{
                return @"An unknown error occured";
            }
        }
        else if ([localizedRecoverySuggestionDict isKindOfClass:[NSString class]])
        {
            NSString*string = (NSString *)localizedRecoverySuggestionDict;
            return [string capitalizedString];
        }
    }
    return @"An unknown error occured";
}

@end
