//
//  FluxRotatingCompassButton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxLocationServicesSingleton.h"

@interface FluxRotatingCompassButton : UIButton {
    UIImageView*rotatingView;
    
    FluxLocationServicesSingleton* locationManager;
}

- (void)headingUpdated:(NSNotification *)notification;

@end
