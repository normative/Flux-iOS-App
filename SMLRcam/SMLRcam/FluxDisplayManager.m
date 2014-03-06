//
//  FluxDisplayManager.m
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDisplayManager.h"
#import "FluxDebugViewController.h"
#import "FluxScanImageObject.h"
#import "FluxOpenGLViewController.h"
#import "FluxDeviceInfoSingleton.h"

const int number_OpenGL_Textures = 5;
const int maxDisplayListCount   = 10;

const int maxRequestCountQuart = 2;
const int maxRequestCountThumb = 5;
const int maxRequestCountFeatures = 2;

const double minMoveDistanceThreshold = 1.0;
const NSTimeInterval maxMoveTimeThreshold = 5.0;

const double maxIncidentThreshold = 45.0;

NSString* const FluxDisplayManagerDidUpdateDisplayList = @"FluxDisplayManagerDidUpdateDisplayList";
NSString* const FluxDisplayManagerDidUpdateNearbyList = @"FluxDisplayManagerDidUpdateNearbyList";
NSString* const FluxDisplayManagerDidUpdateImageTexture = @"FluxDisplayManagerDidUpdateImageTexture";
NSString* const FluxDisplayManagerDidUpdateMapPinList = @"FluxDisplayManagerDidUpdateMapPinList";
NSString* const FluxDisplayManagerDidFailToUpdateMapPinList = @"FluxDisplayManagerDidFailToUpdateMapPinList";
NSString* const FluxDisplayManagerDidMatchImage = @"FluxDisplayManagerDidMatchImage";
NSString* const FluxDisplayManagerDidUpdateImageFeatures = @"FluxDisplayManagerDidUpdateImageFeatures";
NSString* const FluxDisplayManagerMapPinListKey = @"FluxDisplayManagerMapPinListKey";

NSString* const FluxOpenGLShouldRender = @"FluxOpenGLShouldRender";

const double scanImageRequestRadius = 15.0;     // radius for scan image requesting


@implementation FluxDisplayManager

- (id)init
{
    self = [super init];
    if (self)
    {
        [self createNewLogFiles];
        
        _locationManager = [FluxLocationServicesSingleton sharedManager];

        lastMotionPose.position.x = 0.0;
        lastMotionPose.position.y = 0.0;
        lastMotionPose.position.z = 0.0;
        lastMotionTime = [NSDate date];
        
        [_locationManager WGS84_to_ECEF:&lastMotionPose];
        
        [self.locationManager startLocating];
        
        _fluxDataManager = [[FluxDataManager alloc] init];
        
        _fluxNearbyMetadata = [[NSMutableDictionary alloc]init];
        
        _nearbyListLock = [[NSRecursiveLock alloc] init];
        _nearbyScanList = [[NSMutableArray alloc]init];
        _nearbyCamList = [[NSMutableArray alloc]init];

        _displayListLock = [[NSRecursiveLock alloc] init];
        _displayScanList = [[NSMutableArray alloc]init];
        _displayCamList = [[NSMutableArray alloc]init];

        dataFilter = [[FluxDataFilter alloc]init];
        
        _isScrubAnimating = false;
        _isScanMode = true;
        
        _imageRequestCountThumb = 0;
        _imageRequestCountQuart = 0;

        _imageRequestCountLock = [[NSLock alloc]init];
        
        _openGLVC = nil;
        
        // Check if feature matching is supported
        if ([[FluxDeviceInfoSingleton sharedDeviceInfo] isFeatureMatching])
        {
            featureMatchingSupported = YES;
            
            _fluxFeatureMatchingQueue = [[FluxFeatureMatchingQueue alloc] init];
            
            [self setupFeatureMatching];
            
            _featureRequestCount = 0;
            _featureRequestCountLock = [[NSLock alloc] init];
        }
        else
        {
            featureMatchingSupported = NO;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePlacemark:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateHeading:) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateLocation:) name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
        
        // not using constants for this notification name because of conflicting header load ordering
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFilter:) name:@"FluxFilterViewDidChangeFilter" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStartCameraMode:) name:FluxImageCaptureDidPush object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStopCameraMode:) name:FluxImageCaptureDidPop object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCaptureNewImage:) name:FluxImageCaptureDidCaptureImage object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUndoCapture:) name:FluxImageCaptureDidUndoCapture object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupFeatureMatching) name:FluxDebugDidChangeMatchDebugImageOutput object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDataStoreRemoveImageObjectFromCache:) name:FluxDataStoreDidEvictImageObjectFromCache object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMatchImage:) name:FluxDisplayManagerDidMatchImage object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didResetKalmanFilter:) name:FluxLocationServicesSingletonDidResetKalmanFilter object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(featureMatchingKalmanFilterStateChange) name:FluxLocationServicesSingletonDidChangeKalmanFilterState object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FluxFilterViewDidChangeFilter" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxImageCaptureDidPush object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxImageCaptureDidPop object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxImageCaptureDidCaptureImage object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxImageCaptureDidUndoCapture object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDebugDidChangeMatchDebugImageOutput object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDataStoreDidEvictImageObjectFromCache object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDisplayManagerDidMatchImage object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidResetKalmanFilter object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidChangeKalmanFilterState object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    if (featureMatchingSupported)
    {
        [self.fluxFeatureMatchingQueue shutdownMatchQueue];
    }
}

#pragma mark - Notifications

