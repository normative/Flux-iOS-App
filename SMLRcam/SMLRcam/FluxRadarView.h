//
//  FluxRadarView.h
//  Flux
//
//  Created by Jacky So on 2013-09-06.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxScanImageObject.h"
#import "FluxLocationServicesSingleton.h"

@interface FluxRadarView : UIView
{
    NSMutableArray *radarStatusMutatbleArray;
    NSMutableArray* radarImageMutableArray;
    
    CLLocationDirection lastSynTrueHeading;
    
    FluxLocationServicesSingleton* locationManager;
    
    UIView *radarView;
}

- (void)updateRadarWithNewMetaData:(NSMutableDictionary*)newMetaData;
//- (void)updateRadarWithNewHeading:(CLHeading *)newHeading;

@end
