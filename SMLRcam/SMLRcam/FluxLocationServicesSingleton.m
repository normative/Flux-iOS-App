//
//  FluxLocationServicesSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-08.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxLocationServicesSingleton.h"
#import "FluxMotionManagerSingleton.h"

NSString* const FluxLocationServicesSingletonDidUpdateLocation = @"FluxLocationServicesSingletonDidUpdateLocation";
NSString* const FluxLocationServicesSingletonDidUpdateHeading = @"FluxLocationServicesSingletonDidUpdateHeading";
NSString* const FluxLocationServicesSingletonDidUpdatePlacemark = @"FluxLocationServicesSingletonDidUpdatePlacemark";
#define PI M_PI
#define a_WGS84 6378137.0
#define b_WGS84 6356752.3142

@implementation FluxLocationServicesSingleton

+ (id)sharedManager {
    static FluxLocationServicesSingleton *sharedFluxLocationServicesSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFluxLocationServicesSingleton = [[self alloc] init];
    });
    return sharedFluxLocationServicesSingleton;
}

- (id)init {
    if (self = [super init]) {
        
        // Create the manager object
        locationManager = [[CLLocationManager alloc] init];
        if (locationManager == nil)
        {
            return nil;
        }
        locationManager.delegate = self;
        
        // This is the most important property to set for the manager. It ultimately determines how the manager will
        // attempt to acquire location and thus, the amount of power that will be consumed.
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        
        // When "tracking" the user, the distance filter can be used to control the frequency with which location measurements
        // are delivered by the manager. If the change in distance is less than the filter, a location will not be delivered.
        locationManager.distanceFilter = kCLDistanceFilterNone;
        
        // This will drain battery faster, but for now, we want to make sure that we continue to get frequent updates
        locationManager.pausesLocationUpdatesAutomatically = NO;
        
        locationMeasurements = [[NSMutableArray alloc] init];
        
        if ([CLLocationManager headingAvailable]) {
            locationManager.headingFilter = 5;
        }
    }
    self.notMoving = 1;
    [self initKFilter];
    [self startKFilter];
    return self;
}

- (void)startLocating{
    [locationManager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)  name:UIDeviceOrientationDidChangeNotification  object:nil];
    [self orientationChanged:nil];
    
    if ([CLLocationManager headingAvailable]) {
        [locationManager startUpdatingHeading];
    }
    else {
        NSLog(@"No Heading Information Available");
    }
}
- (void)endLocating{
    [locationManager stopUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    if ([CLLocationManager headingAvailable]) {
        [locationManager stopUpdatingHeading];
    }
}

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown)
    {
        // Face-up, face-down, and unknown will preserve the previous frame
        return;
    }
    
    locationManager.headingOrientation = orientation;
}

- (void)updateUserPose
{
    sensorPose localUserPose;
    FluxMotionManagerSingleton *motionManager = [FluxMotionManagerSingleton sharedManager];
    
    CMAttitude *att = motionManager.attitude;
    
    GLKQuaternion quat = GLKQuaternionMake(att.quaternion.x, att.quaternion.y, att.quaternion.z, att.quaternion.w);
    localUserPose.rotationMatrix =  GLKMatrix4MakeWithQuaternion(quat);
    
    //_userPose.rotationMatrix = att.rotationMatrix;
    GLKMatrix4 matrixTP = GLKMatrix4MakeRotation(M_PI_2, 0.0,0.0, 1.0);
    localUserPose.rotationMatrix =  GLKMatrix4Multiply(matrixTP, localUserPose.rotationMatrix);
    
    localUserPose.position.x =self.location.coordinate.latitude;
    localUserPose.position.y =self.location.coordinate.longitude;
    localUserPose.position.z =self.location.altitude;
    
    [self WGS84_to_ECEF:&localUserPose];
    
    _userPose = localUserPose;
    
}

