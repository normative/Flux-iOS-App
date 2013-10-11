//
//  FluxMapViewController.m
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMapViewController.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#define MERCATOR_RADIUS 85445659.44705395

NSString* const locationAnnotationIdentifer = @"locationAnnotation";
NSString* const userAnnotationIdentifer = @"userAnnotation";

@interface FluxMapViewController ()

- (int)   getZoomLevel;
- (float) getScale;

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gesture;

- (void) setupPinchGesture;
- (void) setupLocationManager;
- (void) setupMapView;

@end

@implementation FluxMapViewController

@synthesize myViewOrientation;

#pragma mark - Callbacks


#pragma mark MapKit

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
//    if (![view isKindOfClass:[MKUserLocation class]])
//    {
//        FluxScanImageObject* annotation = (FluxScanImageObject *)view.annotation;
//        
//        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
//        [dataRequest setRequestedIDs:[NSArray arrayWithObject:annotation.localID]];
//        [dataRequest setImageReady:^(FluxLocalID *localID, UIImage *image, FluxDataRequest *completedDataRequest){
//            for (FluxScanImageObject *curAnnotation in mapView.annotations)
//            {
//                if ([curAnnotation isKindOfClass: [FluxScanImageObject class]])
//                {
//                    if (curAnnotation.localID == localID)
//                    {
//                        MKAnnotationView *annotationView = [mapView viewForAnnotation:curAnnotation];
//                        UIImageView *calloutImageView = [[UIImageView alloc] initWithImage:image];
//                        annotationView.leftCalloutAccessoryView = calloutImageView;
//                        
//                        [activityIndicator stopAnimating];
//                        break;
//                    }
//                }
//            }
//        }];
//        [self.fluxDisplayManager.fluxDataManager requestImagesByLocalID:dataRequest withSize:thumb];
//    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
//    if (![view isKindOfClass:[MKUserLocation class]] && [activityIndicator isAnimating])
//    {
//        [activityIndicator stopAnimating];
//    }
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
            locationAnnotationView.image = [UIImage imageNamed:@"locationPin.png"];

            // Just show the activity indicator for now. Don't both checking cache.
            // When a user clicks on it, then we can initiate the request.
        }
        else
        {
            locationAnnotationView.annotation = annotation;
        }
        
        return locationAnnotationView;
    }
    return nil;
}

// show locateMeBtn when user tracking mode changed to not follow
- (void) mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    [UIView transitionWithView:locateMeBtn duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL
     ];
    
    if (mode != MKUserTrackingModeFollow)
    {
        [locateMeBtn setHidden:NO];
    }
    else
    {
        [locateMeBtn setHidden:YES];
    }
}

const float minmovedist = 0.00025;     // approx 25m (little more, little less, best around about 43deg lat)

// make a network update call when user has moved a certain distance
- (void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
#warning Need to improve this logic. Will not request updates unless we move. This misses new points.
// Since this is a delegate of MapView's location updates, the tolerance settings are different.
// We don't get nearly as many updates, and it only updates if location/heading changes.
    if ((userLastSynchedLocation.latitude == -1 && userLastSynchedLocation.longitude == -1) ||
        fabs(userLocation.location.coordinate.latitude - userLastSynchedLocation.latitude) > minmovedist ||
        fabs(userLocation.location.coordinate.longitude - userLastSynchedLocation.longitude) > minmovedist)
    {
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setNearbyListReady:^(NSArray *nearbyList){
            // Need to update all metadata objects even if they exist (in case they change in the future)
            for (FluxScanImageObject *locationObject in nearbyList)
            {
                // add annotation to map
                [mapView addAnnotation: locationObject];
            }
        }];
        [self.fluxDisplayManager.fluxDataManager requestImageListAtLocation:userLocation.location.coordinate
                                              withRadius:50 withDataRequest:dataRequest];
        
        userLastSynchedLocation.latitude = userLocation.location.coordinate.latitude;
        userLastSynchedLocation.longitude = userLocation.location.coordinate.longitude;
    }
    
    [self setStatusBarLocationLabel:nil];
    
}

#pragma mark Gesture Recognizers

// only allow pinch gesture recognizer
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])
    {
        return YES;
    }
    return NO;
}

// handle pinch gesture call
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gesture
{
    float scale = [self getScale];
    
    for (id <MKAnnotation>annotation in fluxMapView.annotations)
    {
        MKAnnotationView *annotationView = [fluxMapView viewForAnnotation:annotation];
        annotationView.transform = CGAffineTransformMakeScale(scale, scale);
    }
}



#pragma mark - getter methods

// get current map zoom level
- (int)getZoomLevel
{
    return 21 - round(log2(fluxMapView.region.span.longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * fluxMapView.bounds.size.width)));
}

// return proper scale size for the annotations in the map view
- (float)getScale
{
    return -1 * sqrt((double)(1 - pow(([self getZoomLevel]/20.0), 2.0))) + 1.1;
}

#pragma mark - setter methods

// set status bar location label
- (void)setStatusBarLocationLabel:(NSNotification *)notification
{
    NSString *locationString = locationManager.subadministativearea;
    NSString *sublocality = locationManager.sublocality;
    
    if (sublocality.length > 0)
    {
        locationString = [NSString stringWithFormat:@"%@, %@", sublocality, locationString];
    }
}

#pragma mark - initialize view

// register pinch gesture recognizer callback
- (void)setupPinchGesture
{
    pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [pinchRecognizer setDelegate:self];
    
    [self.view addGestureRecognizer:pinchRecognizer];
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

// initialize and allocate memory to the map view object
- (void) setupMapView
{
    [fluxMapView setMapType:MKMapTypeStandard];
    [fluxMapView setDelegate:self];
    [fluxMapView setShowsUserLocation:YES];
    [fluxMapView setUserTrackingMode:MKUserTrackingModeFollow];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(fluxMapView.userLocation.coordinate, 50, 50);
    MKCoordinateRegion adjustedRegion = [fluxMapView regionThatFits:viewRegion];
    [fluxMapView setRegion:adjustedRegion animated:YES];
    
    //[mapView setRegion:viewRegion animated:YES];
    CLLocationCoordinate2D eye = CLLocationCoordinate2DMake(fluxMapView.userLocation.coordinate.latitude-0.01, fluxMapView.userLocation.coordinate.longitude);
    mapCamera = [MKMapCamera cameraLookingAtCenterCoordinate:fluxMapView.userLocation.coordinate fromEyeCoordinate:eye eyeAltitude:1000];
    if (fluxMapView.pitchEnabled) {
        [fluxMapView setCamera:mapCamera];
    }
}
#pragma mark - IBActions

// switch user tracking mode to MKUserTrackingModeFollow
- (IBAction)onLocateMeBtn:(id)sender
{
    if ([fluxMapView userTrackingMode] != MKUserTrackingModeFollow)
    {
        [fluxMapView setUserTrackingMode:MKUserTrackingModeFollow];
    }
}

- (IBAction)closeButtonAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^(void)
     {
         [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
         [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
         
         [self.view removeGestureRecognizer:pinchRecognizer];
         
         [EAGLContext setCurrentContext:nil];
     }];
}

#pragma mark - view lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        ;
        
    }
    return self;
}

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
 
    userLastSynchedLocation.latitude = -1;
    userLastSynchedLocation.longitude = -1;
    
    [locateMeBtn setHidden:YES];
    
    [self setupPinchGesture];
    [self setupLocationManager];
    
    [self setupMapView];
}

- (void)viewWillAppear:(BOOL)animated{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Map View"];
    
    // manual screen tracking
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