- (void)didDataStoreRemoveImageObjectFromCache:(NSNotification *)notification
{
    NSNumber *imageTypeNSNumber = [notification.userInfo objectForKey:FluxDataStoreDidEvictImageObjectFromCacheKeyImageType];
    FluxImageType imageType = [imageTypeNSNumber unsignedIntegerValue];
    FluxLocalID *localID = [notification.userInfo objectForKey:FluxDataStoreDidEvictImageObjectFromCacheKeyLocalID];
    
    FluxImageRenderElement *ire = [self getRenderElementForKey:localID];
    ire.imageTypesFetched = ire.imageTypesFetched & ~(1 << imageType);
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    [self.fluxDataManager removeUnusedItemsFromImageCache];
}

#pragma mark Location

- (void)didUpdatePlacemark:(NSNotification *)notification
{
    
}

- (void)didUpdateHeading:(NSNotification *)notification
{
    // first normalize to (0 <= heading < 360.0)
//    currHeading = fmod((self.locationManager.heading + 360.0), 360.0);

//    NSString *logstr = [NSString stringWithFormat:@"DM.didUpdateHeading: New heading at gps.heading: %f, or.heading: %f, delta: %f", self.locationManager.heading, self.locationManager.orientationHeading, (self.locationManager.heading - self.locationManager.orientationHeading) ];
//    [self writeLog:logstr];

    [self calculateTimeAdjustedImageList];
}

- (void)didUpdateLocation:(NSNotification *)notification
{
    // TS: need to filter this a little better - limit to only every 5s or some distance from last request, ignore when in cam mode
    
    // setup local sensorPose object with new lat/long
    // calc ECEF
    // compare to last ECEF
    //  if > threshold then
    //      last ECEF = current ECEF,
    //      request nearby
    sensorPose newPose;
    double dist;
    
    newPose.position.x = self.locationManager.location.coordinate.latitude;
    newPose.position.y = self.locationManager.location.coordinate.longitude;
    newPose.position.z = self.locationManager.location.altitude;
    
    dist = [self haversineBetweenPosition1:newPose andPosition2:lastMotionPose];
    //[self testHaversine];
    
//    NSLog(@"New location: lat: %f, lon: %f, alt: %f, dist from last: %f", newPose.position.x, newPose.position.y, newPose.position.z, dist);
//    NSLog(@"New location: lat: %f, lon: %f, alt: %f", newPose.position.x, newPose.position.y, newPose.position.z);
    
    NSDate *now = [NSDate date];
    NSTimeInterval timeSinceLast = [now timeIntervalSinceDate:lastMotionTime];
    
    if ((fabs(dist) > minMoveDistanceThreshold) || (timeSinceLast > maxMoveTimeThreshold))
    {
        lastMotionPose = newPose;
        lastMotionTime = now;
//        NSString *logstr = [NSString stringWithFormat:@"New request at (%f, %f, %f), (distance=%f)", newPose.position.x, newPose.position.y, newPose.position.z, dist];
//        [self writeLog:logstr];
        [self requestNearbyItems];
        
    }
}

#pragma mark - Feature Matching

- (void)checkForFeatureMatchingTasksWithNearbyItems:(NSArray *)nearbyItems withDisplayItems:(NSArray *)displayItems
{
    bool currentKalmanStateValid = [self.locationManager isKalmanSolutionValid];

    if (currentKalmanStateValid)
    {
        // For all IRE's with features available, queue up feature-matching tasks
        FluxOpenGLViewController *fluxGLVC = (FluxOpenGLViewController *)self.openGLVC;
        
        // Grab a copy of all localID's in displayItems
        NSMutableArray *displayIDs = [[NSMutableArray alloc] init];
        for (FluxImageRenderElement *ire in displayItems)
        {
            [displayIDs addObject:ire.localID];
        }

        for (FluxImageRenderElement *ire in nearbyItems)
        {
            if (ire.imageMetadata.features != nil)
            {
                bool isDisplayed = [displayIDs containsObject:ire.localID];
                
                if (ire.imageMetadata.matchFailed &&
                    (([[NSDate date] compare:ire.imageMetadata.matchFailureRetryTime]) == NSOrderedDescending))
                {
                    // Case where previous match attempt has failed
                    // Reset failure state so it doesn't get queued up again until matching is complete or fails again
                    ire.imageMetadata.matchFailed = NO;
                    
                    FluxImageType rtype = none;
                    FluxCacheImageObject *imageCacheObj = [self.fluxDataManager fetchImagesByLocalID:ire.localID
                                                                                            withSize:highest_res returnSize:&rtype];

                    [self.fluxFeatureMatchingQueue addMatchRequest:ire withObjectImage:imageCacheObj withOpenGLVC:fluxGLVC
                                              isCurrentlyDisplayed:isDisplayed withDebugImageOutput:featureMatchingDebugImageOutput];
                }
                else if (!ire.imageMetadata.matched && (ire.imageMetadata.matchFailureRetryTime == nil))
                {
                    // Also queue up any items which have not been queueud (not matched, no failure retry time set).
                    FluxImageType rtype = none;
                    FluxCacheImageObject *imageCacheObj = [self.fluxDataManager fetchImagesByLocalID:ire.localID
                                                                                            withSize:highest_res returnSize:&rtype];
                    
                    [self.fluxFeatureMatchingQueue addMatchRequest:ire withObjectImage:imageCacheObj withOpenGLVC:fluxGLVC
                                              isCurrentlyDisplayed:isDisplayed withDebugImageOutput:featureMatchingDebugImageOutput];
                }
            }
        }
    }
    
    // Request features not yet available for matching.
    // This can happen whether or not the Kalman state is valid for matching.
    [self requestMissingFeaturesWithNearbyItems:nearbyItems withDisplayItems:displayItems];
}