#pragma mark - LocationManager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocations{
    // Grab last entry for now, since we should be getting all of them
    Geolocation kfgeolocation;
    
    if ([newLocations count] > 1)
    {
        NSLog(@"Received more than one location (%d)", [newLocations count]);
    }
    CLLocation *newLocation = [newLocations lastObject];

    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0)
    {
        NSLog(@"Invalid measurement (horizontalAccuracy=%f)",newLocation.horizontalAccuracy);
        return;
    }
    
    // test that the vertical accuracy does not indicate an invalid measurement
    if (newLocation.verticalAccuracy < 0)
    {
        NSLog(@"Invalid measurement (verticalAccuracy=%f)",newLocation.verticalAccuracy);
        return;
    }
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0)
    {
        NSLog(@"location age too old (%f)",locationAge);
        return;
    }
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    //log location params
//    NSLog(@"Adding new location  with date: %@ \nAnd Location: %0.15f, %0.15f, %f +/- %f (h), %f (v)",
//          [dateFormat stringFromDate:newLocation.timestamp], newLocation.coordinate.latitude, newLocation.coordinate.longitude,
//          newLocation.altitude, newLocation.horizontalAccuracy, newLocation.verticalAccuracy);
    
    // store all of the measurements, just so we can see what kind of data we might receive
    [locationMeasurements addObject:newLocation];
    
    // truncate data to maximum size of window (i.e. 5 locations)
    while ([locationMeasurements count] > 5)
    {
        [locationMeasurements removeObjectAtIndex:0];
    }
   
    // TODO: add in code here to "correct" the current location based on whatever (Kalman, etc.)
    //  Update newLocation and procede
    
//#warning Overriding location with fixed value
//    {
//    // HACK
//    // force location value to eliminate GPS from equation...
////    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.324796, -79.813148);   // Burlington office
//    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.324841, -79.81314);   // Burlington office
////    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.324722, -79.812943);     // end of driveway
////    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.65337, -79.40658);     // Normative office
////    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.325796, -79.813148);   // 20 images for time scroll
////    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.326796, -79.813148);   // ??
////    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(43.327796, -79.813148);   // ??
//    newLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:newLocation.altitude
//                                      horizontalAccuracy:newLocation.horizontalAccuracy verticalAccuracy:newLocation.verticalAccuracy
//                                      course:newLocation.course speed:newLocation.speed timestamp:newLocation.timestamp];
//    }
    
    self.location = newLocation;
    self.rawlocation = newLocation;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *walkMode = [defaults objectForKey:@"Walk Mode"];
    
    if (walkMode.intValue == 1)
    {
        self.notMoving = (newLocation.speed > 0.75) ? 0 : 1;
    }
    else
    {
        self.notMoving = 1;
    }
   
    
    //NSLog(@"Saved lat/long: %0.15f, %0.15f", self.location.coordinate.latitude,
    //      self.location.coordinate.longitude);
  
    
    [self setMeasurementWithLocation:self.location];
    [self ComputeGeodecticFromkfECEF:&kfgeolocation];
    
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(kfgeolocation.latitude, kfgeolocation.longitude);
      newLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:kfgeolocation.altitude
                                          horizontalAccuracy:newLocation.horizontalAccuracy verticalAccuracy:newLocation.verticalAccuracy
                                          course:newLocation.course speed:newLocation.speed timestamp:newLocation.timestamp];
    
    if (isnan(newLocation.coordinate.latitude) || isnan(newLocation.coordinate.longitude)) {
        self.location = self.rawlocation;
    }
    else{
        self.location = newLocation;
    }
    
    [self updateUserPose];
    
    // Notify observers of updated position
    if (self.location != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdateLocation object:self];
        //[self reverseGeocodeLocation:self.location];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (newHeading.headingAccuracy < 0)
        return;
    // Use the true heading if it is valid.
    self.heading = ((newHeading.trueHeading >= 0) ? newHeading.trueHeading : newHeading.magneticHeading);

    // now compute orientationHeading based on current device orientation
    [self updateUserPose];
    sensorPose localUserPose = _userPose;
    
    viewParameters localUserVp;
    
    // calculate angle between user's viewpoint and North
    [self computeTangentParametersForUserPose:&localUserPose toViewParameters:&localUserVp];
    
    
    double x1 = 0.0;
    double y1 = 1.0;
    double x2 = localUserVp.at.x;
    double y2 = localUserVp.at.y;
    double dotx = (x1 * x2);
    double doty = (y1 * y2);
    
    double scalar = dotx + doty;
    double magsq1 = x1 * x1 + y1 * y1;
    double magsq2 = x2 * x2 + y2 * y2;
    
    double costheta = (scalar) / sqrt(magsq1 * magsq2);
    double theta = acos(costheta) * 180.0 / M_PI;
    
    if (x2 < 0)
    {
        theta = -theta;
    }
    
    while (theta < 0.0)
        theta += 360.0;
    
    self.orientationHeading = theta;
    
    // Notify observers of updated heading, if we have a valid heading
    // Since heading is a double, assume that we only have a valid heading if we have a location
    if (self.location != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdateHeading object:self];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Failed with error: %@", [error localizedDescription]);
    // The location "unknown" error simply means the manager is currently unable to get the location.
    if ([error code] != kCLErrorLocationUnknown)
    {
        [self endLocating];
    }
}

