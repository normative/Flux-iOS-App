//
//  FluxMapViewController.h
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapIndex.h"
#import "FluxUserLocationMapPin.h"

#import "FluxDataManager.h"
#import "FluxDisplayManager.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxFiltersViewController.h"

#import "GAITrackedViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

@class FluxScanImageObject;

@interface FluxMapViewController : GAITrackedViewController<MKMapViewDelegate, UIGestureRecognizerDelegate, FiltersTableViewDelegate, MIMapViewDelegate, UISearchBarDelegate>
{
    CLLocationCoordinate2D lastSynchedLocation;
     double lastRadius;
    int outstandingRequests;
    
    // Map View
    __weak IBOutlet MIMapView *fluxMapView;
    
    //location + motion
    FluxUserLocationMapPin *userLocationPin;
    MKCircle*tempCircle;
    
    
    IBOutlet UIButton *filterButton;
    FluxDataFilter *previousDataFilter;
    
    UIView*transitionFadeView;
}

@property (nonatomic, assign) UIInterfaceOrientation myViewOrientation;
@property (nonatomic, weak) FluxDisplayManager *fluxDisplayManager;
@property (nonatomic, weak) FluxLocationServicesSingleton *locationManager;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarBottomConstraint;

@property (nonatomic, strong) FluxDataFilter *currentDataFilter;

- (IBAction)closeButtonAction:(id)sender;


@end
