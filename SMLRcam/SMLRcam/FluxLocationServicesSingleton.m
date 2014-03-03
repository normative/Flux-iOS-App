//
//  FluxLocationServicesSingleton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-08.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxLocationServicesSingleton.h"
#import "FluxDebugViewController.h"
#import "UIAlertView+Blocks.h"
#import "FluxMotionManagerSingleton.h"

NSString* const FluxLocationServicesSingletonDidChangeKalmanFilterState = @"FluxLocationServicesSingletonDidChangeKalmanFilterState";
NSString* const FluxLocationServicesSingletonDidResetKalmanFilter = @"FluxLocationServicesSingletonDidResetKalmanFilter";
NSString* const FluxLocationServicesSingletonDidUpdateLocation = @"FluxLocationServicesSingletonDidUpdateLocation";
NSString* const FluxLocationServicesSingletonDidUpdateHeading = @"FluxLocationServicesSingletonDidUpdateHeading";
NSString* const FluxLocationServicesSingletonDidUpdatePlacemark = @"FluxLocationServicesSingletonDidUpdatePlacemark";

#define PI M_PI
#define a_WGS84 6378137.0
#define b_WGS84 6356752.3142

const float maxUpdateTime = 5.0;    // wait maximum of 5s before forcing a location update notification

const double kalmanFilterMinHeadingAccuracy = 30.0;
const double kalmanFilterMinHorizontalAccuracy = 20.0;
const double kalmanFilterMinVerticalAccuracy = 20.0;

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
        self.locationManager = [[CLLocationManager alloc] init];
        if (self.locationManager == nil)
        {
            return nil;
        }
        self.locationManager.delegate = self;
        
        // This is the most important property to set for the manager. It ultimately determines how the manager will
        // attempt to acquire location and thus, the amount of power that will be consumed.
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        
        // When "tracking" the user, the distance filter can be used to control the frequency with which location measurements
        // are delivered by the manager. If the change in distance is less than the filter, a location will not be delivered.
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        
        // This will drain battery faster, but for now, we want to make sure that we continue to get frequent updates
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
        
        if ([CLLocationManager headingAvailable]) {
            self.locationManager.headingFilter = 1.0;
        }
        
        [self loadTeleportLocationIndex];
        
        [self setupLogger];
    }
    
    [self initKFilter];
    [self startKFilter];
    
    return self;
}

- (void)setupLogger
{
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    
    [DDLog addLogger:fileLogger];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDLogVerbose(@"Logging is setup (\"%@\")", [fileLogger.logFileManager logsDirectory]);
}

- (void)startLocating
{
    NSLog(@"Location Services Status:%u",CLLocationManager.authorizationStatus);
    
    if (CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorized){
        [self beginLocatingAfterPermissions];
    }

    else if (CLLocationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome.", nil) message:@"Flux needs to know your location to place images, and find images around the world. Your location is never shared to anyone outside Flux." delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok, I get It", nil) otherButtonTitles: nil];
        [alert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [self beginLocatingAfterPermissions];
        }];
    }
    else if (CLLocationManager.authorizationStatus == kCLAuthorizationStatusDenied || CLLocationManager.authorizationStatus == kCLAuthorizationStatusRestricted){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Uh oh...", nil) message:@"Location services is disabled for Flux. Go to the Settings app and enable location services for Flux." delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
        [alert show];
    }
    //won't ever hit
    else{
        
    }
}

- (void)beginLocatingAfterPermissions{
    [self.locationManager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadTeleportLocationIndex) name:FluxDebugDidChangeTeleportLocationIndex object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeHeadingCorrectedMotionMode) name:FluxDebugDidChangeHeadingCorrectedMotion object:nil];

    if ([CLLocationManager headingAvailable]) {
        [self.locationManager startUpdatingHeading];
    }
    else {
        NSLog(@"No Heading Information Available");
    }
    
    [self changeHeadingCorrectedMotionMode];
    
    [self startUpdateTimer];
}

