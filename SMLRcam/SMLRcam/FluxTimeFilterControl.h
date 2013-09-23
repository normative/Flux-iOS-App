//
//  FluxClockSlidingControl.h
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxTimeFilterControl : UIView{
    UIImageView *quickPanCircleView;
}

@property (nonatomic)float startingYCoord;

- (void)showQuickPanCircleAtPoint:(CGPoint)point;
- (void)hideQuickPanCircle;
- (void)quickPanDidSlideToPoint:(CGPoint)point;

@end
