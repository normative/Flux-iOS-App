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
#import "FluxConnectionObject.h"
#import "FluxMappingProvider.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxAliasObject.h"
#import "UICKeyChainStore.h"
#import "FluxAppDelegate.h"

#define defaultTimout 7.0
#define defaultImageTimout 60.0

#define _AWSProductionServerURL  @"http://54.221.254.230/"
#define _AWSStagingServerURL     @"http://54.83.61.163/"
#define _AWSTestServerURL        @"http://54.221.222.71/"
#define _DSDLocalTestServerURL   @"http://192.168.2.12:3101/"

NSString* const AWSProductionServerURL = _AWSProductionServerURL;
NSString* const AWSStagingServerURL    = _AWSStagingServerURL;
NSString* const AWSTestServerURL       = _AWSTestServerURL;
NSString* const DSDLocalTestServerURL  = _DSDLocalTestServerURL;

NSString* const FluxServerURL = _AWSProductionServerURL;
//NSString* const FluxServerURL = _AWSStagingServerURL;
//NSString* const FluxServerURL = _AWSTestServerURL;
//NSString* const FluxServerURL = _DSDLocalTestServerURL;

static NSDateFormatter *__fluxNetworkServicesOutputDateFormatter = nil;

@implementation FluxNetworkServices

@synthesize delegate;

//- (NSString *)get_token
//{
//    if (_token == nil)
//    {
//        _token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
//        NSLog(@"Fetching token key from key chain store");
//        if (_token == nil)
//            _token = @"";
//    }
//    
//    return _token;
//}

- (id)init
{
    if (self = [super init])
    {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        BOOL isremote = true;   //[[defaults objectForKey:@"Server Location"]intValue];
//        if (isremote)
//        {
        objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:FluxServerURL]];
//        }
//        else
//        {
//            objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:testServerURL]];
//        }
        
        NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
        
        if (!__fluxNetworkServicesOutputDateFormatter)
        {
            __fluxNetworkServicesOutputDateFormatter = [[NSDateFormatter alloc] init];
            [__fluxNetworkServicesOutputDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
            __fluxNetworkServicesOutputDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
            
        }
        
        outstandingRequestLocalURLs = [[NSMutableDictionary alloc]init];
        uploadedImageObjects = [[NSMutableDictionary alloc]init];
        
        
        //setup descriptors for the user-related calls
        RKResponseDescriptor *userResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                                    method:RKRequestMethodAny
                                                                                               pathPattern:@"users"
                                                                                                   keyPath:nil
                                                                                               statusCodes:statusCodes];
        
        RKResponseDescriptor *registrationResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userRegistrationGETMapping]
                                                                                                    method:RKRequestMethodAny
                                                                                               pathPattern:@"users"
                                                                                                   keyPath:nil
                                                                                               statusCodes:statusCodes];
        
        RKResponseDescriptor *userLoginResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userRegistrationGETMapping]
                                                                                                    method:RKRequestMethodAny
                                                                                               pathPattern:@"users/sign_in"
                                                                                                   keyPath:nil
                                                                                               statusCodes:statusCodes];
        
        RKResponseDescriptor *cameraCreationResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider cameraGETMapping]
                                                                                                         method:RKRequestMethodAny
                                                                                                    pathPattern:@"cameras"
                                                                                                        keyPath:nil
                                                                                                    statusCodes:statusCodes];
        
        RKResponseDescriptor *connectionFollowResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider connectionGETMapping]
                                                                                                              method:RKRequestMethodAny
                                                                                                         pathPattern:@"connections/follow"
                                                                                                             keyPath:nil
                                                                                                         statusCodes:statusCodes];
        
//        RKResponseDescriptor *connectionFriendResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider connectionGETMapping]
//                                                                                                          method:RKRequestMethodAny
//                                                                                                     pathPattern:@"connections/addfriend"
//                                                                                                         keyPath:nil
//                                                                                                     statusCodes:statusCodes];
        RKResponseDescriptor *connectionAcceptFriendResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider connectionGETMapping]
                                                                                                                method:RKRequestMethodAny
                                                                                                           pathPattern:@"connections/respondtofollowrequest"
                                                                                                               keyPath:nil
                                                                                                           statusCodes:statusCodes];
        
        RKResponseDescriptor *aliasCreateResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider aliasGETMapping]
                                                                                                                      method:RKRequestMethodAny
                                                                                                                 pathPattern:@"aliases"
                                                                                                                     keyPath:nil
                                                                                                                 statusCodes:statusCodes];

        RKResponseDescriptor *contactListResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider contactGETMapping]
                                                                                                           method:RKRequestMethodAny
                                                                                                      pathPattern:@"aliases/importcontacts"
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
        
        
        RKRequestDescriptor *userUpdateDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider userPATCHMapping]
                                                                                           objectClass:[FluxUserObject class]
                                                                                           rootKeyPath:@"user"
                                                                                                method:RKRequestMethodPATCH];
        
        RKRequestDescriptor *connectionRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider connectionPOSTMapping]
                                                                                          objectClass:[FluxConnectionObject class]
                                                                                          rootKeyPath:@"connection"
                                                                                               method:RKRequestMethodPOST];
        
        RKRequestDescriptor *connectionDeleteRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider connectionPOSTMapping]
                                                                                                 objectClass:[FluxConnectionObject class]
                                                                                                 rootKeyPath:@"connection"
                                                                                                      method:RKRequestMethodPUT];
        
        RKRequestDescriptor *aliasCreateRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[FluxMappingProvider aliasPOSTMapping]
                                                                                                       objectClass:[FluxAliasObject class]
                                                                                                       rootKeyPath:@"alias"
                                                                                                            method:RKRequestMethodPOST];
        
        [objectManager addRequestDescriptor:userRequestDescriptor];
        [objectManager addRequestDescriptor:userUpdateDescriptor];
        [objectManager addRequestDescriptor:cameraRequestDescriptor];
        [objectManager addRequestDescriptor:connectionRequestDescriptor];
        [objectManager addRequestDescriptor:connectionDeleteRequestDescriptor];
        [objectManager addRequestDescriptor:aliasCreateRequestDescriptor];
        
        [objectManager addResponseDescriptor:userResponseDescriptor];
        [objectManager addResponseDescriptor:registrationResponseDescriptor];
        [objectManager addResponseDescriptor:userLoginResponseDescriptor];
        [objectManager addResponseDescriptor:cameraCreationResponseDescriptor];
        [objectManager addResponseDescriptor:connectionFollowResponseDescriptor];