- (void)requestMissingFeaturesWithNearbyItems:(NSArray *)nearbyItems withDisplayItems:(NSArray *)displayItems
{
    // This routine prioritizes features to download.
    // Note that displayList is a subset of nearbyList
    
    // First pass through display list (current time, desirable heading)
    for (FluxImageRenderElement *ire in displayItems)
    {
        if (!ire.imageMetadata.features &&
            !(ire.imageTypesFetched & FluxImageTypeMask_features) &&
            !ire.imageMetadata.featureFetchFailed &&
            (_featureRequestCount < maxRequestCountFeatures))
        {
            [self queueFeatureRequest:ire];
        }
    }
    
    if (_featureRequestCount >= maxRequestCountFeatures)
    {
        // Reached maximum download count. No sense continuing.
        return;
    }
    
    // Next check any that were not in displayList but are in nearbyList
    // Two-pass approach gives priority to feature sets that have not yet failed
    for (FluxImageRenderElement *ire in nearbyItems)
    {
        if (!ire.imageMetadata.features &&
            !(ire.imageTypesFetched & FluxImageTypeMask_features) &&
            !ire.imageMetadata.featureFetchFailed &&
            (_featureRequestCount < maxRequestCountFeatures))
        {
            [self queueFeatureRequest:ire];
        }
    }

    if (_featureRequestCount >= maxRequestCountFeatures)
    {
        // Reached maximum download count. No sense continuing.
        return;
    }

    // Second pass through gives failed requests another chance (if download slots still exist)
    for (FluxImageRenderElement *ire in nearbyItems)
    {
        if (!ire.imageMetadata.features &&
            !(ire.imageTypesFetched & FluxImageTypeMask_features) &&
            (_featureRequestCount < maxRequestCountFeatures))
        {
            // Reset failure status and retry
            ire.imageMetadata.featureFetchFailed = NO;
            [self queueFeatureRequest:ire];
        }
    }
}

- (void)queueFeatureRequest:(FluxImageRenderElement *)ire
{
    FluxDataRequest *featuresRequest = [[FluxDataRequest alloc] init];
    [featuresRequest setRequestedIDs:[NSMutableArray arrayWithObject:ire.localID]];
    featuresRequest.imageFeaturesReady=^(FluxLocalID *localID, NSData *features, FluxDataRequest *completedDataRequest){
        // assign features into SIO.features...
        ire.imageMetadata.features = features;
        
        [_featureRequestCountLock lock];
        _featureRequestCount--;
        [_featureRequestCountLock unlock];
    };
    featuresRequest.errorOccurred=^(NSError *error,NSString *errDescription, FluxDataRequest *failedDataRequest){
        ire.imageTypesFetched = ire.imageTypesFetched & ~(FluxImageTypeMask_features);
        ire.imageMetadata.featureFetchFailed = YES;
        
        [_featureRequestCountLock lock];
        _featureRequestCount--;
        [_featureRequestCountLock unlock];
    };
    
    [_featureRequestCountLock lock];
    _featureRequestCount++;
    [_featureRequestCountLock unlock];
    
    ire.imageTypesFetched = ire.imageTypesFetched | FluxImageTypeMask_features;
    [self.fluxDataManager requestImageFeaturesByLocalID:featuresRequest];
}

- (void)didMatchImage:(NSNotification *)notification
{
    [self calculateTimeAdjustedImageList];
}

- (void)setupFeatureMatching
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    featureMatchingDebugImageOutput = [[defaults objectForKey:FluxDebugMatchDebugImageOutputKey] boolValue];
}

# pragma mark - Kalman State Changes

- (void)didResetKalmanFilter:(NSNotification *)notification
{
    NSLog(@"Kalman Reset: All cached quantities being reset.");
    
    if (featureMatchingSupported)
    {
        // Delete all queued matching tasks
        [self.fluxFeatureMatchingQueue deleteMatchRequests];

        // Reset cached quantities
        [self.fluxDataManager resetAllFeatureMatches];
    }
    
    // Request a new list of nearby content based on the possibly different location
    [self requestNearbyItems];
}

// Adds valid FluxImageRenderElements to the match queue if enabled, or deletes existing tasks if disabled.
// Triggered by a Kalman state change.
- (void)featureMatchingKalmanFilterStateChange
{
    bool currentKalmanStateValid = [self.locationManager isKalmanSolutionValid];
    
    if (currentKalmanStateValid)
    {
        // This has the side-effect of queueing up jobs for feature matching, but we probably should be doing it anyways
        [self calculateTimeAdjustedImageList];
    }
    else if (featureMatchingSupported)
    {
        // Delete any feature matching jobs in the queue (probably not valid).
        [self.fluxFeatureMatchingQueue deleteMatchRequests];
    }
}

#pragma mark - Filter

- (void)didChangeFilter:(NSNotification*)notification
{
    dataFilter = [notification.userInfo objectForKey:@"filter"];
    [self requestNearbyItems];
}

#pragma mark - Time

// determine sub-set of time-sorted image entries to copy into display list
// value is % of displayListCount and reps the top of the list.  List is fixed size of X
- (void)timeBracketDidChange:(int)value
{
    
    // TODO: these notifications may come thick and fast (especially when using momentum) so we may want to limit them
    //          track the "latest" (order of call, not value) value in a "pending" variable
    //          only allow through when > min time has elapsed from last adjustment calc
    //              calc timeRangeMaxIndex based on pending variable
    //          need to call from "animation is done" notification as well to ensure we process the last value

    if (!_isScanMode)
        return;
    
//    _timeRangeMinIndex = ((self.nearbyList.count + 4) * value);
    if (value >= self.nearbyListCount)
    {
        value = self.nearbyListCount - 1;
    }

    if (value < 0)
    {
        value = 0;
    }

    _timeRangeMinIndex = value;
    
//    NSLog(@"timeRange: count: %d, value: %f, maxIndex: %d", [self.nearbyList count], value, _timeRangeMinIndex);
    [self calculateTimeAdjustedImageList];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxOpenGLShouldRender object:self userInfo:nil];
}

