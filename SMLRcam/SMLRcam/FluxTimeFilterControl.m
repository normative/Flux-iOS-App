//
//  FluxClockSlidingControl.m
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxTimeFilterControl.h"

@implementation FluxTimeFilterControl

@synthesize startingYCoord;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        quickPanCircleView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 15, 100, 100)];
        [quickPanCircleView setImage:[UIImage imageNamed:@"thumbCircle.png"]];
        [quickPanCircleView setHidden:YES];
        quickPanCircleView.transform = CGAffineTransformScale(quickPanCircleView.transform, 0.5, 0.5);
        [self addSubview:quickPanCircleView];
    }
    return self;
}

- (void)showQuickPanCircleAtPoint:(CGPoint)point{
    if (![quickPanCircleView isHidden]) {
        return;
    }
    [quickPanCircleView setHidden:NO];
    [quickPanCircleView setCenter:point];
    //start with today's date
    
    [UIView animateWithDuration:0.2f
                     animations:^{
                         quickPanCircleView.transform = CGAffineTransformScale(quickPanCircleView.transform, 2.0, 2.0);
                     }];
}

- (void)quickPanDidSlideToPoint:(CGPoint)point{
    [quickPanCircleView setCenter:point];
}

- (void)hideQuickPanCircle{
    //if it's not normal size, don't shrink it again
    if (quickPanCircleView.transform.a != 1 || quickPanCircleView.transform.d != 1) {
        return;
    }

    [UIView animateWithDuration:0.1f
                     animations:^{
                         quickPanCircleView.transform = CGAffineTransformScale(quickPanCircleView.transform, 0.1, 0.1);
                     }
                     completion:^(BOOL finished){
                         [quickPanCircleView setHidden:YES];
                         quickPanCircleView.transform = CGAffineTransformScale(quickPanCircleView.transform, 5.0, 5.0);
                     }];
}

@end
