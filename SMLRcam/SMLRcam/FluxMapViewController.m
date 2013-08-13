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
- (void)reverseGeocodeLocation:(CLLocation*)thelocation;

@end

@implementation FluxMapViewController

-(BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void) setupMapView
{
    [mapView setMapType: MKMapTypeStandard];
    [mapView setShowsUserLocation:YES];
    [mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
    
    MKCoordinateRegion region = { {0.0, 0.0 }, { 0.0, 0.0 } };
    region.span.longitudeDelta = 0.005;
    region.span.latitudeDelta = 0.005;
    [mapView setRegion:region animated:YES];
    [mapView setDelegate:self];
}

#pragma mark Location/Orientation Init
//allocates the location object and sets some parameters
- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
    [locationManager setDelegate:self];
    
    if (locationManager.location != nil) {
        [self LocationManager:locationManager didUpdateLocation:locationManager.location];
    }
}

- (void)startUpdatingLocationAndHeading
{
    [locationManager startLocating];
}

#pragma mark - location geocoding
- (void)reverseGeocodeLocation:(CLLocation*)thelocation
{
    theGeocoder = [[CLGeocoder alloc] init];
    
    [theGeocoder reverseGeocodeLocation:thelocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error)
        {
            if (error.code == kCLErrorNetwork || (error.code == kCLErrorGeocodeFoundPartialResult))
            {
                NSLog(@"No internet connection for reverse geolocation");
                //Alert(@"No Internet connection!");
            }
            else
                NSLog(@"Error Reverse Geolocating: %@", [error localizedDescription]);
        }
        else
        {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            NSString * locationString = [placemark.addressDictionary valueForKey:@"SubLocality"];
            locationString = [locationString stringByAppendingString:[NSString stringWithFormat:@", %@", [placemark.addressDictionary valueForKey:@"SubAdministrativeArea"]]];
            locationLabel.text = [NSString stringWithFormat: @"Central %@", locationString];
            
            NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
            NSLog(@"I am currently at Address %@",locatedAt);
            
            locatedAt = [placemark.addressDictionary valueForKey:@"SubLocality"];
            NSLog(@"I am currently at SubLocality %@",locatedAt);
            
            NSLog(@"%@", [placemark.addressDictionary description]);
        }
    }];
}

#pragma mark - Location manager delegate methods
- (void)LocationManager:(FluxLocationServicesSingleton *)locationSingleton didUpdateLocation:(CLLocation *)newLocation{
    
    CLLocationCoordinate2D loc = [newLocation coordinate];
    [mapView setCenterCoordinate:loc];
    [self reverseGeocodeLocation: newLocation];
    
    NSLog(@"%@", [NSString stringWithFormat:@"%f", newLocation.coordinate.latitude]);
    NSLog(@"%@", [NSString stringWithFormat:@"%f", newLocation.coordinate.longitude]);
}

- (void)stopUpdatingLocationAndHeading
{
    [locationManager endLocating];
}


#pragma mark Init
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
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"MMM dd, yyyy"];
    NSString *dateString = [dateFormat stringFromDate:[NSDate date]];
    [dateLabel setText: dateString];
    
    [self setupLocationManager];
    [self startUpdatingLocationAndHeading];
    
    [self setupMapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - temp IBAction
- (IBAction) tempBackAction:(id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end