#pragma mark - Location geocoding

- (void)reverseGeocodeLocation:(CLLocation*)thelocation
{
    CLGeocoder* theGeocoder = [[CLGeocoder alloc] init];
    
    [theGeocoder reverseGeocodeLocation:thelocation completionHandler:^(NSArray *placemarks, NSError *error)
    {
        if (error)
        {
            if (error.code == kCLErrorNetwork)
            {
                NSLog(@"No internet connection for reverse geolocation");
                //Alert(@"No Internet connection!");
                return;
            }
            else if (error.code == kCLErrorGeocodeFoundPartialResult){
                NSLog(@"Only partial placemark returned");
            }
            else {
                NSLog(@"Error Reverse Geolocating: %@", [error localizedDescription]);
                return;
            }
        }
        
        self.placemark = [placemarks lastObject];
        
        // Notify observers of updated address with placemark
        if (self.placemark != nil)
        {
            NSString *newSubLocality = [self.placemark.addressDictionary valueForKey:@"SubLocality"];
            NSString *newSubAdministrativeArea = [self.placemark.addressDictionary valueForKey:@"SubAdministrativeArea"];
            
            if (![self.subadministativearea isEqualToString: newSubAdministrativeArea] || ![self.sublocality isEqualToString: newSubLocality])
            {
                self.sublocality = newSubLocality;
                self.subadministativearea = newSubAdministrativeArea;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdatePlacemark object:self];
            }
        }
    }];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager{
    return YES;
}

#pragma mark - Filtering

-(void) WGS84_to_ECEF:(sensorPose *)sp{
    double normal;
    double eccentricity;
    double flatness;
    
    GLKVector3 lla_rad; //latitude, longitude, altitude
    
    lla_rad.x = sp->position.x*PI/180.0;
    lla_rad.y = sp->position.y*PI/180.0;
    lla_rad.z = sp->position.z;
    
    flatness = (a_WGS84 - b_WGS84) / a_WGS84;
    
    eccentricity = sqrt(flatness * (2 - flatness));
    normal = a_WGS84 / sqrt(1 - (eccentricity * eccentricity * sin(lla_rad.x) *sin(lla_rad.x)));
    
    sp->ecef.x = (lla_rad.z + normal)* cos(lla_rad.x) * cos(lla_rad.y);
    sp->ecef.y = (lla_rad.z + normal)* cos(lla_rad.x) * sin(lla_rad.y);
    sp->ecef.z = (lla_rad.z + (1- eccentricity* eccentricity)*normal)* sin(lla_rad.x);
    
    
}


//Maximum 4 iterations;