//        [objectManager addResponseDescriptor:connectionFriendResponseDescriptor];
        [objectManager addResponseDescriptor:connectionAcceptFriendResponseDescriptor];
        [objectManager addResponseDescriptor:aliasCreateResponseDescriptor];
        [objectManager addResponseDescriptor:contactListResponseDescriptor];
        
        
        
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
        
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"];
//        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        
        [[RKValueTransformer defaultValueTransformer] addValueTransformer:__fluxNetworkServicesOutputDateFormatter];

        
        //general init
        
        //set username and password
        //[objectManager.HTTPClient setAuthorizationHeaderWithUsername:@"username" password:@"password"];
        
        //show network activity indicator
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        
        //add boolean value transformer (restkit bug fix)
//        [[RKValueTransformer defaultValueTransformer] insertValueTransformer:[RKCustomBOOLTransformer defaultTransformer] atIndex:0];
        
        
        
        //show alert if there is no network connectivity
        [objectManager.HTTPClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if (status == AFNetworkReachabilityStatusNotReachable) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh Oh..."
                                                                message:@"It looks like you've lost your connection to the internet. You must be connected to the internet to use Flux."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }];
    }
    return self;
}

#pragma mark - Images

//returns the raw image given an image ID
- (void)getImageForID:(int)imageID withStringSize:(NSString *)sizeString andRequestID:(FluxRequestID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    NSString*url = [NSString stringWithFormat:@"%@images/%i/renderimage?auth_token=%@&size=%@",objectManager.baseURL,imageID,token,sizeString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
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
        NSLog(@"image for ID Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailImageDownloadWithError:andNaturalString:andRequestID:andImageID:)])
        {
            [delegate NetworkServices:self didFailImageDownloadWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID andImageID:imageID];
        }
    }];
    [operation start];
}

- (void)getImageMetadataForID:(int)imageID andRequestID:(FluxRequestID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:[NSString stringWithFormat:@"/images/%i.json?auth_token=%@", imageID, token]
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1]]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
    {
        NSLog(@"%s: Found %lu Results",__func__, (unsigned long)[result count]);
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
        NSLog(@"image metadata for ID Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
        {
            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
        }    }];
    [operation start];
}

- (void)getImagesForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius andRequestID:(FluxRequestID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/images/closest.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:
                                                          [NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&auth_token=%@",
                                                                                    objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                                    location.latitude, location.longitude, radius, token]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
    [self doRequest:request withResponseDesc:responseDescriptor andRequestID:requestID];
}


- (void)getImagesForLocationFiltered:(CLLocationCoordinate2D)location
                           andRadius:(float)radius
                           andMinAlt:(float)altMin
                           andMaxAlt:(float)altMax
                      andMaxReturned:(int)maxCount
                           andFilter:(FluxDataFilter*)dataFilter
                        andRequestID:(FluxRequestID *)requestID;

{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
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
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
//    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSString *timestampMin = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMin]];
    NSString *timestampMax = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMax]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider imageGETMapping] method:RKRequestMethodAny pathPattern:@"/images/filtered.json" keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&altmin=%f&altmax=%f&timemin=%@&timemax=%@&taglist='%@';&userlist='%@'&maxcount=%d&mypics=%i&followingpics=%i&auth_token=%@",
                                                                               objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                               location.latitude, location.longitude, radius,
                                                                               altMin, altMax,
                                                                               timestampMin, timestampMax,
                                                                               dataFilter.hashTags, dataFilter.users, maxCount,[[NSNumber numberWithBool:dataFilter.isActiveUserFiltered]intValue], [[NSNumber numberWithBool:dataFilter.isFollowingFiltered]intValue], token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];

    [self doRequest:request withResponseDesc:responseDescriptor andRequestID:requestID];
    
}

    
    
- (void)doRequest:(NSURLRequest *)request withResponseDesc:(RKResponseDescriptor *)responseDescriptor andRequestID:(FluxRequestID *)requestID
{
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
    {
        NSLog(@"%s: Found %lu Standard Images",__func__,(unsigned long)[result count]);
        
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
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
        NSLog(@"images for Location Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
        {
            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
        }    }];
    [operation start];
}