- (void)timeBracketWillBeginScrolling
{
//    NSLog(@"DisplayManager start scrolling");
//    _isScrubAnimating = true;
}

- (void)timeBracketDidEndScrolling
{
//    NSLog(@"DisplayManager end scrolling");
//    _isScrubAnimating = false;
//    [self calculateTimeAdjustedImageList];
}

-(void) updateImageMetadataForElement:(FluxImageRenderElement*)element
{
    GLKQuaternion quaternion;
    
    FluxScanImageObject *locationObject = element.imageMetadata;
    
    element.imagePose->position.x =  locationObject.latitude;
    element.imagePose->position.y =  locationObject.longitude;
    element.imagePose->position.z =  locationObject.altitude;
    
    if (locationObject.location_data_type == location_data_valid_ecef)
    {
        element.imagePose->validECEFEstimate =1;
        element.imagePose->ecef.x = locationObject.ecefX;
        element.imagePose->ecef.y = locationObject.ecefY;
        element.imagePose->ecef.z = locationObject.ecefZ;
    }
    else if (locationObject.location_data_type == location_data_from_homography)
    {
        // Use rotation and translation calculated from homography from feature matching
    }
    else
    {
        element.imagePose->validECEFEstimate = 0;
    }
    
    quaternion.x = locationObject.qx;
    quaternion.y = locationObject.qy;
    quaternion.z = locationObject.qz;
    quaternion.w = locationObject.qw;
    
    GLKMatrix4 quatMatrix =  GLKMatrix4MakeWithQuaternion(quaternion);
    GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    element.imagePose->rotationMatrix =  GLKMatrix4Multiply(matrixTP, quatMatrix);
}

- (void)calculateTimeAdjustedImageList
{
    static bool inCalcTimeAdjImageList = false;
    
    if (inCalcTimeAdjImageList)
        return;
    
    self.earliestDisplayDate = nil;
    self.latestDisplayDate = nil;

    [_displayListLock lock];
    {
        inCalcTimeAdjImageList = true;

        // Grab a copy of self.nearbyList (keeps the lock hold time to a minimum)
        [_nearbyListLock lock];
        {
            _nearbyPrunedList = [self.nearbyUnPrunedList mutableCopy];
        }

        // calculate up-to-date metadata elements (tangent-plane, relative heading) for all images in nearbyList
        // this will use a copy of the "current" value for the user pose so as to not interfere with the GL rendering loop.
        // The only time this may cause an issue is during periods of large orientation change (fast pivot by user) at which point the user will be
        // hard pressed to see the issues simply because of motion blur.
        
        // spin through nearbylist to update metadata and nearbylist...
        if (self.openGLVC != nil)
        {
            [(FluxOpenGLViewController *)self.openGLVC updateImageMetadataForElementList:_nearbyPrunedList andMaxIncidentThreshold:maxIncidentThreshold];
        }

        // generate the displayList...
        
        // clear the displayList
        [self.displayList removeAllObjects];
        
        // extract X images from nearbyList where timestamp <= time from slider (timeRangeMaxIndex)
        int idx = 0;
        for (idx = 0; ((self.displayList.count < maxDisplayListCount) && ((idx + _timeRangeMinIndex) < _nearbyPrunedList.count)); idx++)
        {
            FluxImageRenderElement *ire = [_nearbyPrunedList objectAtIndex:(_timeRangeMinIndex + idx)];
            
            // Ensure we have requested/already have a thumb image
            if (_isScanMode && !(ire.imageTypesFetched & FluxImageTypeMask_thumb) && !(ire.imageMetadata.justCaptured))
            {
                ire.imageTypesFetched = ire.imageTypesFetched | FluxImageTypeMask_thumb;
                
                FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
                [dataRequest setRequestedIDs:[NSMutableArray arrayWithObject:ire.localID]];
                dataRequest.imageReady=^(FluxLocalID *localID, FluxCacheImageObject *imageCacheObj, FluxDataRequest *completedDataRequest){
                    // Once we have the image, set the imageRenderType so it can be displayed
                    // Also, hang on to the reference count for the cached thumbnail. We want to keep it into the cache until
                    // we move away from here and the image is no longer nearby (or some other condition).
                    // The render code will also grab a reference count, but it will release it when it isn't being rendered.
                    // Because of the above logic, we don't need to set the imageCacheObject here...
                    ire.imageRenderType = thumb;
                    [self updateImageMetadataForElement:ire];
                    
                    [self calculateTimeAdjustedImageList];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateImageTexture
                                                                        object:self userInfo:nil];
                };
                dataRequest.errorOccurred=^(NSError *error,NSString *errDescription, FluxDataRequest *failedDataRequest){
                    ire.imageTypesFetched = ire.imageTypesFetched & ~(FluxImageTypeMask_thumb);
                };
                
                [self.fluxDataManager requestImagesByLocalID:dataRequest withSize:thumb];
            }
            
            // As long as we have an image to render, we can add it to the displayList
            // imageRenderType is popualted once we have an image, and is only ever dropped down to thumb (during time-scrubbing)
            // If we ever set it back to none, this will break, and will never again be increased!!!!
            if (ire.imageRenderType > 0)
            {
                //  calc imagePose (via openglvc call) & add to displayList
                [self updateImageMetadataForElement:ire];
                [self.displayList addObject:ire];
                
                //to get display date range
                NSDate *date = [ire timestamp]; 
                if (self.earliestDisplayDate == nil && self.latestDisplayDate == nil)
                {
                    self.earliestDisplayDate = date;
                    self.latestDisplayDate = date;
                }
                if ([date compare:self.earliestDisplayDate] == NSOrderedAscending)
                {
                    self.earliestDisplayDate = date;
                }
                if ([date compare:self.latestDisplayDate] == NSOrderedDescending)
                {
                    self.latestDisplayDate = date;
                }
            }
        }
        [_nearbyListLock unlock];

        // sort by abs(heading delta with current) asc
        [self.displayList sortUsingComparator:^NSComparisonResult(FluxImageRenderElement *obj1, FluxImageRenderElement *obj2) {
            // get heading deltas relative to current...
            
            double h1 = floor(fabs(obj1.imageMetadata.relHeading) / 5.0);         // 5-degree blocks
            double h2 = floor(fabs(obj2.imageMetadata.relHeading) / 5.0);

            if (h1 != h2)
            {
                return (h1 < h2) ? NSOrderedAscending : NSOrderedDescending;
            }
            else
            {
                return ([obj2.timestamp compare:obj1.timestamp]);   // sort descending timestamp
            }
        }];
        
        if (featureMatchingSupported)
        {
            // Check nearbyList for feature matching tasks to spawn off (since tasks are spawned off, this routine is quick)
            // We are checking the un-filtered list to maximize chances of finding a match
            // Also pass in display list so that priority can be given to images currently viewed
            // Since this code is called very frequently, the retry logic will also be handled here for failed matches
            [self checkForFeatureMatchingTasksWithNearbyItems:self.nearbyUnPrunedList withDisplayItems:self.displayList];
        }
        
        inCalcTimeAdjImageList = false;
    }
    [_displayListLock unlock];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateNearbyList
                                                        object:self userInfo:nil];

    NSDictionary *userInfoDict = [[NSDictionary alloc]
                                  initWithObjectsAndKeys:self.displayList, @"displayList" , nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateDisplayList
                                                        object:self userInfo:userInfoDict];
    
}

