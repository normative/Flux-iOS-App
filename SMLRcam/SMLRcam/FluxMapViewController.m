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

- (void) setStatusBarLocationLabel:(NSString*)locationString;
- (void) setStatusBarDateLabel;

- (void) reverseGeocodeLocation:(CLLocation*)thelocation;

@end

@implementation FluxMapViewController

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
            [self setStatusBarLocationLabel: locationString];
            
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
    [self reverseGeocodeLocation:userLocation.location];
}

#pragma mark - set label
#pragma mark - set location label
- (void) setStatusBarLocationLabel: (NSString*) locationString
{
    [currentLocalityLbl setText: locationString];
}

#pragma mark - set date label
- (void) setStatusBarDateLabel
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"MMM dd, yyyy"];
    NSString *todayDateString = [dateFormat stringFromDate:[NSDate date]];
    [currentDateLbl setText: todayDateString];
}

#pragma mark - initialize and allocate objects
#pragma mark - location manage config
//allocates the location object and sets some parameters
- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
}

#pragma mark - mapview config
- (void) setupMapView
{
    [mapView setMapType: MKMapTypeStandard];
    [mapView setShowsUserLocation: YES];
    [mapView setUserTrackingMode: MKUserTrackingModeFollowWithHeading];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(locationManager.location.coordinate, 0.5, 0.5);
    
    [mapView setRegion:viewRegion animated:YES];
    [mapView setDelegate:self];
}

#pragma mark - IBActions
#pragma mark - Back button
- (IBAction) exitMapView:(id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - rotation and orientations
-(BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark - viewcontroller methods
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