- (void)endLocating
{
    [self.locationManager stopUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDebugDidChangeTeleportLocationIndex object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDebugDidChangeHeadingCorrectedMotion object:nil];
    
    if ([CLLocationManager headingAvailable]) {
        [self.locationManager stopUpdatingHeading];
    }
    
    if (updateTimer != nil)
    {
        [updateTimer invalidate];
        updateTimer = nil;
    }
}

- (void)updateUserPose
{
    sensorPose localUserPose;
    
    FluxMotionManagerSingleton *fluxMotionManager = [FluxMotionManagerSingleton sharedManager];

    CMQuaternion att = fluxMotionManager.attitude;
    
    GLKQuaternion quat = GLKQuaternionMake(att.x, att.y, att.z, att.w);
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

- (CLLocationDirection)orientationHeading
{
    CLLocationDirection newHeading = 0.0;
    
    @try
    {
        newHeading = self.heading;
        [self updateUserPose];
        sensorPose localUserPose = _userPose;
        
        viewParameters localUserVp;
        
        // calculate angle between user's viewpoint and North
        [self computeTangentParametersForUserPose:&localUserPose toViewParameters:&localUserVp];
        
        
        double x1 = 0.0;
        double y1 = 1.0;
        double x2 = localUserVp.at.x;
        double y2 = localUserVp.at.y;
        if (!(isnan(x2) || isnan(y2)))
        {
            double dotx = (x1 * x2);
            double doty = (y1 * y2);
            
            double scalar = dotx + doty;
            double magsq1 = x1 * x1 + y1 * y1;
            double magsq2 = x2 * x2 + y2 * y2;
            
            if (magsq2 != 0.0)
            {
                // won't freak out and will return a valid result
                double costheta = (scalar) / sqrt(magsq1 * magsq2);
                double theta = acos(costheta) * 180.0 / M_PI;
                
                if (x2 < 0)
                {
                    theta = -theta;
                }
                
                while (theta < 0.0)
                    theta += 360.0;
                
                if (!isnan(theta))
                    newHeading = theta;
            }
        }
    }
    @catch (NSException *theException)
    {
        NSLog(@"An exception occurred: %@", theException.name);
        NSLog(@"Here are some details: %@", theException.reason);
    }

    return newHeading;
}

- (void) startUpdateTimer
{
    if (updateTimer != nil)
        [updateTimer invalidate];
    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:maxUpdateTime
                                                   target:self
                                                 selector:@selector(notifyLocationUpdate)
                                                 userInfo:nil
                                                  repeats:NO];
}

- (void)notifyLocationUpdate
{
    [self startUpdateTimer];

    // Notify observers of updated position
    if (self.location != nil)
    {
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:self.location forKey:@"location"];
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidUpdateLocation object:self userInfo:userInfo];
    }
}