#pragma mark - Image Capture

- (void)didStartCameraMode:(NSNotification *)notification
{
    [_displayListLock lock];
    {
        if (_isScanMode)
        {
            _timeRangeMinIndexScan = _timeRangeMinIndex;
            _timeRangeMinIndex = 0;
            _isScanMode = false;
            [self requestNearbyItems];
        }
    }
    [_displayListLock unlock];
}

- (void)didStopCameraMode:(NSNotification *)notification
{
    [_displayListLock lock];
    {
        if (!_isScanMode)
        {
            _timeRangeMinIndex = _timeRangeMinIndexScan;
            _isScanMode = true;
            
            // not sure if need to copy images out of notification into nearby list but will see...
            NSMutableArray *capturedImageObjects = [[notification userInfo] objectForKey:@"capturedImageObjects"];
            
            if (capturedImageObjects)
            {
                [_nearbyListLock lock];
                for (FluxScanImageObject*imgObject in capturedImageObjects)
                {
                    // find the objects by key in the master meta list and add to nearbylist
                    FluxImageRenderElement *ire = [_fluxNearbyMetadata objectForKey:imgObject.localID];
                    if (ire)
                    {
                        [_nearbyScanList insertObject:ire atIndex:0];
                    }
                }
                [_nearbyListLock unlock];
                [self calculateTimeAdjustedImageList];
            }
            else
            {
                NSLog(@"Apparently capturedImageObjects is not defined");
            }
            
            if ((!capturedImageObjects) || (capturedImageObjects.count <= 0))
            {
                // Remove locals from fluxNearbyMetadata based on keys in _nearbyCamList
                for (FluxImageRenderElement *ire in _nearbyCamList)
                {
                    [_fluxNearbyMetadata removeObjectForKey:ire.localID];
                }
            }
          
            // clear out camera imagery
            [_nearbyCamList removeAllObjects];
            [_displayCamList removeAllObjects];
            
            [self requestNearbyItems];
        }
    }
    [_displayListLock unlock];
}

- (void)didCaptureNewImage:(NSNotification *)notification
{
    FluxScanImageObject *newImageObject = [[notification userInfo] objectForKey:@"imageObject"];
//    UIImage *newImage = [[notification userInfo] objectForKey:@"image"];
    FluxImageRenderElement *ire = [[FluxImageRenderElement alloc]initWithImageObject:newImageObject];
    ire.imageRenderType = full_res;
    ire.imageTypesFetched = ire.imageTypesFetched | FluxImageTypeMask_full_res;
    ire.localCaptureTime = ire.timestamp;
    [_fluxNearbyMetadata setObject:ire forKey:newImageObject.localID];
    [_nearbyCamList addObject:ire];
    [self requestNearbyItems];
}

- (void)didUndoCapture:(NSNotification *)notification
{
    [_fluxNearbyMetadata removeObjectForKey: [[notification userInfo] objectForKey:@"localID"]];
    if (_nearbyCamList.count > 0) {
        [_nearbyCamList removeObjectAtIndex:0];
    }
    
    // Need to remove item from fluxNearbyMetadata, fluxMetadata, and fluxImageCache
    
    [self requestNearbyItems];
}

