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

@interface FluxMapViewController : UIViewController <MKMapViewDelegate> {
    __weak IBOutlet MKMapView *mapView;
    
    __weak IBOutlet UILabel *dateLabel;
    __weak IBOutlet UILabel *locationLabel;
    __weak IBOutlet UIButton *detailButton;
    
    __weak IBOutlet UIButton *tempBackBtn;
    
    CLGeocoder *theGeocoder;
    
    //location + motion
    FluxLocationServicesSingleton *locationManager;
}

- (IBAction) tempBackAction:(id)sender;
- (void)updatePosition:(NSNotification *)notification;

@end