- (void)deleteImageWithID:(int)imageID andRequestID:(NSUUID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:objectManager.baseURL];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"DELETE"
                                                            path:[NSString stringWithFormat:@"%@images/%i?auth_token=%@",objectManager.baseURL,imageID, token]
                                                      parameters:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // No success for DELETE
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([operation.response statusCode] == 404) {
            if ([delegate respondsToSelector:@selector(NetworkServices:didDeleteImageWithID:andRequestID:)])
            {
                [delegate NetworkServices:self didDeleteImageWithID:imageID andRequestID:requestID];
            }
        }
        else{
            if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
            {
                [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
            }
        }
    }];
    [operation start];
}

- (void)updateImagePrivacyForImages:(NSArray *)images andPrvacy:(BOOL)newPrivacy andRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:objectManager.baseURL];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT"
                                                            path:[NSString stringWithFormat:@"%@images/setprivacy?privacy=%i&image_ids=%@&auth_token=%@",objectManager.baseURL,(newPrivacy ? 1 : 0), [images componentsJoinedByString:@","], token]
                                                      parameters:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([delegate respondsToSelector:@selector(NetworkServices:didUpdateImagePrivacysWithRequestID:)])
        {
            [delegate NetworkServices:self didUpdateImagePrivacysWithRequestID:requestID];
        }
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         NSLog(@"Privacy update failed with error: %@", [error localizedDescription]);
                                         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
                                         {
                                             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
                                         }
                                     }];
    [operation start];
    
}

#pragma mark Upload New Image

- (void)uploadImage:(FluxScanImageObject*)theImageObject andImage:(UIImage *)theImage andRequestID:(FluxRequestID *)requestID andHistoricalImage:(UIImage *)theHistoricalImg;
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];

    NSLog(@"Uploading image with positional accuracy: %f, %f", theImageObject.horiz_accuracy, theImageObject.vert_accuracy);
    
    
    // Build the request body
    NSString *boundary = @"thisIsBoundary";

    NSData*imageData = [self getDataForImage:theImage];
    //builds the entire body (imageData + the rest)
    NSMutableData *body = [self buildDataBodyForObject:theImageObject andImageData:imageData andBoudary:boundary];
    
    //creates a file path to save the data packet
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*folderDirectory = [NSString stringWithFormat:@"%@%@",[paths objectAtIndex:0],@"/imageUploadCache"];
    
    //ensures the correct folder exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderDirectory]) {
        // Directory does not exist so create it
        [[NSFileManager defaultManager] createDirectoryAtPath:folderDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //add filename to the path
    NSString *srcImagePath = [NSString stringWithFormat:@"%@/%@", folderDirectory, [NSString stringWithFormat:@"Photo-%@",requestID.UUIDString]];
    NSString *dataSrcImagePath = [srcImagePath stringByAppendingString:@".tmp"];
    
    //sace data to local folder
    if (!([body writeToFile:dataSrcImagePath atomically:YES])) {
        NSLog(@"Failed to save uploaded file");
    }

    
    // sets the URL and request type. Cannot add the body as uploadTaskWithRequest ignores the body
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images.json?auth_token=%@",objectManager.baseURL, token]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";

    //use the backgroundSession signle instance (per WWDC session), and upload the file generated and saved above
    NSString*fileURL = [NSString stringWithFormat:@"file://%@", dataSrcImagePath];
    NSURLSessionUploadTask*uploadTask = [[self backgroundSession] uploadTaskWithRequest:request fromFile:[NSURL URLWithString:fileURL]];

    //set the request ID in the task itself.
    [uploadTask setTaskDescription:requestID.UUIDString];
    
    //hold on ot the searchPAth locally so we can delete it later
    [outstandingRequestLocalURLs setObject:dataSrcImagePath forKey:[NSString stringWithFormat:@"%lu",(unsigned long)uploadTask.taskIdentifier]];
    [uploadedImageObjects setObject:theImageObject forKey:[NSString stringWithFormat:@"%lu",(unsigned long)uploadTask.taskIdentifier]];

    //actually send it
    [uploadTask resume];
    
    
//    [request setHTTPBody:body];
//    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    
//    //        sessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
//    sessionConfiguration.HTTPAdditionalHeaders = @{
//                                                   @"Accept"        : @"application/json",
//                                                   @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", @"thisIsBoundary"]
//                                                   };
//    
//    // Initialize Session
//    NSURLSession  *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
//    NSURLSessionDataTask*dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData*data, NSURLResponse*response, NSError*error){
//        NSLog(@"got something backl");
//        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
//        int responseStatusCode = (int)[httpResponse statusCode];
//        NSLog(@"got something backl");
//    }];
//    [dataTask resume];
}

- (NSData*)getDataForImage:(UIImage*)img{
    NSData *imageData = UIImageJPEGRepresentation(img, 0.7);
    return imageData;
}