- (void)changeHeadingCorrectedMotionMode
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool headingCorrectedMotion = [[defaults objectForKey:FluxDebugHeadingCorrectedMotionKey] boolValue];
    
    FluxMotionManagerSingleton *fluxMotionManager = [FluxMotionManagerSingleton sharedManager];
    [fluxMotionManager changeHeadingCorrectedMotionMode:headingCorrectedMotion];
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
    
    if (1 == self.teleportLocationIndex)
    {
        // Note, location of "1" is the current location. Leave data unaffected.
    }
    else if (2 == self.teleportLocationIndex)
    {
        CLLocationCoordinate2D fakecoord = CLLocationCoordinate2DMake(43.65337, -79.40658);     // Normative Office Location
        newLocation = [[CLLocation alloc] initWithCoordinate:fakecoord altitude:118.0
                                          horizontalAccuracy:newLocation.horizontalAccuracy verticalAccuracy:newLocation.verticalAccuracy
                                                      course:newLocation.course speed:newLocation.speed timestamp:newLocation.timestamp];
    }
    else if (3 == self.teleportLocationIndex)
    {
        CLLocationCoordinate2D fakecoord = CLLocationCoordinate2DMake(63.75, -68.53);     // Middle of Nowhere Location
        newLocation = [[CLLocation alloc] initWithCoordinate:fakecoord altitude:0.0
                                          horizontalAccuracy:newLocation.horizontalAccuracy verticalAccuracy:newLocation.verticalAccuracy
                                                      course:newLocation.course speed:newLocation.speed timestamp:newLocation.timestamp];
    }
    else if (4 == self.teleportLocationIndex)
    {
        CLLocationCoordinate2D fakecoord = CLLocationCoordinate2DMake(0.0, 0.0);     // (0,0) location - boundary condition
        newLocation = [[CLLocation alloc] initWithCoordinate:fakecoord altitude:0.0
                                          horizontalAccuracy:newLocation.horizontalAccuracy verticalAccuracy:newLocation.verticalAccuracy
                                                      course:newLocation.course speed:newLocation.speed timestamp:newLocation.timestamp];
    }
    
    self.rawlocation = newLocation;
    
    //NSLog(@"Saved lat/long: %0.15f, %0.15f", self.location.coordinate.latitude,
    //      self.location.coordinate.longitude);
    
    [self updateAltitudeWithAlt:newLocation.altitude andError:newLocation.verticalAccuracy];
    
    
    [self setMeasurementWithLocation:newLocation];
    [self ComputeGeodecticFromkfECEF:&kfgeolocation];
    
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(kfgeolocation.latitude, kfgeolocation.longitude);
      newLocation = [[CLLocation alloc] initWithCoordinate:coord altitude:kfgeolocation.altitude
                                          horizontalAccuracy:newLocation.horizontalAccuracy verticalAccuracy:newLocation.verticalAccuracy
                                          course:newLocation.course speed:newLocation.speed timestamp:newLocation.timestamp];
    
    DDLogVerbose(@"loc: %.8f, %.8f, alt: %.6f, h_acc: %.2f, v_acc: %.2f, head: %.2f, loc_kal: %.8f, %.8f, alt_kal: %.6f",
                 self.rawlocation.coordinate.latitude, self.rawlocation.coordinate.longitude, self.rawlocation.altitude,
                 self.rawlocation.horizontalAccuracy, self.rawlocation.verticalAccuracy, self.heading,
                 newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.altitude);
    
    if (isnan(newLocation.coordinate.latitude) || isnan(newLocation.coordinate.longitude))
    {
        self.location = self.rawlocation;
    }
    else
    {
        self.location = newLocation;
    }
    
    [self updateUserPose];
    
    [self notifyLocationUpdate];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (newHeading.headingAccuracy < 0)
        return;
    
    // Use the true heading if it is valid.
    self.heading = ((newHeading.trueHeading >= 0) ? newHeading.trueHeading : newHeading.magneticHeading);
    
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
    kfgeolocation->altitude  = X_alt;
    
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


 
- (void)registerPedDisplacementKFilter:(int)direction
{
    NSLog(@"disp registered");
    
    stepcount++;
    double enuHeadingRad;
    double stepsize =0.73;
    
    enuHeadingRad = (90.0 + (360 - ((direction == -1) ? self.heading + 180.0 : self.heading)))/180.0 * PI;
    
    DDLogVerbose(@"#Event: STEP step_size %.2f, direction %.2f, raw_heading: %.2f, lat: %.8f, long: %.8f msg: direction flag %d", stepsize, enuHeadingRad*180.0/PI, self.heading,
                 self.location.coordinate.latitude, self.location.coordinate.longitude, direction);

    kfXDisp = stepsize * cos(enuHeadingRad);
    kfYDisp = stepsize * sin(enuHeadingRad);
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
    _validCurrentLocationData = NO;
    //[self testKalman];
    kfAltStarted = false;
    iterations_alt = 0;
    P_alt = 5.0;
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
    _kfMeasure.position.z = X_alt;
    
    
    // Check for state changes in validCurrentLocationData. Toggles to true are caught in updateKFilter and resetKFilter.
    if((location.horizontalAccuracy >=0.0) && (location.horizontalAccuracy <= kalmanFilterMinHorizontalAccuracy) &&
       (location.verticalAccuracy >= 0.0) && (location.verticalAccuracy <= kalmanFilterMinVerticalAccuracy) &&
       (self.locationManager.heading.headingAccuracy >= 0.0) && (self.locationManager.heading.headingAccuracy <= kalmanFilterMinHeadingAccuracy) &&
       (self.locationManager.heading.trueHeading >= 0))
    {
        // if kfStarted is false, we haven't started yet, so state changes are handled elsewhere.
        // Otherwise, handle them here.
        if (kfStarted && !_validCurrentLocationData)
        {
            // This is the case where it was already initialized, but the location data temporarily became bad.
            // Need to notify state change now that location data is good again.
            _validCurrentLocationData = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidChangeKalmanFilterState object:self];
        }
        _validCurrentLocationData = YES;
        _horizontalAccuracy = location.horizontalAccuracy;
    }
    else
    {
        // Bad location information. Kalman state will be reported as disabled until we get good data again.
        // Notify observers of state change.
        if (_validCurrentLocationData)
        {
            _validCurrentLocationData = NO;

            // Previous value was valid. Signal state change.
            [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidChangeKalmanFilterState object:self];
        }
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
    
    DDLogVerbose(@"#Event: RESET lat: %.8f, long: %.8f, msg: Kalman filter reset as a result of large delta between measurement and estimate.",
                 self.location.coordinate.latitude, self.location.coordinate.longitude);

    // Post notification of Kalman reset
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidResetKalmanFilter object:self];
    
    // Since already intiialized, now post notification of Kalman init
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidChangeKalmanFilterState object:self];

}

