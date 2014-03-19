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

@class FluxTimeFilterControl;
@protocol TimeFilterControlDelegate <NSObject>
@optional
- (void)timeFilterControl:(FluxTimeFilterControl *)timeControl didTapAtPoint:(CGPoint)point;
@end

@interface FluxTimeFilterControl : UIView<UIScrollViewDelegate, TimeFilterScrollViewTapDelegate>{
    UIView*clockContainerView;
    UIImageView*timeGaugeImageView;
    UIImageView*timeGaugeClockView;
    UIView *circularScrollerView;
    CAShapeLayer *circleLayer;
    
    UIImageView*animatingThumbView;
    
    BOOL isAnimating;
    
    float oldScrollPos;
    __weak id <TimeFilterControlDelegate> delegate;
}
@property (nonatomic, weak) id <TimeFilterControlDelegate> delegate;

@property (nonatomic, strong)FluxTimeFilterScrollView*timeScrollView;
@property (nonatomic, weak) FluxDisplayManager *fluxDisplayManager;


-(void)setViewForContentCount:(int)count reverseAnimated:(BOOL)reverseAnimated;
- (void)setScrollIndicatorCenter:(CGPoint)centre;
- (void)showThumbView;


@end
