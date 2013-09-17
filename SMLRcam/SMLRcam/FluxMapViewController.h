//
//  FluxMapViewController.h
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"

@class FluxScanImageObject;

@interface FluxMapViewController : UIViewController<MKMapViewDelegate, UIGestureRecognizerDelegate>
{
    UIActivityIndicatorView *activityIndicator;
    
    //
    UIPinchGestureRecognizer *pinchRecognizer;
    
    // Currnet View Orientation Direction
    UIInterfaceOrientation myViewOrientation;
    
    MKAnnotationView *userAnnotationView;
    CLLocationCoordinate2D userLastSynchedLocation;
    
    MKMapCamera*mapCamera;
    
    // Map View
    __weak IBOutlet MKMapView *mapView;
    
    // Status Bar
    __weak IBOutlet UIButton *statusBarExitMapBtn;
    __weak IBOutlet UIButton *statusBardetailBtn;
    __weak IBOutlet UILabel *dateLabel;
    __weak IBOutlet UILabel *locationLabel;
    __weak IBOutlet UILabel *imageCountLabel;
    
    // button
    __weak IBOutlet UIButton *locateMeBtn;
    
    //location + motion
    FluxLocationServicesSingleton *locationManager;
}

@property (nonatomic, assign) UIInterfaceOrientation myViewOrientation;
@property (nonatomic, weak) FluxDataManager *fluxDataManager;

- (IBAction)onLocateMeBtn:(id)sender;

@end
