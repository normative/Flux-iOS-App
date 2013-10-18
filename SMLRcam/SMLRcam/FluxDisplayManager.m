//
//  FluxDisplayManager.m
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDisplayManager.h"

#import "FluxScanImageObject.h"

const int number_OpenGL_Textures = 5;

NSString* const FluxDisplayManagerDidUpdateDisplayList = @"FluxDisplayManagerDidUpdateDisplayList";
NSString* const FluxDisplayManagerDidUpdateOpenGLDisplayList = @"FluxDisplayManagerDidUpdateOpenGLDisplayList";
NSString* const FluxDisplayManagerDidUpdateImageTexture = @"FluxDisplayManagerDidUpdateImageTexture";

@implementation FluxDisplayManager

- (id)init{
    self = [super init];
    if (self)
    {
        self.locationManager = [FluxLocationServicesSingleton sharedManager];
        [self.locationManager startLocating];
        
        self.fluxDataManager = [[FluxDataManager alloc] init];
        
        self.fluxNearbyMetadata = [[NSMutableDictionary alloc]init];

        _nearbyListLock = [[NSLock alloc] init];
//        _renderListLock = [[NSLock alloc] init];
        
        dataFilter = [[FluxDataFilter alloc]init];
        
//        renderedTextures = [[NSMutableArray alloc]init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePlacemark:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateHeading:) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateLocation:) name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFilter:) name:@"FluxFilterViewDidChangeFilter" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAcquireNewPicture:) name:@"FluxScanViewDidAcquireNewPicture" object:nil];
        
        timeSliderRange = NSMakeRange(0,5);
        oldTimeBracket = MAXFLOAT;
    }
    
    return self;
}

#pragma mark - Notifications

#pragma mark Location

-(void)didUpdatePlacemark:(NSNotification *)notification
{
    
}

- (void)didUpdateHeading:(NSNotification *)notification{
    //    CLLocationDirection heading = locationManager.heading;
    //    if (locationManager.location != nil) {
    //        ;
    //    }
}

- (void)didUpdateLocation:(NSNotification *)notification{
    [self requestNearbyItems];
}

#pragma mark Filter

- (void)didChangeFilter:(NSNotification*)notification{
    dataFilter = [notification.userInfo objectForKey:@"filter"];
    [self requestNearbyItems];
}

- (void)timeBracketDidChange:(float)value{
    
    //splits the images into bracketss
    int numOfBrackets = ceilf(self.nearbyList.count/(float)number_OpenGL_Textures);
    
    //find out what bracket the slider value is in
    int bracket = value*numOfBrackets;
    if (bracket == numOfBrackets) {
        return;
    }
    
    //if the bracket is a new one
    if (bracket != oldTimeBracket) {
        int lowBucketIndex = (bracket*number_OpenGL_Textures);
        int length = 5;
        if (((bracket+1)*number_OpenGL_Textures) > self.nearbyList.count-1) {
            length = (self.nearbyList.count-lowBucketIndex-1);
        }
        
        //find out what images are within that bracket
        timeSliderRange = NSMakeRange(lowBucketIndex,length);
        
        //make sure the range is within the bounds of the images array **should** never happen
        if (timeSliderRange.length+timeSliderRange.location > self.nearbyList.count) {
            return;
        }
        oldTimeBracket = bracket;
        [self calculateTimeAdjustedImageList];
    }

}

- (void)calculateTimeAdjustedImageList{
    if (timeSliderRange.location +timeSliderRange.length >= self.nearbyList.count) {
        timeSliderRange = NSMakeRange(0,MIN(5, self.nearbyList.count));
    }
    NSArray *tmp = [self.nearbyList subarrayWithRange:timeSliderRange];
    NSArray* timeBracketArray = [[tmp reverseObjectEnumerator] allObjects];
    NSMutableDictionary*timeBracketNearbyMetadata = [[NSMutableDictionary alloc]init];
    for (int i = 0; i<timeBracketArray.count; i++) {
        [timeBracketNearbyMetadata setObject:[self.fluxNearbyMetadata objectForKey:[timeBracketArray objectAtIndex:i]] forKey:[timeBracketArray objectAtIndex:i]];
    }
    
    
    NSDictionary *userInfoDict = [[NSDictionary alloc]
                                  initWithObjectsAndKeys:timeBracketArray, @"nearbyList",timeBracketNearbyMetadata, @"fluxNearbyMetadata" , nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateOpenGLDisplayList
                                                        object:self userInfo:userInfoDict];
    
    // Request images for nearby items
    for (id localID in timeBracketArray)
    {
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setRequestedIDs:[NSArray arrayWithObject:localID]];
        dataRequest.ImageReady=^(FluxLocalID *localID, UIImage *image, FluxDataRequest *completedDataRequest){
            //update image texture
            NSDictionary *userInfoDict = [[NSDictionary alloc]
                                          initWithObjectsAndKeys:image, localID, nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateImageTexture
                                                                object:self userInfo:userInfoDict];
        };
//        [dataRequest setImageReady:^(FluxLocalID *localID, UIImage *image, FluxDataRequest *completedDataRequest){
//            //update image texture
//            NSDictionary *userInfoDict = [[NSDictionary alloc]
//                                          initWithObjectsAndKeys:image, localID, nil];
//            [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateImageTexture
//                                                                object:self userInfo:userInfoDict];
//        }];
        [self.fluxDataManager requestImagesByLocalID:dataRequest withSize:full_res];
    }
}

