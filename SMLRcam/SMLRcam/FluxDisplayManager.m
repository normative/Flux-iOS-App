//
//  FluxDisplayManager.m
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDisplayManager.h"
#import "FluxScanImageObject.h"
#import "FluxImageCaptureViewController.h"
#import "FluxOpenGLViewController.h"

const int number_OpenGL_Textures = 5;
const int maxDisplayListCount   = 10;

const int maxRequestCountQuart = 2;
const int maxRequestCountThumb = 5;

const double minMoveDistanceThreshold = 1.0;
const NSTimeInterval maxMoveTimeThreshold = 5.0;

NSString* const FluxDisplayManagerDidUpdateDisplayList = @"FluxDisplayManagerDidUpdateDisplayList";
NSString* const FluxDisplayManagerDidUpdateNearbyList = @"FluxDisplayManagerDidUpdateNearbyList";
NSString* const FluxDisplayManagerDidUpdateImageTexture = @"FluxDisplayManagerDidUpdateImageTexture";
NSString* const FluxDisplayManagerDidUpdateMapPinList = @"FluxDisplayManagerDidUpdateMapPinList";
NSString* const FluxDisplayManagerDidFailToUpdateMapPinList = @"FluxDisplayManagerDidFailToUpdateMapPinList";

NSString* const FluxOpenGLShouldRender = @"FluxOpenGLShouldRender";

const double scanImageRequestRadius = 10.0;     // 10.0m radius for scan image requesting



@implementation FluxDisplayManager

- (id)init{
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
        
        _fluxMapContentMetadata = [[NSArray alloc]init];
        
        _nearbyListLock = [[NSRecursiveLock alloc] init];
        _nearbyScanList = [[NSMutableArray alloc]init];
        _nearbyCamList = [[NSMutableArray alloc]init];

        _displayListLock = [[NSRecursiveLock alloc] init];
        _displayScanList = [[NSMutableArray alloc]init];
        _displayCamList = [[NSMutableArray alloc]init];

        dataFilter = [[FluxDataFilter alloc]init];
        
        currHeading = 0.0;  // due North until told otherwise...
        
        _isScrubAnimating = false;
        _isScanMode = true;
        
        _imageRequestCountThumb = 0;
        _imageRequestCountQuart = 0;

        _imageRequestCountLock = [[NSLock alloc]init];
        
        _openGLVC = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePlacemark:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateHeading:) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateLocation:) name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
        
        // not using constants for this notification name because of conflicting header load ordering
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFilter:) name:@"FluxFilterViewDidChangeFilter" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStartCameraMode:) name:FluxImageCaptureDidPush object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStopCameraMode:) name:FluxImageCaptureDidPop object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCaptureNewImage:) name:FluxImageCaptureDidCaptureImage object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUndoCapture:) name:FluxImageCaptureDidUndoCapture object:nil];
    }
    
    return self;
}

//double getAbsAngle(double angle, double heading)
//{
//    double h1 = fmod((angle + 360.0), 360.0);
//    h1 = fabs(fmod(((heading - h1) + 360.0), 360.0));
//    if (h1 > 180.0)
//    {
//        h1 = 360.0 - h1;
//    }
//    
//    return h1;
//}


#pragma mark - Notifications

#pragma mark Location

-(void)didUpdatePlacemark:(NSNotification *)notification
{
    
}

- (void)didUpdateHeading:(NSNotification *)notification{
    // first normalize to (0 <= heading < 360.0)
    currHeading = fmod((self.locationManager.heading + 360.0), 360.0);
    [self calculateTimeAdjustedImageList];
}