-(void) ComputeGeodecticFromkfECEF:(Geolocation *) kfgeolocation
{
    int max_iterations =4;
    int i;
    double lambda, phi, h, phi_next, h_next;
    double p; //radius in xy plane
    double X, Y,Z; //ecef coordinates;
    double N;
    X = _kflocation.x;
    Y = _kflocation.y;
    Z = _kflocation.z;
    
    double diff, eSq; //eSq eccentricity square
    
    diff = (a_WGS84 *a_WGS84) - (b_WGS84 *b_WGS84);
    eSq = diff/(a_WGS84*a_WGS84);
    lambda = atan2(Y, X);
   
    p = sqrt(X * X + Y * Y);
    
    phi = atan2(Z, p*(1-eSq));
    
    
    
    for(i =0; i< max_iterations;i++)
    {
        N= a_WGS84/(sqrt(1-(eSq * sin(phi)*sin(phi))));
        h_next = p/cos(phi) -N;
        phi_next = atan2(Z, p*(1 - (eSq*(N/(N+h_next)))));
        h = h_next;
        phi = phi_next;
    }
    
    kfgeolocation->latitude  =  phi/PI * 180.0;
    kfgeolocation->longitude = lambda/PI * 180.0;
    kfgeolocation->altitude  = h;
    
}


//only works for height = 0
-(void) ecefToWGS84KF
{
    double lambda, phi, h;
    double p, theta, N;
    double eSq, e_pSq, diff;
    double X, Y, sin3theta, cos3theta;
    diff = (a_WGS84 *a_WGS84) - (b_WGS84 *b_WGS84);
    eSq = diff/(a_WGS84*a_WGS84);
    e_pSq = diff/(b_WGS84*b_WGS84);
    
    //test
    
    //_kfPose.ecef.x =sp.ecef.x;
    //_kfPose.ecef.y =sp.ecef.y;
    //_kfPose.ecef.z =sp.ecef.z;
    
    //test ends
    
    
    lambda = atan2(_kfPose.ecef.y, _kfPose.ecef.x);
    X =_kfPose.ecef.x;
    Y = _kfPose.ecef.y;
    p = sqrt(X*X + Y*Y);
    theta = atan2(_kfPose.ecef.z*a_WGS84, p*b_WGS84);
    sin3theta = sin(theta);
    sin3theta = sin3theta*sin3theta *sin3theta;
    cos3theta = cos(theta);
    cos3theta = cos3theta*cos3theta *cos3theta;
    phi = atan2((_kfPose.ecef.z+(e_pSq*b_WGS84*sin3theta)), (p-(eSq*a_WGS84*cos3theta)));
    
    N= a_WGS84/(sqrt(1-(eSq * sin(phi)*sin(phi))));
    
    h = (p/cos(phi))-N;
    
    _kfPose.position.x = phi;
    _kfPose.position.y = lambda;
    _kfPose.position.z = h;
    
    NSLog(@"lla[%f, %f, %f]", phi*180/PI, lambda*180/PI,h);
    
}



