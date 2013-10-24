//
//  FluxClockSlidingControl.h
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxTimeFilterScrollView.h"

#import "FluxDisplayManager.h"

@interface FluxTimeFilterControl : UIView<UIScrollViewDelegate>{
    UIView*clockContainerView;
    UIImageView*timeGaugeImageView;
    UIImageView*timeGaugeClockView;
    UIView *circularScrollerView;
    CAShapeLayer *circleLayer;
    
    float oldScrollPos;
}
@property (nonatomic, strong)FluxTimeFilterScrollView*timeScrollView;
@property (nonatomic, weak) FluxDisplayManager *fluxDisplayManager;


-(void)setViewForContentCount:(int)count;
- (void)setScrollIndicatorCenter:(CGPoint)centre;


@end