//big nasty method for building our own request body instead of relying on restKit to do it for us.
- (NSMutableData*)buildDataBodyForObject:(FluxScanImageObject*)imgObject andImageData:(NSData*)imageData andBoudary:(NSString*)boundary{
    
    NSMutableData *body = [NSMutableData data];
    if (imageData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"photo.jpeg\"\r\n", @"image[image]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[altitude]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.altitude] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[camera_id]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%i\r\n", imgObject.cameraID] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[category_id]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%i\r\n", imgObject.categoryID] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[description]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", imgObject.descriptionString] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[heading]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.heading] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[id]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%i\r\n", imgObject.imageID] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[latitude]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.latitude] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[longitude]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.longitude] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[pitch]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.pitch] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[privacy]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%i\r\n", imgObject.privacy] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[qw]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.qw] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[qx]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.qx] dataUsingEncoding:NSUTF8StringEncoding]];

        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[qy]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.qy] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[qz]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.qz] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[roll]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.roll] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[time_stamp]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", imgObject.timestampString] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[user_id]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%i\r\n", imgObject.userID] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[vert_accuracy]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.vert_accuracy] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"image[yaw]"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%f\r\n", imgObject.yaw] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return body;
}

#pragma mark URLSession Delegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    NSString*requestIDString = task.taskDescription;
    FluxRequestID*requestID = [[NSUUID alloc]initWithUUIDString:requestIDString];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([delegate respondsToSelector:@selector(NetworkServices:uploadProgress:ofExpectedPacketSize:andRequestID:)])
        {
            [delegate NetworkServices:self uploadProgress:(long long)totalBytesSent ofExpectedPacketSize:(long long)totalBytesExpectedToSend andRequestID:requestID];
        }
    });
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    NSError *e = nil;
    
    
    NSDictionary * jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableLeaves error: &e];
    
    if (!jsonArray) {
        NSLog(@"Error parsing JSON: %@", e);
    } else {
        FluxScanImageObject*uploadedImg = (FluxScanImageObject*)[uploadedImageObjects objectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)dataTask.taskIdentifier]];
        [uploadedImg setImageID:[(NSString*)[jsonArray objectForKey:@"id"]intValue]];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSURLResponse*response = task.response;
    NSString*hello = task.taskDescription;
    FluxRequestID*requestID = [[NSUUID alloc]initWithUUIDString:hello];
        if (!error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = (int)[httpResponse statusCode];
            //if the status code is in the 200s
            if ([RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) containsIndex:responseStatusCode]) {
                //delete the local file
                NSString*pathToFile = [outstandingRequestLocalURLs objectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)task.taskIdentifier]];
                [[NSFileManager defaultManager] removeItemAtPath: pathToFile error: &error];
                if (error) {
                    NSLog(@"Uploaded file failed to delete");
                }
                else{
                    [outstandingRequestLocalURLs removeObjectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)task.taskIdentifier]];
                }
                
                FluxScanImageObject*imageObject = (FluxScanImageObject*)[uploadedImageObjects objectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)task.taskIdentifier]];
                [imageObject setLocalID:[imageObject generateUniqueStringID]];
                
                //I did this in case a random bug occured where this method was called before any progress was made. Random. Could ususally clear it by doing a clean build.
                if (imageObject) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([delegate respondsToSelector:@selector(NetworkServices:didUploadImage:andRequestID:)])
                        {
                            [delegate NetworkServices:self didUploadImage:imageObject andRequestID:requestID];
                        }
                        [uploadedImageObjects removeObjectForKey:[NSString stringWithFormat:@"%lu",(unsigned long)task.taskIdentifier]];
                    });
                }
                else{
                    NSLog(@"Image upload failed with response code: %i, nothing was uploaded from the looks of it.", responseStatusCode);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
                        {
                            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
                        }
                    });
                }
                



            }
            else{
                NSLog(@"Image upload failed with response code: %i", responseStatusCode);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
                    {
                        [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
                    }
                });

            }
        }
        else{
            NSLog(@"Image upload failed with error: %@", [error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
                {
                    [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
                }
            });
        }
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
    
    FluxAppDelegate *appDelegate = (FluxAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
    NSLog(@"All tasks are finished");
    
}

- (NSURLSession *)backgroundSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Session Configuration
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"uniqueSessionID"];
        
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
        sessionConfiguration.HTTPAdditionalHeaders = @{
                                                       @"Accept"        : @"application/json",
                                                       @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", @"thisIsBoundary"]
                                                       };
        [sessionConfiguration setTimeoutIntervalForResource:defaultImageTimout];
        
        // Initialize Session
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    });
    
    return session;
}

#pragma mark Features

