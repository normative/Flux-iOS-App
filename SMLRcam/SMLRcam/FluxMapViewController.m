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
- (void) setupStatusBarContent;

- (void) updateLoadingMessage: (NSTimer *)thisTimer;

- (void) setStatusBarLocationLabel:(NSNotification *)notification;
- (void) setStatusBarDateLabel;
- (void) setStatusBarMomentLabel;

@end

@implementation FluxMapViewController

@synthesize myViewOrientation;

#pragma mark - set label

// set status bar location label
- (void) setStatusBarLocationLabel:(NSNotification *)notification
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
- (void) setStatusBarDateLabel
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"MMM dd, yyyy"];
    NSString *todayDateString = [dateFormat stringFromDate:[NSDate date]];
    [statusBarCurrentDateLbl setText:todayDateString];
}

// set status bar moment label
- (void) setStatusBarMomentLabel
{
    [statusBarCurrentMoment setText:@"0 Moment"];
}

#pragma mark - @selector

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

// initialize and allocate memory to the location manager object and register for nsnotification service
- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
    
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStatusBarLocationLabel:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
    }
}

// initialize and allocate memory to the map view object
- (void) setupMapView
{
    [myMapView setMapType:MKMapTypeStandard];
    [myMapView setShowsUserLocation:YES];
    [myMapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(myMapView.userLocation.coordinate, 0.5, 0.5);
    [myMapView setRegion:viewRegion animated:YES];
}

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

// IBAction for exiting the map view
- (IBAction) exitMapView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
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
    
    [self setupLocationManager];
    [self setupMapView];
    [self setupStatusBarContent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
