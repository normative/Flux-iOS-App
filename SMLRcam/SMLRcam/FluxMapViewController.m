//
//  FluxMapViewController.m
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMapViewController.h"

#define MERCATOR_RADIUS 85445659.44705395

NSString* const locationAnnotationIdentifer = @"locationAnnotation";
NSString* const userAnnotationIdentifer = @"userAnnotation";

@interface FluxMapViewController ()

- (int)   getZoomLevel;
- (float) getScale;

- (void) setupNetworkServiceManager;
- (void) setupLocationManager;
- (void) setupAnnotationView;
- (void) setupMapView;
- (void) setupStatusBarContent;

- (void) updateLoadingMessage: (NSTimer *)thisTimer;

- (void) setStatusBarLocationLabel:(NSNotification *)notification;
- (void) setStatusBarDateLabel;
- (void) setStatusBarMomentLabel;

- (void) setUserHeadingDirection;

@end

@implementation FluxMapViewController

@synthesize myViewOrientation;
@synthesize mapAnnotationsDictionary;

#pragma mark - getter methods

//
- (int)getZoomLevel
{
    return 21 - round(log2(myMapView.region.span.longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * myMapView.bounds.size.width)));
}

//
- (float)getScale
{
    return -1 * sqrt((double)(1 - pow(([self getZoomLevel]/20.0), 2.0))) + 1.1;
}

#pragma mark - setter methods

// set the user annotation heading direction as heading updating
- (void)setUserHeadingDirection
{
    if (userAnnotationView != nil)
    {
        double scale = [self getScale];
        userAnnotationView.transform = CGAffineTransformMakeScale(scale, scale);
        
        // heading direction to be improve
        CGAffineTransform transform = CGAffineTransformRotate(userAnnotationView.transform ,-(float)locationManager.heading*M_PI/180.0);
        userAnnotationView.transform = transform;
    }
}

// set status bar location label
- (void)setStatusBarLocationLabel:(NSNotification *)notification
{
    NSString *locationString = locationManager.subadministativearea;
    NSString *sublocality = locationManager.sublocality;
    
    if (sublocality.length > 0)
    {
        locationString = [NSString stringWithFormat:@"%@, %@", sublocality, locationString];
    }
    [statusBarCurrentLocalityLbl setText: locationString];
}

// set status bar date label
- (void)setStatusBarDateLabel
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"MMM dd, yyyy"];
    NSString *todayDateString = [dateFormat stringFromDate:[NSDate date]];
    [statusBarCurrentDateLbl setText:todayDateString];
}

// set status bar moment label
- (void)setStatusBarMomentLabel
{
    [statusBarCurrentMoment setText:@"0 Moment"];
}

#pragma mark - delegate methods

//
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    float scale = [self getScale];
    
    for (id <MKAnnotation>annotation in myMapView.annotations)
    {
        if ([annotation isKindOfClass:[MKUserLocation class]])
        {
            userAnnotationView.transform = CGAffineTransformMakeScale(scale, scale);
            [self setUserHeadingDirection];
        }
        else
        {
            MKAnnotationView *annotationView = [myMapView viewForAnnotation:annotation];
            annotationView.transform = CGAffineTransformMakeScale(scale, scale);
        }
    }
}

//
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[FluxScanImageObject class]])
    {
        MKAnnotationView *locationAnnotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:locationAnnotationIdentifer];
        
        if (locationAnnotationView == nil)
        {
            locationAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:locationAnnotationIdentifer];
            
            locationAnnotationView.enabled = YES;
            locationAnnotationView.canShowCallout = YES;
            locationAnnotationView.image = [UIImage imageNamed:@"locationPinWithRadius.png"];
        }
        else
        {
            locationAnnotationView.annotation = annotation;
        }
        
        return locationAnnotationView;
    }
    else if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        userAnnotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:userAnnotationIdentifer];

        if (userAnnotationView == nil)
        {
            userAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:userAnnotationIdentifer];
            userAnnotationView.image = [UIImage imageNamed:@"userPinWithRadius.png"];
            userAnnotationView.enabled = NO;
            
            NSLog(@"First time set user location annotation");
            double scale = [self getScale];
            userAnnotationView.transform = CGAffineTransformMakeScale(scale, scale);
        }
        else
        {
            userAnnotationView.annotation = annotation;
        }
        
        userLastSynchedLocation =  mapView.userLocation.coordinate;
        [self setUserHeadingDirection];
        return userAnnotationView;
    }
    
    return nil;
}

//
- (void)            mapView:(MKMapView *)mapView
  didChangeUserTrackingMode:(MKUserTrackingMode)mode
                   animated:(BOOL)animated
{
    [UIView transitionWithView:locateMeBtn duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL
     ];
    
    if (mode != MKUserTrackingModeFollow)
    {
        userAnnotationView.image = [UIImage imageNamed:@"userPin.png"];
        [locateMeBtn setHidden:NO];
    }
    else
    {
        double scale = [self getScale];
        userAnnotationView.image = [UIImage imageNamed:@"userPinWithRadius.png"];
        userAnnotationView.transform = CGAffineTransformMakeScale(scale, scale);
        [locateMeBtn setHidden:YES];
    }
}