//returns the cloud-extracted features given an image ID
- (void)getImageFeaturesForID:(int)imageID andRequestID:(FluxRequestID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    NSString*url = [NSString stringWithFormat:@"%@images/%i/image?auth_token=%@&size=%@",objectManager.baseURL,imageID,token, fluxImageTypeStrings[features]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
        {
            if ([delegate respondsToSelector:@selector(NetworkServices:didreturnImageFeatures:forImageID:andRequestID:)])
            {
                [delegate NetworkServices:self didreturnImageFeatures:operation.responseData forImageID:imageID andRequestID:requestID];
            }
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
            NSLog(@"image features for ID Failed with error: %@", [error localizedDescription]);
            if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
            {
                [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
            }
        }
     ];

    [operation start];
}

#pragma mark  - Users

#pragma mark Registraion / Logout

- (void)createUser:(FluxRegistrationUserObject*)userObject withImage:(UIImage *)theImage andRequestID:(NSUUID *)requestID
{
    
    // Serialize the Article attributes then attach a file
    NSMutableURLRequest *request = [[RKObjectManager sharedManager] multipartFormRequestWithObject:userObject
                                                                                            method:RKRequestMethodPOST
                                                                                              path:[NSString stringWithFormat:@"/users"]
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
                                                   FluxRegistrationUserObject *newUserObject = [result firstObject];
                                                   if (userObject.twitter) {
                                                       [newUserObject setTwitter:userObject.twitter];
                                                   }
                                                   else if (userObject.facebook) {
                                                       [newUserObject setFacebook:userObject.facebook];
                                                   }
                                                   else{
                                                       
                                                   }
                                                   [newUserObject setSocialName:userObject.socialName];
                                                   
                                                   NSLog(@"Successfuly Created user %i with details: %@: %@",newUserObject.userID,newUserObject.name,newUserObject.username);
                                                   if ([delegate respondsToSelector:@selector(NetworkServices:didCreateUser:andRequestID:)])
                                                   {
                                                       [delegate NetworkServices:self didCreateUser:newUserObject andRequestID:requestID];
                                                   }
                                               }
                                           }
                                                                                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
                                           {
                                               NSLog(@"create user Failed with error: %@", [error localizedDescription]);
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

- (void)updateUser:(FluxUserObject *)userObject withImage:(UIImage *)theImage andRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];

    NSLog(@"name: %@, user name: %@, email: %@, bio: %@", userObject.name, userObject.username, userObject.email, userObject.bio);
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:token, @"auth_token",
                                                [NSNumber numberWithInt:userObject.userID], @"id",
                                                                                            nil];

    // Serialize the Article attributes then attach a file
    NSMutableURLRequest *request = [[RKObjectManager sharedManager] multipartFormRequestWithObject:userObject
                                                                                            method:RKRequestMethodPATCH
//                                                                                              path:[NSString stringWithFormat:@"/users?auth_token=%@", token]
                                                                                              path:[NSString stringWithFormat:@"/users/%i", userObject.userID]
                                                                                        parameters:params
                                                                         constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
                                    {
                                        if (theImage) {
                                            [formData appendPartWithFileData:UIImageJPEGRepresentation(theImage, 0.7)
                                                                        name:@"user[avatar]"
                                                                    fileName:@"photo.jpeg"
                                                                    mimeType:@"image/jpeg"];
                                        }
                                    }];
    
    RKObjectRequestOperation *operation = [[RKObjectManager sharedManager] objectRequestOperationWithRequest:request
        success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
           {
//               if ([result count]>0)
               {
//                   FluxUserObject *userObject = [result firstObject];
                   NSLog(@"Successfuly updated user %i ",userObject.userID);
                   if ([delegate respondsToSelector:@selector(NetworkServices:didUpdateUser:andRequestID:)])
                   {
                       [delegate NetworkServices:self didUpdateUser:userObject andRequestID:requestID];
                   }
               }
           }
        failure:^(RKObjectRequestOperation *operation, NSError *error)
           {
               NSLog(@"update user Failed with error: %@", [error localizedDescription]);
               if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
               {
                   [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
               }
           }];
    
    [[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation]; // NOTE: Must be enqueued rather than started
}

-(void)loginUser:(FluxRegistrationUserObject *)userObject withRequestID:(NSUUID *)requestID{
    [[RKObjectManager sharedManager] postObject:userObject path:@"/users/sign_in" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         if ([result count]>0)
         {
             FluxRegistrationUserObject*userObj = [result firstObject];
             [userObject setAuth_token:userObj.auth_token];
             NSLog(@"Successfully logged in with userID %i and token %@",userObj.userID,userObj.auth_token);
             if ([delegate respondsToSelector:@selector(NetworkServices:didLoginUser:andRequestID:)])
             {
                 [delegate NetworkServices:self didLoginUser:userObject andRequestID:requestID];
             }
         }
     }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"login user Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}

-(void)logoutWithRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:objectManager.baseURL];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"DELETE"
                                                            path:[NSString stringWithFormat:@"%@users/sign_out?auth_token=%@",objectManager.baseURL, token]
                                                      parameters:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([delegate respondsToSelector:@selector(NetworkServices:didLogoutWithRequestID:)])
        {
            [delegate NetworkServices:self didLogoutWithRequestID:requestID];
        }
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         if ([operation.response statusCode] == 404) {
                                             if ([delegate respondsToSelector:@selector(NetworkServices:didLogoutWithRequestID:)])
                                             {
                                                 [delegate NetworkServices:self didLogoutWithRequestID:requestID];
                                             }
                                         }
                                         else{
                                             if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
                                             {
                                                 [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
                                             }
                                         }
                                     }];
    [operation start];
}

- (void)checkUsernameUniqueness:(NSString *)username withRequestID:(NSUUID *)requestID{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@users/suggestuniqueuname?username=%@",objectManager.baseURL,username]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
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
                                                                                            
                                                                                            NSLog(@"username uniqueness Failed with Error: %@, %@", error, error.userInfo);
                                                                                            if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
                                                                                            {
                                                                                                [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
                                                                                            }
                                                                                        }];
    
    [operation start];
}