- (void)didUpdateLocation:(NSNotification *)notification{
    // TS: need to filter this a little better - limit to only every 5s or some distance from last request, ignore when in cam mode
    
    // setup local sensorPose object with new lat/long
    // calc ECEF
    // compare to last ECEF
    //  if > threshold then
    //      last ECEF = current ECEF,
    //      request nearby
    sensorPose newPose;
    newPose.position.x = self.locationManager.location.coordinate.latitude;
    newPose.position.y = self.locationManager.location.coordinate.longitude;
    newPose.position.z = self.locationManager.location.altitude;
    
    [self.locationManager WGS84_to_ECEF:&newPose];

    double dx = newPose.ecef.x - lastMotionPose.ecef.x;
    double dy = newPose.ecef.y - lastMotionPose.ecef.y;
    
    double dist = sqrt(dx * dx + dy * dy);
    
    NSDate *now = [NSDate date];
    NSTimeInterval timeSinceLast = [now timeIntervalSinceDate:lastMotionTime];
    
    if ((dist > minMoveDistanceThreshold) || (timeSinceLast > maxMoveTimeThreshold))
    {
        lastMotionPose = newPose;
        lastMotionTime = now;
        NSString *logstr = [NSString stringWithFormat:@"New request at (%f, %f, %f), (distance=%f)", newPose.position.x, newPose.position.y, newPose.position.z, dist];
        [self writeLog:logstr];
        [self requestNearbyItems];
        
    }
}

#pragma mark Filter

- (void)didChangeFilter:(NSNotification*)notification{
    dataFilter = [notification.userInfo objectForKey:@"filter"];
    [self requestNearbyItems];
}

#pragma mark - Time

// determine sub-set of time-sorted image entries to copy into display list
// value is % of displayListCount and reps the top of the list.  List is fixed size of X
- (void)timeBracketDidChange:(float)value
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxOpenGLShouldRender object:self userInfo:nil];
    // TODO: these notifications may come thick and fast (especially when using momentum) so we may want to limit them
    //          track the "latest" (order of call, not value) value in a "pending" variable
    //          only allow through when > min time has elapsed from last adjustment calc
    //              calc timeRangeMaxIndex based on pending variable
    //          need to call from "animation is done" notification as well to ensure we process the last value

    if (!_isScanMode)
        return;
    
    _timeRangeMinIndex = (self.nearbyList.count * value);
//    NSLog(@"timeRange: count: %d, value: %f, maxIndex: %d", [self.nearbyList count], value, _timeRangeMinIndex);
    [self calculateTimeAdjustedImageList];
}

- (void)timeBracketWillBeginScrolling
{
    NSLog(@"DisplayManager start scrolling");
//    _isScrubAnimating = true;
}

- (void)timeBracketDidEndScrolling
{
    NSLog(@"DisplayManager end scrolling");
//    _isScrubAnimating = false;
    
}

-(void) updateImageMetadataForElement:(FluxImageRenderElement*)element
{
    //    NSLog(@"Adding metadata for key %@ (dictionary count is %d)", key, [fluxNearbyMetadata count]);
    GLKQuaternion quaternion;
    
    FluxScanImageObject *locationObject = element.imageMetadata;
    
    element.imagePose->position.x =  locationObject.latitude;
    element.imagePose->position.y =  locationObject.longitude;
    element.imagePose->position.z =  locationObject.altitude;
    
    if(locationObject.location_confidence==1.0)
    {
        element.imagePose->validECEFEstimate =1;
        element.imagePose->ecef.x = locationObject.ecefX;
        element.imagePose->ecef.y = locationObject.ecefY;
        element.imagePose->ecef.z = locationObject.ecefZ;
    }
    else
    {
        element.imagePose->validECEFEstimate =0;
    }
    
    quaternion.x = locationObject.qx;
    quaternion.y = locationObject.qy;
    quaternion.z = locationObject.qz;
    quaternion.w = locationObject.qw;
    
    GLKMatrix4 quatMatrix =  GLKMatrix4MakeWithQuaternion(quaternion);
    GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    element.imagePose->rotationMatrix =  GLKMatrix4Multiply(matrixTP, quatMatrix);
    //    NSLog(@"Loaded metadata for image %d quaternion [%f %f %f %f]", idx, quaternion.x, quaternion.y, quaternion.z, quaternion.w);
}