-(void) tPlaneRotationKFilterWithPose:(sensorPose*) sp
{
    
    float rotation_te[16];
    
    GLKVector3 lla_rad; //latitude, longitude, altitude
    
    lla_rad.x = sp->position.x*PI/180.0;
    lla_rad.y = sp->position.y*PI/180.0;
    lla_rad.z = sp->position.z;
    
    rotation_te[0] = -1.0 * sin(lla_rad.y);
    rotation_te[1] = cos(lla_rad.y);
    rotation_te[2] = 0.0;
    rotation_te[3]= 0.0;
    rotation_te[4] = -1.0 * cos(lla_rad.y)* sin(lla_rad.x);
    rotation_te[5] = -1.0 * sin(lla_rad.x) * sin(lla_rad.y);
    rotation_te[6] = cos(lla_rad.x);
    rotation_te[7]= 0.0;
    rotation_te[8] = cos(lla_rad.x) * cos(lla_rad.y);
    rotation_te[9] = cos(lla_rad.x) * sin(lla_rad.y);
    rotation_te[10] = sin(lla_rad.x);
    rotation_te[11]= 0.0;
    rotation_te[12]= 0.0;
    rotation_te[13]= 0.0;
    rotation_te[14]= 0.0;
    rotation_te[15]= 1.0;
    
    kfrotation_teM = GLKMatrix4Transpose(GLKMatrix4MakeWithArray(rotation_te));
    
}
-(void) tPInverseRotationKFilterWithPose:(sensorPose*) sp
{
    
    float rotation_te[16];
    
    GLKVector3 lla_rad; //latitude, longitude, altitude
    
    lla_rad.x = sp->position.x*PI/180.0;
    lla_rad.y = sp->position.y*PI/180.0;
    lla_rad.z = sp->position.z;
    
    rotation_te[0] = -1.0 * sin(lla_rad.y);
    rotation_te[1] = cos(lla_rad.y);
    rotation_te[2] = 0.0;
    rotation_te[3]= 0.0;
    rotation_te[4] = -1.0 * cos(lla_rad.y)* sin(lla_rad.x);
    rotation_te[5] = -1.0 * sin(lla_rad.x) * sin(lla_rad.y);
    rotation_te[6] = cos(lla_rad.x);
    rotation_te[7]= 0.0;
    rotation_te[8] = cos(lla_rad.x) * cos(lla_rad.y);
    rotation_te[9] = cos(lla_rad.x) * sin(lla_rad.y);
    rotation_te[10] = sin(lla_rad.x);
    rotation_te[11]= 0.0;
    rotation_te[12]= 0.0;
    rotation_te[13]= 0.0;
    rotation_te[14]= 0.0;
    rotation_te[15]= 1.0;
    
    kfInverseRotation_teM = GLKMatrix4MakeWithArray(rotation_te);
    
}



-(void) computeKInitKFilter
{
    
	GLKVector3 positionTP;
    positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    [self WGS84_to_ECEF:&_kfInit];
    [self tPlaneRotationKFilterWithPose:&_kfInit];
    [self tPInverseRotationKFilterWithPose:&_kfInit];
    
}

//distance - distance of plane
-(void) computeKMeasureKFilter
{
    GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    // GLKVector3 positionTP1 = GLKVector3Make(0.0, 0.0, 0.0);
    //planar
    _kfMeasure.position.z = _kfInit.position.z;
    
    
    [self WGS84_to_ECEF:&_kfMeasure];
    
    
    positionTP.x = _kfMeasure.ecef.x - _kfInit.ecef.x;
    positionTP.y = _kfMeasure.ecef.y - _kfInit.ecef.y;
    positionTP.z = _kfMeasure.ecef.z - _kfInit.ecef.z;
    
    
    positionTP = GLKMatrix4MultiplyVector3(kfrotation_teM, positionTP);
    
    kfMeasureX = positionTP.x;
    kfMeasureY = positionTP.y;
    kfMeasureZ = positionTP.z;
    /*
     positionTP1 = GLKMatrix4MultiplyVector3(kfInverseRotation_teM, positionTP);
     
     positionTP1.x = _kfInit.ecef.x + positionTP1.x;
     positionTP1.y = _kfInit.ecef.y + positionTP1.y;
     positionTP1.z = _kfInit.ecef.z + positionTP1.z;
     
     NSLog(@"B:[%f %f %f] A:[%f %f %f]", _kfMeasure.ecef.x,_kfMeasure.ecef.y, _kfMeasure.ecef.z, positionTP1.x, positionTP1.y, positionTP1.z);
     //test
     */
    
}


 
- (void)registerPedDisplacementKFilter:(int)direction {
 
     NSLog(@"disp registered");
    // return;
    stepcount++;
     double enuHeadingRad;
     //int count = motionManager.pedometerCount;
     double stepsize =0.73;
 
    if(direction == -1)
        self.heading +=180.0;
    
    // heading =self.fluxDisplayManager.locationManager.heading ;
 
     enuHeadingRad = (90.0 +(360- self.heading))/180.0 *PI;
     
     kfXDisp = stepsize * cos(enuHeadingRad);
     kfYDisp = stepsize * sin(enuHeadingRad);

 
 //[motionManager resetPedometer];
 
 
 
 }