- (void)postCamera:(FluxCameraObject*)cameraObject withRequestID:(FluxRequestID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    [[RKObjectManager sharedManager] postObject:cameraObject path:[NSString stringWithFormat:@"/cameras?auth_token=%@", token] parameters:nil
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
         
         NSLog(@"post camera Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}


-(void) updateAPNsDeviceTokenWithRequestID:(FluxRequestID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
//    NSLog(@"name: %@, user name: %@, email: %@, bio: %@", userObject.name, userObject.username, userObject.email, userObject.bio);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *apnstoken = [defaults objectForKey:@"currAPNSToken"];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:token, @"auth_token",
//                                   [NSNumber numberWithInt:0], @"id",
                                   apnstoken, @"apns_token",
                                   nil];
    
    // Serialize the Article attributes then attach a file
    NSMutableURLRequest *request = [[RKObjectManager sharedManager] multipartFormRequestWithObject:nil
                                                                                            method:RKRequestMethodPUT
                                                                                              path:[NSString stringWithFormat:@"/users/updateapnstoken"]
                                                                                        parameters:params
                                                                         constructingBodyWithBlock:^(id<AFMultipartFormData> formData){}
                                    ];
    
    RKObjectRequestOperation *operation = [[RKObjectManager sharedManager] objectRequestOperationWithRequest:request
                                                                                                     success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
                                           {
                                               //               if ([result count]>0)
                                               {
                                                   //                   FluxUserObject *userObject = [result firstObject];
                                                   NSLog(@"Successfuly updated device token for user");
                                                   if ([delegate respondsToSelector:@selector(NetworkServices:didUpdateUser:andRequestID:)])
                                                   {
                                                       [delegate NetworkServices:self didUpdateUser:nil andRequestID:requestID];
                                                   }
                                               }
                                           }
                                                                                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
                                           {
                                               NSLog(@"update apn device token Failed with error: %@", [error localizedDescription]);
                                               if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
                                               {
                                                   [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
                                               }
                                           }];
    
    [[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation]; // NOTE: Must be enqueued rather than started
    
}



#pragma mark User Profiles

- (void)getUserForID:(int)userID withRequestID:(NSUUID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:[NSString stringWithFormat:@"/users/%i/profile.json",userID]
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?auth_token=%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1], token]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
    {
        NSLog(@"Found %lu Results",(unsigned long)[result count]);
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
        NSLog(@"get user for ID Failed with error: %@", [error localizedDescription]);
        if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
        {
            [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
        }
    }];
    [operation start];
}

- (void)getUserProfilePicForID:(int)userID withStringSize:(NSString *)sizeString withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSString*url = [NSString stringWithFormat:@"%@users/%i/avatar?size=%@&auth_token=%@",objectManager.baseURL,userID,sizeString, token];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
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
          NSLog(@"user profile pic Failed with error: %@", [error localizedDescription]);
          if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
          {
              [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
          }
      }];
    [operation start];
}

- (void)getImagesListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userImagesGetMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/images/getimagelistforuser.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?userid=%i&auth_token=%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],userID, token]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Results",(unsigned long)[result count]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnImageListForUser:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnImageListForUser:result.array andRequestID:requestID];
         }
     }
    failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"images list for user Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}

#pragma mark Social Stuff

- (void)getFollowerRequestsForUserWithRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/users/followerrequests.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?auth_token=%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1], token]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Results",(unsigned long)[result count]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnFollowingRequestsForUser:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnFollowingRequestsForUser:result.array andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"get flllower requests for user Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}


- (void)getFollowingListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/users/following.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?auth_token=%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1], token]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Results",(unsigned long)[result count]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnFollowingListForUser:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnFollowingListForUser:result.array andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"get following list Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}

- (void)getFollowerListForUserWithID:(int)userID withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/users/followers.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?auth_token=%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1], token]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Results",(unsigned long)[result count]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnFollowerListForUser:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnFollowerListForUser:result.array andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"get follower list Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}

- (void)getUsersListForQuery:(NSString*)query withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider userGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/users/lookupname.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?contact=%@&auth_token=%@",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],query, token]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Results",(unsigned long)[result count]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnUsersListForQuery:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnUsersListForQuery:result.array andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"get user list for query failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}


- (void)unfollowUserID:(int)userID withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    int activeUserID = [(NSString*)[UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService] intValue];
    
    FluxConnectionObject*connObj = [[FluxConnectionObject alloc]init];
    [connObj setUserID:activeUserID];
    [connObj setConnectionsUserID:userID];
    [connObj setConnetionType:FluxConnectionState_follow];
    
    [[RKObjectManager sharedManager] putObject:connObj path:[NSString stringWithFormat:@"/connections/disconnect?auth_token=%@", token] parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         FluxConnectionObject*conObject = [result firstObject];
         if ([delegate respondsToSelector:@selector(NetworkServices:didUnfollowUserWithID:andRequestID:)])
         {
             [delegate NetworkServices:self didUnfollowUserWithID:conObject.connectionsUserID andRequestID:requestID];
         }
     }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"unfollow user failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}

- (void)forceUnfollowUserID:(int)userID withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    int activeUserID = [(NSString*)[UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService] intValue];
    
    FluxConnectionObject*connObj = [[FluxConnectionObject alloc]init];
    [connObj setUserID:userID];
    [connObj setConnectionsUserID:activeUserID];
    [connObj setConnetionType:FluxConnectionState_follow];
    
    [[RKObjectManager sharedManager] putObject:connObj path:[NSString stringWithFormat:@"/connections/disconnect?auth_token=%@", token] parameters:nil
                                       success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         if ([delegate respondsToSelector:@selector(NetworkServices:didForceUnfollowUserWithID:andRequestID:)])
         {
             [delegate NetworkServices:self didForceUnfollowUserWithID:userID andRequestID:requestID];
         }
     }
                                       failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"force unfollow failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}


