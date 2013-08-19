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

@interface FluxMapViewController : UIViewController {
    // Currnet View Orientation Direction (
    UIInterfaceOrientation myViewOrientation;
    
    // Map View
    __weak IBOutlet MKMapView *myMapView;
    
    // Status Bar
    __weak IBOutlet UIButton *statusBarExitMapBtn;
    __weak IBOutlet UIButton *statusBardetailBtn;
    __weak IBOutlet UILabel *statusBarcurrentDateLbl;
    __weak IBOutlet UILabel *statusBarcurrentLocalityLbl;
    
    //location + motion
    FluxLocationServicesSingleton *locationManager;
}
@property (nonatomic, assign) UIInterfaceOrientation myViewOrientation;

- (IBAction) exitMapView:(id)sender;

@end
