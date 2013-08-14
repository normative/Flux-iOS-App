//
//  FluxMapViewController.h
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "FluxLocationServicesSingleton.h"

@interface FluxMapViewController : UIViewController <LocationServicesSingletonDelegate, MKMapViewDelegate> {
    __weak IBOutlet MKMapView *mapView;
    
    // Status Bar
    __weak IBOutlet UIButton *exitMapBtn;
    __weak IBOutlet UILabel *currentDateLbl;
    __weak IBOutlet UILabel *currentLocalityLbl;
    __weak IBOutlet UIButton *detailBtn;
    
    // location information coder
    CLGeocoder *theGeocoder;
    
    //location + motion
    FluxLocationServicesSingleton *locationManager;
}

- (IBAction) exitMapView:(id)sender;

@end