-(void) updateKFilter
{
    //NSString *stepS = [NSString stringWithFormat:@"%d",stepcount];
    
    //[pedoLabel setText:stepS];
    
    if(kfStarted!=true)
    {
        if(!_validCurrentLocationData)
        {
            //NSLog(@"updateKFilter:Invalid location, kf not started");
            return;
        }
        _kfInit.position.x = _kfMeasure.position.x;
        _kfInit.position.y = _kfMeasure.position.y;
        _kfInit.position.z = _kfMeasure.position.z;
        
        kfStarted = true;
        [self computeKInitKFilter];
        //set pedometer count to zero
        
        // Post notification of Kalman initialization (now safe to use)
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxLocationServicesSingletonDidChangeKalmanFilterState object:self];
        
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

- (bool)isKalmanSolutionValid
{
    return kfStarted && _validCurrentLocationData;
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

- (void) loadTeleportLocationIndex
{
    // Stored as a string (starting at 1). Mapping of locations to use.
    // 1 - Current location (default)
    // 2 - Normative (lots of content)
    // 3 - Location with no content
    // 4 - Location (0,0) - special case condition
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.teleportLocationIndex = [[defaults objectForKey:FluxDebugTeleportLocationIndexKey] integerValue];
}


-(void) updateAltitudeWithAlt:(double)altitude andError:(double)error
{
    double X_x;
    double P_p;
    double Q = 0.00001;
    double K;
    double R = error;
    double z = altitude;
    
    
    while(iterations_alt <5)
    {
        X_alt = altitude;
        iterations_alt++;
        return;
    }
    
    
    X_x = X_alt;
    P_p = P_alt + Q;
    
    K = P_p / (P_p +R);
    X_alt = X_x + K *(z -X_x);
    P_alt = (1-K) * P_p;
    
    kfAltStarted = true;
}
@end