- (void)sendFollowRequestToUserWithID:(int)userID withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    int activeUserID = [(NSString*)[UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService] intValue];
    
    FluxConnectionObject*connObj = [[FluxConnectionObject alloc]init];
    [connObj setUserID:activeUserID];
    [connObj setConnectionsUserID:userID];
    
    
    [[RKObjectManager sharedManager] postObject:connObj path:[NSString stringWithFormat:@"/connections/follow?auth_token=%@", token] parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         FluxConnectionObject*conObject = [result firstObject];
         if ([delegate respondsToSelector:@selector(NetworkServices:didSendFollowingRequestToUserWithID:andRequestID:)])
         {
             [delegate NetworkServices:self didSendFollowingRequestToUserWithID:conObject.connectionsUserID andRequestID:requestID];
         }
     }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"send follow request failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}


- (void)acceptFollowingRequestFromUserWithID:(int)userID withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    int activeUserID = [(NSString*)[UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService] intValue];
    
    FluxConnectionObject*connObj = [[FluxConnectionObject alloc]init];
    [connObj setUserID:activeUserID];
    [connObj setConnectionsUserID:userID];
    [connObj setFollowingState:FluxFollowState_accept];
    [connObj setAmFollowing:YES];
    
    
    [[RKObjectManager sharedManager] putObject:connObj path:[NSString stringWithFormat:@"/connections/respondtofollowrequest?auth_token=%@", token] parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         FluxConnectionObject*conObject = [result firstObject];
         if ([delegate respondsToSelector:@selector(NetworkServices:didAcceptFollowingRequestFromUserWithID:andRequestID:)])
         {
             [delegate NetworkServices:self didAcceptFollowingRequestFromUserWithID:conObject.connectionsUserID andRequestID:requestID];
         }
     }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"accept Follow request Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}


- (void)ignoreFollowingRequestFromUserWithID:(int)userID withRequestID:(NSUUID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    int activeUserID = [(NSString*)[UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService] intValue];
    
    FluxConnectionObject*connObj = [[FluxConnectionObject alloc]init];
    [connObj setUserID:activeUserID];
    [connObj setConnectionsUserID:userID];
    [connObj setFollowingState:FluxFollowState_ignore];
    
    
    [[RKObjectManager sharedManager] putObject:connObj path:[NSString stringWithFormat:@"/connections/respondtofollowrequest?auth_token=%@", token] parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         FluxConnectionObject*conObject = [result firstObject];
         if ([delegate respondsToSelector:@selector(NetworkServices:didIgnoreFollowingRequestFromUserWithID:andRequestID:)])
         {
             [delegate NetworkServices:self didIgnoreFollowingRequestFromUserWithID:conObject.connectionsUserID andRequestID:requestID];
         }
     }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"ignoring follow request Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
}


#pragma mark Aliases

- (void) createAliasWithName:(NSString *)social_name andServiceID:(int)service_id andRequestID:(NSUUID *)requestID
{
    FluxAliasObject *aliasObject = [[FluxAliasObject alloc] initWithName: social_name andServiceID: service_id];
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:token, @"auth_token", nil];
    [[RKObjectManager sharedManager] postObject:aliasObject
                                           path:@"/aliases"
                                     parameters:params
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         FluxAliasObject *newAliasObject = [result firstObject];
         NSLog(@"Alias created successfully to %@ for service %d", newAliasObject.alias_name, newAliasObject.serviceID);
     }
     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         
         NSLog(@"create alias Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
   
}

- (void)requestContactsFromService:(int)serviceID withCredentials:(NSDictionary *)credentials withRequestID:(NSUUID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider contactGETMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/aliases/importcontacts"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSMutableString *fullurl = [NSMutableString stringWithFormat:@"%@%@?auth_token=%@&serviceid=%d", objectManager.baseURL, [responseDescriptor.pathPattern substringFromIndex:1], token, serviceID];
    
    switch (serviceID)
    {
        case 1: // contact list
            // treat credentials as a list of email addresses and add them in as one key
            break;
        case 2: // Twitter
        case 3: // Facebook
            for (id key in credentials)
            {
                [fullurl appendString:[NSString stringWithFormat:@"&%@=%@", (NSString *)key, (NSString *)[credentials objectForKey:key]]];
            }
            break;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fullurl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];

    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Contacts",(unsigned long)[result count]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnContactList:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnContactList:result.array andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"Contact request Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
    
}


#pragma mark  - Filters

- (void)getTagsForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius andMaxCount:(int)maxCount
              andRequestID:(FluxRequestID *)requestID
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider tagGetMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/tags/localbycount.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&maxrows=%i&auth_token=%@",
                                                                               objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                               location.latitude, location.longitude, radius, maxCount, token]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Tags",(unsigned long)[result count]);
         
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnTagList:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnTagList:result.array andRequestID:requestID];
         }
     }
    failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"tags for location failed with error: %@", [error localizedDescription]);
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
                    andMaxReturned:(int)maxCount
                         andFilter:(FluxDataFilter*)dataFilter
                      andRequestID:(FluxRequestID *)requestID;
{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider tagGetMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/tags/localbycountfiltered.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
//    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
  
    NSString *timestampMin = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMin]];
    NSString *timestampMax = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMax]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&altmin=%f&altmax=%f&timemin=%@&timemax=%@&taglist='%@'&userlist='%@'&maxcount=%d&mypics=%i&followingpics=%i&auth_token=%@",
                                                                               objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                               location.latitude, location.longitude, radius,
                                                                               altMin, altMax,
                                                                               timestampMin, timestampMax,
                                                                               dataFilter.hashTags, dataFilter.users, maxCount,[[NSNumber numberWithBool:dataFilter.isActiveUserFiltered]intValue], [[NSNumber numberWithBool:dataFilter.isFollowingFiltered]intValue], token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Tags",(unsigned long)[result count]);
         
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnTagList:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnTagList:result.array andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"Tags for location Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}