#pragma mark - Requests
#pragma mark Global Image Request

- (FluxImageRenderElement *)getRenderElementForKey:(FluxLocalID *)localID
{
    return [_fluxNearbyMetadata objectForKey:localID];
}

- (void)requestNearbyItems
{
    // make request
    if (_isScanMode)
    {
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        
        dataRequest.maxReturnItems = 100;
        dataRequest.searchFilter = dataFilter;
        dataRequest.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
        
        [dataRequest setNearbyListReady:^(NSArray *imageList)
        {
            // ignore the request response if we are in camera capture mode
            if (!_isScanMode)
                return;
            
            // process request using nearbyList:
            //  copy local-only objects (justCaptured > 0) into localList
            NSMutableDictionary *localOnlyObjects = [[NSMutableDictionary alloc] init];
            
            NSMutableArray *nearbyLocalIDs = [[NSMutableArray alloc] init];
            
            [_nearbyListLock lock];
            {
                // Iterate over the current nearbylist and clear out anything that is not local-only, or that has been local too long
                for (FluxImageRenderElement *ire in self.nearbyUnPrunedList)
                {
                    if (ire.imageMetadata.justCaptured > 0)
                    {
                        if (ire.imageMetadata.justCaptured++ < 10)
                        {
                            [localOnlyObjects setObject:ire forKey:ire.localID];
                        }
                        
                    }
                }
                
                //  clean nearbyList (empty)
                [self.nearbyUnPrunedList removeAllObjects];
                
                //  for each item in response
                for (FluxScanImageObject *curImgObj in imageList)
                {
                    // check the local list first
                    FluxImageRenderElement *localImgRenderObj = [localOnlyObjects objectForKey:curImgObj.localID];
                    FluxImageRenderElement *curImgRenderObj = [_fluxNearbyMetadata objectForKey:curImgObj.localID];
                    if (localImgRenderObj == nil)
                    {
                        // then check in nearbyMeta
                        if (curImgRenderObj == nil)
                        {
                            // still not found so add new entry
                            FluxScanImageObject *cachedMetadata = [self.fluxDataManager getMetadataObjectFromCacheWithLocalID:curImgObj.localID];
                            curImgRenderObj = [[FluxImageRenderElement alloc]initWithImageObject:cachedMetadata];
                            [_fluxNearbyMetadata setObject:curImgRenderObj forKey:curImgObj.localID];
                        }
                    }
                    else
                    {
                        // check against nearbyMeta entry (if exists)
                        if (curImgRenderObj != nil)
                        {
                            // in both lists - make sure things are transferred properly
                            curImgRenderObj.localCaptureTime = localImgRenderObj.localCaptureTime;
                            curImgRenderObj.imageRenderType = localImgRenderObj.imageRenderType;
                            curImgRenderObj.imageMetadata.justCaptured = 0;
                            localImgRenderObj.imageMetadata.justCaptured = 0;
                        }
                        else
                        {
                            curImgRenderObj = localImgRenderObj;
                        }
                        
                        // remove from localobjectsonly list so isn't processed again below
                        [localOnlyObjects removeObjectForKey:curImgObj.localID];
                        localImgRenderObj = nil;
                    }
                    
                    if (curImgRenderObj != nil)
                    {
                        // update lastrefd time, metadata
                        curImgRenderObj.lastReferenced = [[NSDate alloc]init];
                        FluxScanImageObject *cachedMetadata = [self.fluxDataManager getMetadataObjectFromCacheWithLocalID:curImgObj.localID];
                        curImgRenderObj.imageMetadata = cachedMetadata;
                    }
                    
                    // copy to nearbyList
                    [self.nearbyUnPrunedList addObject:curImgRenderObj];
                    [nearbyLocalIDs addObject:curImgRenderObj.localID];
                }
                
                //  for each remaining item in localOnlyObjects list
                for (FluxImageRenderElement *localRender in [localOnlyObjects allValues])
                {
                    // find in nearbyList
                    FluxImageRenderElement *curImgRenderObj = [_fluxNearbyMetadata objectForKey:localRender.localID];
                    if (curImgRenderObj == nil)
                    {
                        // if not found then an error - local images should always be in the metadata list
                        NSLog(@"FluxDisplayManager requestNearbyItems local image not found in metadata list");
                    }
                    else
                    {
                        // copy to nearbyList
                        [self.nearbyUnPrunedList addObject:curImgRenderObj];
                        [nearbyLocalIDs addObject:curImgRenderObj.localID];

                        // update anything else that needs to be here...
                        curImgRenderObj.lastReferenced = [[NSDate alloc]init];
                    }
                }
            
                //  sort nearbyList by localCaptureTime then by timestamp desc (localCaptureTime bubbles recently taken local imagery to the top
                NSArray *sortDescriptors = [[NSArray alloc]initWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"localCaptureTime" ascending:NO],
                                                                            [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
                                                                            nil];
                
                [self.nearbyUnPrunedList sortUsingDescriptors:sortDescriptors];
                
                // spin through list and remove duplicates - shouldn't be any but given the fits the GL rendering sub-system throws if they are present, better safe than sorry...
                // NOTE: elements should be right next to each other (same timestamp) - this allows us to do neighbour comparisons rather than full-list checks.
                NSMutableArray *duplist = [[NSMutableArray alloc]init];
                FluxImageRenderElement *prevIre = nil;
                int c = 0;
                for (FluxImageRenderElement *ire in self.nearbyUnPrunedList)
                {
                    if (prevIre != nil)
                    {
                        if (prevIre.imageMetadata.imageID == ire.imageMetadata.imageID)
                        {
                            // have a duplicate - kill the first one
                            [duplist addObject:[NSNumber numberWithInteger:c]];
                        }
                    }
                    c++;
                    prevIre = ire;
                }
                
                // remove in reverse order (bottom up) so indexes aren't messed up
                for (NSNumber *idx in [duplist reverseObjectEnumerator])
                {
                    [self.nearbyUnPrunedList removeObjectAtIndex:[idx intValue]];
                }

                [self calculateTimeAdjustedImageList];
                
                [self.fluxDataManager cleanupNonLocalContentWithLocalIDArray:nearbyLocalIDs];
            }
            [_nearbyListLock unlock];

        }];
        
        CLLocation *loc = self.locationManager.location;
        [self.fluxDataManager requestImageListAtLocation:loc withRadius:scanImageRequestRadius withDataRequest:dataRequest];

    }
    else
    {
        [_nearbyListLock lock];
        {
            // camera mode - just sort and notify
            //  sort nearbyList by localCaptureTime then by timestamp desc (localCaptureTime bubbles recently taken local imagery to the top
            NSArray *sortDescriptors = [[NSArray alloc]initWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"localCaptureTime" ascending:NO],
                                        [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
                                        nil];
            
            [self.nearbyUnPrunedList sortUsingDescriptors:sortDescriptors];
            
            [self calculateTimeAdjustedImageList];
        }
        [_nearbyListLock unlock];
    }
}

