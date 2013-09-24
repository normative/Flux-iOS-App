//
//  FluxClockSlidingControl.h
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxDataManager.h"

@interface FluxTimeFilterControl : UIView<UIGestureRecognizerDelegate>{
    UIImageView *quickPanCircleView;
}

@property (nonatomic)float startingYCoord;
@property (nonatomic, weak) FluxDataManager *fluxDataManager;


//quick pan circle view
- (void)enableQuickPanCircle;
- (void)showQuickPanCircleAtPoint:(CGPoint)point;
- (void)hideQuickPanCircle;
- (void)quickPanDidSlideToPoint:(CGPoint)point;

//swipe time gesture
- (void)handleSwipeUpGesture:(UISwipeGestureRecognizer*)sender;
- (void)handleSwipeDownGesture:(UISwipeGestureRecognizer*)sender;
@end
