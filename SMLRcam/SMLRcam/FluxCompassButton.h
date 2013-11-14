//
//  FluxRadarView.h
//  Flux
//
//  Created by Jacky So on 2013-09-06.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxScanImageObject.h"
#import "FluxLocationServicesSingleton.h"

@interface FluxCompassButton : UIButton
{
    NSMutableArray *radarStatusArray;
    NSMutableArray* radarImagesArray;
    
    UIImage*onImg;
    
    CLLocationDirection lastSynTrueHeading;
    
    FluxLocationServicesSingleton* locationManager;
    
    UIView *radarView;
    UIView*selectionView;
}
- (void)updateImageList:(NSNotification*)notification;

@end