#pragma mark Image Capture

- (void)didAcquireNewPicture:(NSNotification *)notification
{
    FluxLocalID *localID = [[notification userInfo] objectForKey:@"FluxScanViewDidAcquireNewPictureLocalIDKey"];
    
    [_nearbyListLock lock];
    //        if ((localID != nil) && ([fluxNearbyMetadata objectForKey:localID] != nil) && ([fluxImageCache objectForKey:localID] != nil))
    // There is currently nothing here ensuring that it will still be in the cache.
    if (localID != nil)
    {
        // We have a new picture ready in the cache.
        // Add the ID to the current list of nearby items, and re-sort and re-prune the list
        [self.nearbyList insertObject:localID atIndex:0];
        [self calculateTimeAdjustedImageList];
    }
    [_nearbyListLock unlock];
}

#pragma mark - Global Image Request

- (void)requestNearbyItems{
    CLLocation *loc = self.locationManager.location;
    
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    
    dataRequest.maxReturnItems = 50;
    dataRequest.searchFilter = dataFilter;
    dataRequest.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    
    [dataRequest setNearbyListReady:^(NSArray *imageList){
        NSMutableArray *localOnlyObjects = [[NSMutableArray alloc] init];
        
        [_nearbyListLock lock];
        
#warning This is where we re-add local-only content that won't be returned in new requests yet
        // Iterate over the list and clear out anything that is not local-only
        for (id localID in self.nearbyList)
        {
            FluxScanImageObject *locationObject = [self.fluxNearbyMetadata objectForKey:localID];
            if (locationObject.imageID < 0)
            {
                [localOnlyObjects addObject:localID];
            }
        }
        
        NSMutableArray *previousNearbyKeys = [NSMutableArray arrayWithArray:[self.fluxNearbyMetadata allKeys]];
        [previousNearbyKeys removeObjectsInArray:localOnlyObjects];
        
        // Remove all objects except for local-only
        [self.fluxNearbyMetadata removeObjectsForKeys:previousNearbyKeys];
        
        self.nearbyList = [NSMutableArray arrayWithArray:localOnlyObjects];
        
        // Need to update all metadata objects even if they exist (in case they change in the future)
        // Note that this dictionary will be up to date, but metadata will need to be re-copied from this dictionary
        // when a desired image is loaded (happens after the texture is loaded)
        for (FluxScanImageObject *curImgObj in imageList)
        {
            [self.fluxNearbyMetadata setObject:curImgObj forKey:curImgObj.localID];
            if (![self.nearbyList containsObject:curImgObj.localID])
            {
                [self.nearbyList addObject:curImgObj.localID];
            }
        }
        [self calculateTimeAdjustedImageList];
        [_nearbyListLock unlock];
    }];
    [self.fluxDataManager requestImageListAtLocation:loc.coordinate withRadius:10.0 withDataRequest:dataRequest];
}

#pragma mark - OpenGL Texture & Metadata Manipulation

//-(void) populateImageData
//{
//    // Sort and cap the list of nearby images. Shows the most recent textures returned for a location.
//    //    self.nearbyList = [NSMutableArray arrayWithArray:[self.nearbyList sortedArrayUsingSelector:@selector(compare:)]];
//    NSUInteger rangeLen = ([self.nearbyList count] >= number_OpenGL_Textures ? number_OpenGL_Textures : [self.nearbyList count]);
//    self.nearbyList = [NSMutableArray arrayWithArray:[self.nearbyList subarrayWithRange:NSMakeRange(0, rangeLen)]];
//    
//    NSDictionary *userInfoDict = @{@"nearbyList" : self.nearbyList, @"fluxNearbyMetadata" : self.fluxNearbyMetadata};
//    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateOpenGLDisplayList
//                                                        object:self userInfo:userInfoDict];
//
//    // Request images for nearby items
//    for (id localID in self.nearbyList)
//    {
//        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
//        [dataRequest setRequestedIDs:[NSArray arrayWithObject:localID]];
//        [dataRequest setImageReady:^(FluxLocalID *localID, UIImage *image, FluxDataRequest *completedDataRequest){
//            //update image texture
//            NSDictionary *userInfoDict = @{localID : image};
//            [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateImageTexture
//                                                                object:self userInfo:userInfoDict];
//        }];
//        [self.fluxDataManager requestImagesByLocalID:dataRequest withSize:full_res];
//    }
//}





@end