- (void)getImageCountsForLocationFiltered:(CLLocationCoordinate2D)location
                                andRadius:(float)radius
                                andMinAlt:(float)altMin
                                andMaxAlt:(float)altMax
                                andFilter:(FluxDataFilter*)dataFilter
                             andRequestID:(FluxRequestID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider filterImageCountsGetMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/images/filteredimgcounts.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
//    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSString *timestampMin = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMin]];
    NSString *timestampMax = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMax]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&altmin=%f&altmax=%f&timemin=%@&timemax=%@&taglist='%@'&userlist='%@'&mypics=%i&followingpics=%i&auth_token=%@",
                                                                                objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                                location.latitude, location.longitude, radius,
                                                                                altMin, altMax,
                                                                                timestampMin, timestampMax,
                                                                                dataFilter.hashTags, dataFilter.users,[[NSNumber numberWithBool:dataFilter.isActiveUserFiltered]intValue], [[NSNumber numberWithBool:dataFilter.isFollowingFiltered]intValue], token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         FluxFilterImageCountObject *countsObject = [result firstObject];
         
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnImageCounts:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnImageCounts:countsObject andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"image counts Failed with error: %@", [error localizedDescription]);
         if ([delegate respondsToSelector:@selector(NetworkServices:didFailWithError:andNaturalString:andRequestID:)])
         {
             [delegate NetworkServices:self didFailWithError:error andNaturalString:[self readableStringFromError:error] andRequestID:requestID];
         }
     }];
    [operation start];
}

- (void)getFilteredImageCountForLocation:(CLLocationCoordinate2D)location
                               andRadius:(float)radius
                               andMinAlt:(float)altMin
                               andMaxAlt:(float)altMax
                               andFilter:(FluxDataFilter*)dataFilter
                            andRequestID:(FluxRequestID *)requestID{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider filterImageCountsGetMapping]
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:@"/images/filteredimgcounts.json"
                                                                                           keyPath:nil
                                                                                       statusCodes:statusCodes];
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
//    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSString *timestampMin = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMin]];
    NSString *timestampMax = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMax]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&altmin=%f&altmax=%f&timemin=%@&timemax=%@&taglist='%@'&userlist='%@'&mypics=%i&followingpics=%i&auth_token=%@",
                                                                                objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                                location.latitude, location.longitude, radius,
                                                                                altMin, altMax,
                                                                                timestampMin, timestampMax,
                                                                                dataFilter.hashTags, dataFilter.users,[[NSNumber numberWithBool:dataFilter.isActiveUserFiltered]intValue], [[NSNumber numberWithBool:dataFilter.isFollowingFiltered]intValue], token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         FluxFilterImageCountObject *countsObject = [result firstObject];
         
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnTotalImageCount:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnTotalImageCount:countsObject.totalImageCount andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"image count Failed with error: %@", [error localizedDescription]);
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
                         andMaxReturned:(int)maxCount
                              andFilter:(FluxDataFilter*)dataFilter
                           andRequestID:(FluxRequestID *)requestID{
    
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
//    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

    NSString *timestampMin = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMin]];
    NSString *timestampMax = [NSString stringWithFormat:@"'%@'", [__fluxNetworkServicesOutputDateFormatter stringFromDate:dataFilter.timeMax]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[FluxMappingProvider mapImageGetMapping] method:RKRequestMethodAny pathPattern:@"/images/filteredcontent.json" keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f&altmin=%f&altmax=%f&timemin=%@&timemax=%@&taglist='%@'&userlist='%@'&maxcount=%d&mypics=%i&followingpics=%i&auth_token=%@",
                                                                               objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],
                                                                               location.latitude, location.longitude, radius,
                                                                               altMin, altMax,
                                                                               timestampMin, timestampMax,
                                                                               dataFilter.hashTags, dataFilter.users, maxCount,[[NSNumber numberWithBool:dataFilter.isActiveUserFiltered]intValue], [[NSNumber numberWithBool:dataFilter.isFollowingFiltered]intValue], token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];
    
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result)
     {
         NSLog(@"Found %lu Map Images",(unsigned long)[result count]);         
         if ([delegate respondsToSelector:@selector(NetworkServices:didReturnMapList:andRequestID:)])
         {
             [delegate NetworkServices:self didReturnMapList:result.array andRequestID:requestID];
         }
     }
                                     failure:^(RKObjectRequestOperation *operation, NSError *error)
     {
         NSLog(@"map images Failed with error: %@", [error localizedDescription]);
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
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?lat=%f&long=%f&radius=%f",objectManager.baseURL,[responseDescriptor.pathPattern substringFromIndex:1],location.latitude, location.longitude, radius]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:defaultTimout];

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
            
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString*error = [json objectForKey:@"error"];
            return [error lowercaseString];
        }
    }
    return @"An unknown error occured";
}

@end
