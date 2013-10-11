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

- (void) setupLocationManager;
- (void) setupMapView;

@end

@implementation FluxMapViewController

@synthesize myViewOrientation;

#pragma mark - Callbacks


#pragma mark MapKit

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	MIAnnotation *annotation = (MIAnnotation *)view.annotation;
	if ([annotation class] == [MIAnnotation class])
	{
        
	}
}

- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
}

// initialize and allocate memory to the map view object
- (void) setupMapView
{
    [fluxMapView setShowsUserLocation:YES];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(locationManager.location.coordinate, 50, 50);
    MKCoordinateRegion adjustedRegion = [fluxMapView regionThatFits:viewRegion];
    [fluxMapView setRegion:adjustedRegion animated:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
                   {
                       if (self.fluxDisplayManager.fluxNearbyMetadata) {
                           dispatch_async(dispatch_get_main_queue(), ^
                              {
                                  [fluxMapView addAnnotations:[self.fluxDisplayManager.fluxNearbyMetadata allValues]];
                              });
                       }
                   });
}


#pragma mark - IBActions

- (IBAction)closeButtonAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^(void)
     {
         [EAGLContext setCurrentContext:nil];
     }];
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLocationManager];
    [self setupMapView];
    
    self.screenName = @"Map View";
}

@end