- (void)calculateTimeAdjustedImageList
{
    static bool inCalcTimeAdjImageList = false;

    if (inCalcTimeAdjImageList)
        return;
  
    [_displayListLock lock];
    [_nearbyListLock lock];
    {
        // calculate up-to-date metadata elements (tangent-plane, relative heading) for all images in nearbyList
        // this will use a copy of the "current" value for the user pose so as to not interfere with the GL rendering loop.
        // The only time this may cause an issue is during periods of large orientation change (fast pivot by user) at which point the user will be
        // hard pressed to see the issues simply because of motion blur.
        
        // spin through nearbylist to update...
        if (self.openGLVC != nil)
        {
            [(FluxOpenGLViewController *)self.openGLVC updateImageMetadataForElementList:self.nearbyList];
        }
        
        inCalcTimeAdjImageList = true;
        
        // generate the displayList...
        
        // clear the displayList
        [self.displayList removeAllObjects];
        
        // extract X images from nearbyList where timestamp <= time from slider (timeRangeMaxIndex)
        for (int idx = 0; ((self.displayList.count < maxDisplayListCount) && ((idx + _timeRangeMinIndex) < self.nearbyList.count)); idx++)
        {
            FluxImageRenderElement *ire = [self.nearbyList objectAtIndex:(_timeRangeMinIndex + idx)];
            if (ire.image == nil)
            {
                // check to see if we have the imagery in the cache..
                FluxImageType rtype = none;
                UIImage *image = [self.fluxDataManager fetchImagesByLocalID:ire.localID withSize:lowest_res returnSize:&rtype];
                if (image != nil)
                {
                    ire.image = image;
                    ire.imageType = rtype;
                }
                else if (_isScanMode)
                {
                    // request it if it isn't there...
                    ire.imageFetchType = thumb;
                    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
                    [dataRequest setRequestedIDs:[NSArray arrayWithObject:ire.localID]];
                    dataRequest.ImageReady=^(FluxLocalID *localID, UIImage *image, FluxDataRequest *completedDataRequest){
                        // assign image into ire.image...
                        ire.image = image;
                        ire.imageType = thumb;
                        ire.imageFetchType = none;
                        [self updateImageMetadataForElement:ire];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateImageTexture
                                                                            object:self userInfo:nil];
                    };
                    [self.fluxDataManager requestImagesByLocalID:dataRequest withSize:thumb];
                }
            }
            
            if (ire.image != nil)
            {
                //  calc imagePose (via openglvc call) & add to displayList
                [self updateImageMetadataForElement:ire];
                [self.displayList addObject:ire];
            }
        }
        
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
        
        inCalcTimeAdjImageList = false;
    }
    [_nearbyListLock unlock];
    [_displayListLock unlock];
    