//
-       (void) mapView:(MKMapView *)mapView
 didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (fabs(userLocation.location.coordinate.latitude - userLastSynchedLocation.latitude) > 25 ||
        fabs(userLocation.location.coordinate.longitude - userLastSynchedLocation.longitude) > 25 ||
        [mapAnnotationsDictionary count] == 0)
    {
        [networkServiceManager getImagesForLocation:userLocation.location.coordinate andRadius:50];
        
        userLastSynchedLocation.latitude = userLocation.location.coordinate.latitude;
        userLastSynchedLocation.longitude = userLocation.location.coordinate.longitude;
    }
}

// call back from the image request
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
     didreturnImageList:(NSMutableDictionary *)imageList
{
    for (id key in imageList)
    {
        if (![mapAnnotationsDictionary objectForKey:key])
        {
            FluxScanImageObject *locationObject = [imageList objectForKey:key];
            
            // add annotation to map
            [myMapView addAnnotation: locationObject];
            
            // insert object to dic
            [mapAnnotationsDictionary setObject:locationObject forKey:key];
        }
    }
}

#pragma mark - @selector

// animating loading message when it is currently unable to update the location label
- (void) updateLoadingMessage: (NSTimer *)thisTimer
{
    if ([statusBarCurrentLocalityLbl.text hasPrefix:@"Loading "])
    {
        // if statusBarCurrentLocalityLbl is less than the length of "Loading ...", append a "." at the end of the text
        if (statusBarCurrentLocalityLbl.text.length < 11)
        {
            [statusBarCurrentLocalityLbl setText:[NSString stringWithFormat:@"%@.", statusBarCurrentLocalityLbl.text]];
        }
        else
            [statusBarCurrentLocalityLbl setText:@"Loading "];
    }
    else
    {
        [thisTimer invalidate];
        thisTimer = nil;
    }
}

#pragma mark - initialize and allocate objects

// initial and allocate memory to the network service manager
- (void)setupNetworkServiceManager
{
    networkServiceManager = [[FluxNetworkServices alloc] init];
    [networkServiceManager setDelegate:self];
}

// initialize and allocate memory to the location manager object and register for nsnotification service
- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
    
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStatusBarLocationLabel:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUserHeadingDirection) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
    }
}

- (void) setupAnnotationView
{
    NSLog(@"map annotaiton dictionary count is %i", [mapAnnotationsDictionary count]);
    for (id key in mapAnnotationsDictionary)
    {
        FluxScanImageObject *locationObject = [mapAnnotationsDictionary objectForKey:key];
            
        // add annotation to map
        [myMapView addAnnotation: locationObject];
            
        // insert object to dic
        [mapAnnotationsDictionary setObject:locationObject forKey:key];
    }
}

// initialize and allocate memory to the map view object
- (void) setupMapView
{
    [myMapView setMapType:MKMapTypeStandard];
    [myMapView setDelegate:self];
    [myMapView setShowsUserLocation:YES];
    [myMapView setUserTrackingMode:MKUserTrackingModeFollow];
    
    NSLog(@"default latitude Delta");
    NSLog(@"longitudeDelta %f",myMapView.region.span.latitudeDelta);
    NSLog(@"longitudeDelta %f",myMapView.region.span.longitudeDelta);
    
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(myMapView.userLocation.coordinate, 0.01, 0.01);
    
    [myMapView setRegion:viewRegion animated:YES];
    NSLog(@"after adding region");
    NSLog(@"longitudeDelta %f",myMapView.region.span.latitudeDelta);
    NSLog(@"longitudeDelta %f",myMapView.region.span.longitudeDelta);
}

// setting the status bar content
- (void) setupStatusBarContent
{
    // assign text to locality label
    // Check to see if either any location text already exists. Otherwise display loading prompt.
    NSString *locationString = locationManager.subadministativearea;
    NSString *sublocality = locationManager.sublocality;
    if ((sublocality.length > 0) || (locationString.length > 0))
    {
        [self setStatusBarLocationLabel:nil];
    }
    else
    {
        [statusBarCurrentLocalityLbl setText:@"Loading "];
        [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(updateLoadingMessage:)
                                       userInfo: nil repeats: YES];
    }
    
    // assign text to date label
    [self setStatusBarDateLabel];
    
    // assign text to moment label
    [self setStatusBarMomentLabel];
}

#pragma mark - IBActions

//
- (IBAction)onLocateMeBtn:(id)sender
{
    if ([myMapView userTrackingMode] != MKUserTrackingModeFollow)
    {
        [myMapView setUserTrackingMode:MKUserTrackingModeFollow];
        [self setUserHeadingDirection];
    }
}

// IBAction for exiting the map view
- (IBAction)onExitMapBtn:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
    }];
}

#pragma mark - rotation and orientations

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return myViewOrientation ? myViewOrientation : UIInterfaceOrientationLandscapeRight;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
    {
        [self dismissViewControllerAnimated:YES completion:^(void)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
            //[myMapView setDelegate:nil];
        }];
    }
}

#pragma mark - view lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    myLocationPinImageview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userPinWithRadius.png"]];
    
    userLastSynchedLocation.latitude = -1;
    userLastSynchedLocation.longitude = -1;
    
    mapAnnotationsDictionary = [[NSMutableDictionary alloc] init];
    [locateMeBtn setHidden:YES];
    
    [self setupLocationManager];
    [self setupMapView];
    [self setupStatusBarContent];
    [self setupAnnotationView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
