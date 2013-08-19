//
//  FluxMapViewController.m
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMapViewController.h"

@interface FluxMapViewController ()

- (void) setupLocationManager;
- (void) setupMapView;

- (void) setStatusBarLocationLabel:(NSNotification *)notification;
- (void) setStatusBarDateLabel;

@end

@implementation FluxMapViewController

@synthesize myViewOrientation;

#pragma mark - set label

// set status bar location label
- (void) setStatusBarLocationLabel:(NSNotification *)notification
{
    NSDictionary *userInfoDict = [notification userInfo];
    if (userInfoDict != nil) {
        CLPlacemark *placemark = [userInfoDict objectForKey:FluxLocationServicesSingletonKeyPlacemark];
        NSString * locationString = [placemark.addressDictionary valueForKey:@"SubLocality"];
        locationString = [locationString stringByAppendingString:[NSString stringWithFormat:@", %@", [placemark.addressDictionary valueForKey:@"SubAdministrativeArea"]]];
        statusBarcurrentLocalityLbl.text = locationString;
    }
}

// set status bar date label
- (void) setStatusBarDateLabel
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"MMM dd, yyyy"];
    NSString *todayDateString = [dateFormat stringFromDate:[NSDate date]];
    [statusBarcurrentDateLbl setText:todayDateString];
}

#pragma mark - initialize and allocate objects

// initialize and allocate memory to the location manager object and register for nsnotification service
- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
    
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStatusBarLocationLabel:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
    }
    [locationManager startLocating];
}

#pragma mark - mapview config

// initialize and allocate memory to the map view object
- (void) setupMapView
{
    [myMapView setMapType:MKMapTypeStandard];
    [myMapView setShowsUserLocation:YES];
    [myMapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(myMapView.userLocation.coordinate, 0.5, 0.5);
    [myMapView setRegion:viewRegion animated:YES];
}

#pragma mark - IBActions

// IBAction for exiting the map view
- (IBAction) exitMapView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void) {
        
        [myMapView setDelegate:nil];
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
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        
        [self dismissViewControllerAnimated:YES completion:^(void) {
            //[mapView setUserTrackingMode:MKUserTrackingModeNone];
            [myMapView setDelegate:nil];
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
    
    [self setupLocationManager];
    [self setupMapView];
    
    [self setStatusBarDateLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