//    NSLog(@"Nearby Sort:");
//    int i = 0;
//    for (FluxImageRenderElement *ire in self.nearbyList)
//    {
//        NSLog(@"render: i=%d, key=%@, headRaw=%f timestamp=%@", i++, ire.localID, ire.imageMetadata.heading, ire.timestamp);
//    }
//    
//    NSLog(@"Display Sort: localCurrHeading: %f", localCurrHeading);
//    i = 0;
//    for (FluxImageRenderElement *ire in self.displayList)
//    {
//        NSLog(@"dl: i=%d, key=%@, headDelta=%f, timestamp=%@", i++, ire.localID, ire.imageMetadata.heading, ire.timestamp);
//    }
    
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
            }
            else
            {
                NSLog(@"Apparently capturedImageObjects is not defined");
            }
            
            if ((!capturedImageObjects) && (capturedImageObjects.count <= 0))
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
    UIImage *newImage = [[notification userInfo] objectForKey:@"image"];
    FluxImageRenderElement *ire = [[FluxImageRenderElement alloc]initWithImageObject:newImageObject];
    ire.image = newImage;
    ire.imageType = full_res;
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
            // process request using nearbyList:
            //  copy local-only objects (imageid < 0) into localList
            NSMutableDictionary *localOnlyObjects = [[NSMutableDictionary alloc] init];
            
            [_nearbyListLock lock];
            {
//                for (int oidx = 0; oidx < (imageList.count-1); oidx++)
//                {
//                    FluxScanImageObject *oObj = [imageList objectAtIndex:oidx];
//                    for (int iidx = oidx + 1; iidx < imageList.count; iidx++)
//                    {
//                        FluxScanImageObject *iObj = [imageList objectAtIndex:iidx];
//                        if ((iObj != nil) && (oObj != nil))
//                        {
//                            if ([iObj.localID isEqualToString:oObj.localID])
//                            {
//                                NSLog(@"Duplicated image IDs in received image list: %@, %@, %d, %d", oObj.localID, iObj.localID, oObj.imageID, iObj.imageID);
//                            }
//                        }
//                    }
//                    
//                }

                // Iterate over the current nearbylist and clear out anything that is not local-only
                for (FluxImageRenderElement *ire in self.nearbyList)
                {
                    if (ire.imageMetadata.imageID < 0)
                    {
                        [localOnlyObjects setObject:ire forKey:ire.localID];
                    }
                }
                
                //  clean nearbyList (empty)
                [self.nearbyList removeAllObjects];
                
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
                            curImgRenderObj = [[FluxImageRenderElement alloc]initWithImageObject:curImgObj];
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
                            curImgRenderObj.textureMapElement = localImgRenderObj.textureMapElement;
                            curImgRenderObj.image = localImgRenderObj.image;
                            curImgRenderObj.imageType = localImgRenderObj.imageType;

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
                        // update lastrefd time, metadata, set dirty
                        curImgRenderObj.lastReferenced = [[NSDate alloc]init];
                        curImgRenderObj.imageMetadata = curImgObj;
                    }
                    
                    // copy to nearbyList
// list dup elimination
//                    bool found = false;
//                    for (FluxImageRenderElement *ire in self.nearbyList)
//                    {
//                        if (ire.imageMetadata.imageID == curImgRenderObj.imageMetadata.imageID)
//                        {
//                            found = true;
//                            NSLog(@"Found ID %d in nearby list already!!", ire.imageMetadata.imageID);
//                        }
//                    }
//                    
//                    if (!found)
//                    if ([self.nearbyList indexOfObject:curImgRenderObj] == NSNotFound)
                    {
                        [self.nearbyList addObject:curImgRenderObj];
                    }
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
                        [self.nearbyList addObject:curImgRenderObj];

                        // update anything else that needs to be here...
                        curImgRenderObj.lastReferenced = [[NSDate alloc]init];
                    }
                }
            
                //  sort nearbyList by localCaptureTime then by timestamp desc (localCaptureTime bubbles recently taken local imagery to the top
                NSArray *sortDescriptors = [[NSArray alloc]initWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"localCaptureTime" ascending:NO],
                                                                            [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
                                                                            nil];
                
                [self.nearbyList sortUsingDescriptors:sortDescriptors];
                
                // spin through list and remove duplicates - shouldn't be any but given the fits the GL rendering sub-system throws if they are present, better safe than sorry...
                // NOTE: elements should be right next to each other (same timestamp) - this allows us to do neighbour comparisons rather than full-list checks.
                NSMutableArray *duplist = [[NSMutableArray alloc]init];
                FluxImageRenderElement *prevIre = nil;
                int c = 0;
                for (FluxImageRenderElement *ire in self.nearbyList)
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
                    [self.nearbyList removeObjectAtIndex:[idx intValue]];
                }

                [self calculateTimeAdjustedImageList];
            }
            [_nearbyListLock unlock];

            [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateNearbyList
                                                                object:self userInfo:nil];

        }];
        
       CLLocation *loc = self.locationManager.location;
       [self.fluxDataManager requestImageListAtLocation:loc.coordinate withRadius:scanImageRequestRadius withDataRequest:dataRequest];

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
            
            [self.nearbyList sortUsingDescriptors:sortDescriptors];
            
            [self calculateTimeAdjustedImageList];
        }
        [_nearbyListLock unlock];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateNearbyList
                                                            object:self userInfo:nil];

    }
}

#pragma mark MapView Image Request

