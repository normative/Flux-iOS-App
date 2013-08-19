//
//  FluxMapViewController.m
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMapViewController.h"

@interface FluxMapViewController ()

- (void) setupMapView;

- (void) setStatusBarLocationLabel:(NSString*)locationString;
- (void) setStatusBarDateLabel;

- (void) reverseGeocodeLocation:(CLLocation*)thelocation;

@end

@implementation FluxMapViewController

@synthesize myViewOrientation;

#pragma mark - additional functions
#pragma mark - get location info
- (void)reverseGeocodeLocation:(CLLocation*)thelocation
{
    theGeocoder = [[CLGeocoder alloc] init];
    [theGeocoder reverseGeocodeLocation:thelocation completionHandler:^(NSArray *placemarks, NSError *error){
        if (error){
            
            if (error.code == kCLErrorNetwork || (error.code == kCLErrorGeocodeFoundPartialResult)) {
                
                NSLog(@"Error - No internet connection for reverse geolocation");
            } else {
                
                NSLog(@"Error Reverse Geolocating: %@", [error localizedDescription]);
            }
        } else {
            
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            NSString * locationString = [placemark.addressDictionary valueForKey:@"SubLocality"];
            locationString = [locationString stringByAppendingString:[NSString stringWithFormat:@", %@", [placemark.addressDictionary valueForKey:@"SubAdministrativeArea"]]];
            [self setStatusBarLocationLabel:locationString];
            
            NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
            NSLog(@"User current address - %@",locatedAt);
            
            locatedAt = [placemark.addressDictionary valueForKey:@"SubLocality"];
            NSLog(@"User current subLocality - %@",locatedAt);
            
            NSLog(@"User current address description - %@", [placemark.addressDictionary description]);
        }
    }];
}

#pragma mark - delegate methods
#pragma mark - mapView delegate methods
- (void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (userLocation.location.horizontalAccuracy > 0) {
        
        [self reverseGeocodeLocation:userLocation.location];
    }
}

#pragma mark - set label
#pragma mark - set location label
- (void) setStatusBarLocationLabel:(NSString*) locationString
{
    [statusBarcurrentLocalityLbl setText:locationString];
}

#pragma mark - set date label
- (void) setStatusBarDateLabel
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"MMM dd, yyyy"];
    NSString *todayDateString = [dateFormat stringFromDate:[NSDate date]];
    [statusBarcurrentDateLbl setText:todayDateString];
}

#pragma mark - initialize and allocate objects

#pragma mark - mapview config
- (void) setupMapView
{
    [myMapView setMapType:MKMapTypeStandard];
    [myMapView setShowsUserLocation:YES];
    [myMapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(myMapView.userLocation.coordinate, 0.5, 0.5);
    [myMapView setRegion:viewRegion animated:YES];
    [myMapView setDelegate:self];
}

#pragma mark - IBActions
#pragma mark - Back button
- (IBAction) exitMapView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void) {
        //[mapView setUserTrackingMode:MKUserTrackingModeNone];
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
    
    locationManager = [FluxLocationServicesSingleton sharedManager];
    [self setupMapView];
    
    [self setStatusBarDateLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