#pragma mark MapView Image Request

- (void)requestMapPinsForLocation:(CLLocationCoordinate2D)location withRadius:(float)radius andFilter:(FluxDataFilter *)mapDataFilter
{
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    
    dataRequest.maxReturnItems = 30000;
    if (mapDataFilter)
    {
        dataRequest.searchFilter = mapDataFilter;
    }
    else
    {
        dataRequest.searchFilter = dataFilter;        
    }

    dataRequest.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    
    [dataRequest setWideAreaListReady:^(NSArray *imageList){
        NSDictionary *userInfo = @{FluxDisplayManagerMapPinListKey : imageList};
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateMapPinList
                                                            object:self userInfo:userInfo];
    }];
    [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        NSString*errorString = @"Unknown network error occured";
        NSDictionary *userInfoDict = [[NSDictionary alloc]
                                      initWithObjectsAndKeys:errorString, @"errorString" , nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidFailToUpdateMapPinList
                                                            object:self userInfo:userInfoDict];
    }];
    [self.fluxDataManager requestMapImageListAtLocation:location withRadius:radius withDataRequest:dataRequest];
}

#pragma mark - List Management Support

- (NSMutableArray *)displayList
{
    if (_isScanMode)
        return _displayScanList;
    else
        return _displayCamList;
}

- (NSMutableArray *)nearbyList
{
    return _nearbyPrunedList;
}

- (NSMutableArray *)nearbyUnPrunedList
{
    if (_isScanMode)
        return _nearbyScanList;
    else
        return _nearbyCamList;
}

- (int)displayListCount
{
    return [self.displayList count];
}

- (int)nearbyListCount
{
    return [self.nearbyList count];
}

- (void)lockDisplayList
{
    // lock the display list
    [_displayListLock lock];
}

- (void)unlockDisplayList
{
    // unlock the display list
    [_displayListLock unlock];
}


- (NSMutableArray *)selectRenderElementsInto:(NSMutableArray *)renderList ToMaxCount:(integer_t)maxCount
{
    [renderList removeAllObjects];
    
    int maxDisplayCount = self.displayListCount;
    maxDisplayCount = MIN(maxDisplayCount, maxCount);

    [self lockDisplayList];

    int count = 0;
    if (count < maxDisplayCount)
    {
        for (FluxImageRenderElement *ire in self.displayList)
        {
            if (fabs(ire.imageMetadata.relHeading) < 90.0)
            {
                // make sure a duplicate object isn't there already - need to search for duplicate localIDs.
                bool dupFound = false;
                for (FluxImageRenderElement *lire in renderList)
                {
                    dupFound = dupFound || ([lire.localID isEqualToString:ire.localID]);
                }
                
                if ((!dupFound) && (count < maxDisplayCount))
                {
                    [renderList addObject:ire];
                    count++;
                }
            }
        }
    }
    [self unlockDisplayList];

    return renderList;
}