- (void)mapViewWillDisplay{
    //if we have items already, check if it's worth pulling again
    if (self.fluxMapContentMetadata && previousMapViewLocation) {
        if ([previousMapViewLocation distanceFromLocation:self.locationManager.location] > 50) {
            [self requestMapPinsForLocation:self.locationManager.location.coordinate withRadius:500.0 andFilter:nil];
        }
    }
    else{
        [self requestMapPinsForLocation:self.locationManager.location.coordinate withRadius:500.0 andFilter:nil];
    }
}

- (void)requestMapPinsForLocation:(CLLocationCoordinate2D)location withRadius:(float)radius andFilter:(FluxDataFilter *)mapDataFilter{
    
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    
    dataRequest.maxReturnItems = 30000;
    if (mapDataFilter) {
        dataRequest.searchFilter = mapDataFilter;
    }
    else{
        dataRequest.searchFilter = dataFilter;        
    }

    
    dataRequest.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    
    
    [dataRequest setWideAreaListReady:^(NSArray *imageList){
        self.fluxMapContentMetadata = imageList;
        CLLocation*temp = [[CLLocation alloc]initWithLatitude:location.latitude longitude:location.longitude];
        previousMapViewLocation = temp;
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateMapPinList
                                                            object:self userInfo:nil];
    }];
    [dataRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
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
                
                if (!dupFound)
                {
                    [renderList addObject:ire];
                    count++;
                    if (count >= maxDisplayCount)
                    {
                        break;
                    }
                }
            }
        }
    }
    [self unlockDisplayList];

    return renderList;
}

- (void)sortRenderList:(NSMutableArray *)renderList
{
//    NSLog(@"Renderlist Count: %d", renderList.count);

    NSArray *sortDescriptors = [[NSArray alloc]initWithObjects: /*[NSSortDescriptor sortDescriptorWithKey:@"localCaptureTime" ascending:NO],*/
                                [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
                                nil];
    
    [renderList sortUsingDescriptors:sortDescriptors];
    
    if (!_isScrubAnimating)
    {
        if (_imageRequestCountQuart < maxRequestCountQuart)
        {
            // look to see if can trigger load of higher resolution
            for (FluxImageRenderElement *ire in renderList)
            {
                if ((ire.imageFetchType == none) && (ire.imageType < quarterhd))        // only fetch if we aren't fetching and aren't already showing...
                {
                    // fetch the quart for this element
                    ire.imageFetchType = quarterhd;

                    [_imageRequestCountLock lock];
                    _imageRequestCountQuart++;
                    [_imageRequestCountLock unlock];
                    
                    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
                    [dataRequest setRequestedIDs:[NSArray arrayWithObject:ire.localID]];
                    dataRequest.ImageReady=^(FluxLocalID *localID, UIImage *image, FluxDataRequest *completedDataRequest){
                        // assign image into ire.image...
                        ire.imageFetchType = none;
                        ire.imageType = quarterhd;
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDisplayManagerDidUpdateImageTexture
                                                                            object:self userInfo:nil];
                        [_imageRequestCountLock lock];
                        _imageRequestCountQuart--;
                        [_imageRequestCountLock unlock];
                    };
                    [self.fluxDataManager requestImagesByLocalID:dataRequest withSize:quarterhd];
                    
                    // only request one at a time
                    break;
                }
            }
        }
    }
    else
    {
        // only load thumbs if loading required
        for (FluxImageRenderElement *ire in renderList)
        {
            ire.imageType = thumb;
        }
    }

//    NSLog(@"Render Sort:");
//    int i = 0;
//    for (FluxImageRenderElement *ire in renderList)
//    {
//        FluxImageType lt = (ire.textureMapElement != nil) ? ((ire.textureMapElement.localID == ire.localID) ? ire.textureMapElement.imageType : -1) : -2;
//        NSLog(@"render: i=%d, key=%@, headRaw=%f, timestamp=%@, fetchtype=%d, loadtype=%d", i++, ire.localID, ire.imageMetadata.heading, ire.timestamp, ire.imageFetchType, lt);
//    }
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




@end
