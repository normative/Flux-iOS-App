//
//  FluxClockSlidingControl.h
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxTimeFilterScrollView.h"

#import "FluxDisplayManager.h"


@interface FluxTimeFilterControl : UIView<UIScrollViewDelegate, TimeFilterScrollViewTapDelegate>{
    UIView*clockContainerView;
    UIImageView*timeGaugeImageView;
    UIImageView*timeGaugeClockView;
    UIView *circularScrollerView;
    CAShapeLayer *circleLayer;
    
    BOOL isAnimating;
    
    float oldScrollPos;
}

@property (nonatomic, strong)FluxTimeFilterScrollView*timeScrollView;
@property (nonatomic, weak) FluxDisplayManager *fluxDisplayManager;


-(void)setViewForContentCount:(int)count reverseAnimated:(BOOL)reverseAnimated;
- (void)setScrollIndicatorCenter:(CGPoint)centre;


@end