- (void) computeFilteredECEF
{
    GLKVector3 positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    
    positionTP.x = kfilter.positionX;
    positionTP.y = kfilter.positionY;
    positionTP.z = kfMeasureZ;
    positionTP = GLKMatrix4MultiplyVector3(kfInverseRotation_teM, positionTP);
    
    
    _kfPose.ecef.x = _kfInit.ecef.x + positionTP.x;
    _kfPose.ecef.y = _kfInit.ecef.y + positionTP.y;
    _kfPose.ecef.z = _kfInit.ecef.z + positionTP.z;
    
    _kflocation.valid = 1;
    _kflocation.x = _kfPose.ecef.x;
    _kflocation.y = _kfPose.ecef.y;
    _kflocation.z = _kfPose.ecef.z;
}
- (void) computeEstimateDelta
{
    
    double tx, ty;
    _kfdebug.gpsx = kfMeasureX;
    _kfdebug.gpsy = kfMeasureY;
    _kfdebug.filterx = kfilter.positionX;
    _kfdebug.filtery = kfilter.positionY;
    
    _kfdebug.filterx = (double)stepcount;
    
    
    
    tx = kfMeasureX - kfilter.positionX;
    ty = kfMeasureY - kfilter.positionY;
    
    _estimateDelta = sqrt( tx*tx + ty*ty );
    if(_estimateDelta > _resetThreshold)
        [self resetKFilter];
    
}

- (void) initKFilter
{
    kfStarted =false;
    kfValidData = false;
    kfDt = 1.0/60.0;
    kfNoiseX = 0.0;
    kfNoiseY = 0.0;
    
    kfilter = [[FluxKalmanFilter alloc] init];
    stepcount = 0;
    _lastvalue =0;
    _resetThreshold = 10.0; //in meters;
    _validCurrentLocationData = -1;
    _validInitLocationData = -1;
    //[self testKalman];
}
- (void) startKFilter
{
    //[self testWGS84Conversions];
    kfilterTimer = [NSTimer scheduledTimerWithTimeInterval:kfDt
                                                    target:self
                                                  selector:@selector(updateKFilter)
                                                  userInfo:nil
                                                   repeats:YES];
    
    
}
- (void) setMeasurementWithLocation:(CLLocation*)location
{
    _kfMeasure.position.x = location.coordinate.latitude;
    _kfMeasure.position.y = location.coordinate.longitude;
    _kfMeasure.position.z = location.altitude;
    
    
    if(location.horizontalAccuracy >=0.0 && location.verticalAccuracy >= 0.0)
    {
        _validCurrentLocationData = 0;
        _validInitLocationData = 0;
        _horizontalAccuracy = location.horizontalAccuracy;
    }
    else
    {
        _validCurrentLocationData = -1;
    }
    
}



-(void) stopKFilter
{
    
}
-(void) resetKFilter
{
    _kfInit.position.x = _kfMeasure.position.x;
    _kfInit.position.y = _kfMeasure.position.y;
    _kfInit.position.z = _kfMeasure.position.z;
    
    kfStarted = true;
    [self computeKInitKFilter];
    [kfilter resetKalmanFilter];
}
-(void) updateKFilter
{
    //NSString *stepS = [NSString stringWithFormat:@"%d",stepcount];
    
    //[pedoLabel setText:stepS];
    
    if(kfStarted!=true)
    {
        if(_validCurrentLocationData <0)
        {
            NSLog(@"updateKFilter:Invalid location, kf not started");
            return;
        }
        _kfInit.position.x = _kfMeasure.position.x;
        _kfInit.position.y = _kfMeasure.position.y;
        _kfInit.position.z = _kfMeasure.position.z;
        
        kfStarted = true;
        [self computeKInitKFilter];
        //set pedometer count to zero
        
        return;
    }
    
    kfNoiseX = kfNoiseY = _horizontalAccuracy;
    
    [self computeKMeasureKFilter];
    
    [kfilter predictWithXDisp:kfXDisp YDisp:kfYDisp dT:kfDt];
    kfXDisp = 0.0;
    kfYDisp =0.0;
    [kfilter measurementUpdateWithZX:kfMeasureX ZY:kfMeasureY Rx:kfNoiseX Ry:kfNoiseY];
    [self computeFilteredECEF];
    [self computeEstimateDelta];
    
    //tests here for tangent plane
    
    //[self printDebugInfo];
    // [self ecefToWGS84KF];
}