- (void)sortRenderList:(NSMutableArray *)renderList
{
    NSArray *sortDescriptors = [[NSArray alloc]initWithObjects: /*[NSSortDescriptor sortDescriptorWithKey:@"localCaptureTime" ascending:NO],*/
                                [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
                                nil];
    
    [renderList sortUsingDescriptors:sortDescriptors];
    if (!_isScrubAnimating)
    {
        if (_isScanMode)
        {
            FluxImageType higherImageResolution = quarterhd;
            FluxImageTypeMask higherImageResolutionBitMask = FluxImageTypeMask_quarterhd;
            
            // reset to higher-res (quarterhd) textures if already in the cache
            for (FluxImageRenderElement *ire in renderList)
            {
                if (ire.imageRenderType < higherImageResolution)
                {
                    FluxImageType rtype = none;
                    FluxCacheImageObject *imageCacheObj = [self.fluxDataManager fetchImagesByLocalID:ire.localID withSize:higherImageResolution returnSize:&rtype];
                    if (imageCacheObj.image && (rtype == higherImageResolution))
                    {
                        ire.imageRenderType = higherImageResolution;
                        ire.imageTypesFetched = ire.imageTypesFetched | higherImageResolutionBitMask;
                        
                        // Only care about existence of an image here. Decrement reference count as we are not using the object.
                        [imageCacheObj endContentAccess];
                    }
                }
            }

            if (_imageRequestCountQuart < maxRequestCountQuart)
            {
                // look to see if can trigger load of higher resolution
                for (FluxImageRenderElement *ire in renderList)
                {
                    if (!(ire.imageTypesFetched & higherImageResolutionBitMask) && (!ire.imageMetadata.justCaptured))
                    {
                        // fetch the quart for this element
                        ire.imageTypesFetched = ire.imageTypesFetched | higherImageResolutionBitMask;

                        [_imageRequestCountLock lock];
                        _imageRequestCountQuart++;
                        [_imageRequestCountLock unlock];
                        
                        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
                        [dataRequest setRequestedIDs:[NSMutableArray arrayWithObject:ire.localID]];
                        dataRequest.imageReady=^(FluxLocalID *localID, FluxCacheImageObject *imageCacheObj, FluxDataRequest *completedDataRequest){
                            // assign image into ire.image...
                            ire.imageRenderType = higherImageResolution;
                            
                            // Only care about existence of an image here. Decrement reference count as we are not using the object.
                            [imageCacheObj endContentAccess];
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateImageTexture
                                                                                object:self userInfo:nil];
                            [_imageRequestCountLock lock];
                            _imageRequestCountQuart--;
                            [_imageRequestCountLock unlock];
                        };
                        dataRequest.errorOccurred=^(NSError *error,NSString *errDescription, FluxDataRequest *failedDataRequest){
                            [_imageRequestCountLock lock];
                            _imageRequestCountQuart--;
                            [_imageRequestCountLock unlock];

                            ire.imageTypesFetched = ire.imageTypesFetched & ~(higherImageResolutionBitMask);
                        };
                        [self.fluxDataManager requestImagesByLocalID:dataRequest withSize:higherImageResolution];

                        if (_imageRequestCountQuart >= maxRequestCountQuart)
                        {
                            // only request a few at a time
                            break;
                        }
                    }
                }
            }
        }
    }
    else
    {
        // only load thumbs if loading required
        for (FluxImageRenderElement *ire in renderList)
        {
            ire.imageRenderType = thumb;
        }
    }
}

#pragma mark - Logging

- (void) createNewLogFiles
{
    NSString *logName = @"Documents/log.txt";
    
    NSString *logFilename = [NSHomeDirectory() stringByAppendingPathComponent:logName];
    [[NSFileManager defaultManager] createFileAtPath:logFilename contents:nil attributes:nil];
    logFile = [NSFileHandle fileHandleForWritingAtPath:logFilename];
    
    logDateFormat = [[NSDateFormatter alloc] init];
    [logDateFormat setDateFormat:@"yyyy'-'MM'-'dd', 'HH':'mm':'ss'.'SSS', '"];
}

- (void) writeLog:(NSString *)logmsg
{
    if (logFile == nil)
    {
        return;
    }
    
    NSDate *curDate = [NSDate date];
    NSString *curDateString = [logDateFormat stringFromDate:curDate];
    
    NSString *outStr = [[curDateString stringByAppendingString:logmsg] stringByAppendingString:@"\n"];
    
    [logFile writeData:[outStr dataUsingEncoding:NSUTF8StringEncoding]];
}

// @brief The usual PI/180 constant
static const double DEG_TO_RAD = 0.017453292519943295769236907684886;
/// @brief Earth's quatratic mean radius for WGS-84
static const double EARTH_RADIUS_IN_METERS = 6372797.560856;

/** @brief Computes the arc, in radian, between two WGS-84 positions.
 *
 * The result is equal to <code>Distance(from,to)/EARTH_RADIUS_IN_METERS</code>
 *    <code>= 2*asin(sqrt(h(d/EARTH_RADIUS_IN_METERS )))</code>
 *
 * where:<ul>
 *    <li>d is the distance in meters between 'from' and 'to' positions.</li>
 *    <li>h is the haversine function: <code>h(x)=sin²(x/2)</code></li>
 * </ul>
 *
 * The haversine formula gives:
 *    <code>h(d/R) = h(from.lat-to.lat)+h(from.lon-to.lon)+cos(from.lat)*cos(to.lat)</code>
 *
 * @sa http://en.wikipedia.org/wiki/Law_of_haversines
 */


- (double) haversineBetweenPosition1:(sensorPose) p1 andPosition2:(sensorPose) p2
{
    double arcInRadians = 0.0;
    double latitudeArc  = (p1.position.x - p2.position.x) * DEG_TO_RAD;
    double longitudeArc = (p1.position.y - p2.position.y) * DEG_TO_RAD;
    double latitudeH = sin(latitudeArc * 0.5);
    latitudeH *= latitudeH;
    double lontitudeH = sin(longitudeArc * 0.5);
    lontitudeH *= lontitudeH;
    double tmp = cos(p1.position.x*DEG_TO_RAD) * cos(p2.position.y*DEG_TO_RAD);
    arcInRadians = 2.0 * asin(sqrt(latitudeH + tmp*lontitudeH));
    
    return EARTH_RADIUS_IN_METERS * arcInRadians;
}

-  (void)testHaversine
{
    sensorPose p1;
    sensorPose p2;
    double distance;
    p1.position.x = 43.654113;
    p1.position.y = -79.383400;
    p2.position.x = 43.653527;
    p2.position.y = -79.383189;
    
    distance = [self haversineBetweenPosition1:p1 andPosition2:p2];
    NSLog(@"distance = %f", distance);
}

@end