- (int) computeTangentParametersForUserPose:(sensorPose *)usp toViewParameters:(viewParameters *)vp
{
    //    viewParameters viewP;
	GLKVector3 positionTP;
    positionTP = GLKVector3Make(0.0, 0.0, 0.0);
    
//    setParametersTP(usp->position);   // empty function
    
    [self WGS84_to_ECEF:usp];
    
//    tangentplaneRotation(usp);        // teM result not used here
    
    GLKVector3 zRay = GLKVector3Make(0.0, 0.0, -1.0);
    zRay = GLKVector3Normalize(zRay);
    
    GLKVector3 v = GLKMatrix4MultiplyVector3(usp->rotationMatrix, zRay);
    
    //NSLog(@"Projection vector: [%f, %f, %f]", v.x, v.y, v.z);
    
    GLKVector3 P0 = GLKVector3Make(0.0, 0.0, 0.0);
    GLKVector3 V = GLKVector3Normalize(v);
    
    (*vp).origin = GLKVector3Add(positionTP, P0);
    (*vp).at = V;
    (*vp).up = GLKMatrix4MultiplyVector3(usp->rotationMatrix, GLKVector3Make(0.0, 1.0, 0.0));
    
    return 0;
}


#pragma mark - test and debug filter

-(void) testWGS84Conversions
{
    int i =0;
    double lat[]={43.628342, 37.774930};
    double lon[] ={-79.394792,-122.419416};
    double alt[]={75,20};
    sensorPose s;
    Geolocation kfgeo;
    for(i=0; i<2; i++)
    {
        s.position.x = lat[i];
        s.position.y = lon[i];
        s.position.z = alt[i];
        
        [self WGS84_to_ECEF:&s];
        _kflocation.x = s.ecef.x;
        _kflocation.y = s.ecef.y;
        _kflocation.z = s.ecef.z;
        
        [self ComputeGeodecticFromkfECEF:&kfgeo];
        
        NSLog(@"[bef]aft lat:[ %f ] %f | lon:[ %f ] %f | alt:[ %f ] %f",lat[i], kfgeo.latitude, lon[i], kfgeo.longitude, alt[i], kfgeo.altitude);
      
    }
    
    
}

-(void) printDebugInfo
{
    /*
     double distancef;
     double tx, ty, tkx, tky;
     
     
     NSString *rawXS = [NSString stringWithFormat:@"RX: %f",kfMeasureX];
     [gpsX setText:rawXS];
     
     
     NSString *rawYS = [NSString stringWithFormat:@"RY: %f",kfMeasureY];
     [gpsY setText:rawYS];
     
     NSString *kXS = [NSString stringWithFormat:@"kX: %f",kfilter.positionX];
     [kX setText:kXS];
     
     NSString *kYS = [NSString stringWithFormat:@"kY: %f",kfilter.positionY];
     [kY setText:kYS];
     
     tkx = kfilter.positionX;
     tky = kfilter.positionY;
     tx = kfMeasureX - tkx;
     ty = kfMeasureY -tky;
     
     distancef = sqrt(tx*tx + ty*ty);
     
     NSString *distanceS = [NSString stringWithFormat:@"D: %f",distancef];
     [distance setText:distanceS];
     */
}
/*
- (void) testKalman
{
    double measX[] ={5.0, 5.0, 10.0, 20.0, 30.0};
    double measY[] ={0.0, 2.0, 4.0, 4.0, 6.0};
    
    int i;
    for(i =0; i <5; i++)
    {
        [kfilter predictWithXDisp:0.0 YDisp:0.0 dT:0.1];
        [kfilter measurementUpdateWithZX:measX[i] ZY:measY[i] Rx:0.0 Ry:0.0];
    }
    
}
*/
@end



