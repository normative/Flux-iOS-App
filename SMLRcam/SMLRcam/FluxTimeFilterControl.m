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
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUpGesture:)];
        [swipeUpRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
        [self addGestureRecognizer:swipeUpRecognizer];
        
        UISwipeGestureRecognizer *swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDownGesture:)];
        [swipeDownRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
        [self addGestureRecognizer:swipeDownRecognizer];
    }
    return self;
}

#pragma mark - Quick Pan Circle View

- (void)enableQuickPanCircle{
    if (!quickPanCircleView) {
        quickPanCircleView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 15, 100, 100)];
        [quickPanCircleView setImage:[UIImage imageNamed:@"thumbCircle.png"]];
        [quickPanCircleView setHidden:YES];
        quickPanCircleView.transform = CGAffineTransformScale(quickPanCircleView.transform, 0.5, 0.5);
        [self addSubview:quickPanCircleView];
    }
}

- (void)showQuickPanCircleAtPoint:(CGPoint)point{
    if (!quickPanCircleView) {
        return;
    }
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
    startingYCoord = point.y;
}

- (void)quickPanDidSlideToPoint:(CGPoint)point{
    if (!quickPanCircleView) {
        return;
    }
    [quickPanCircleView setCenter:point];
}

- (void)hideQuickPanCircle{
    if (!quickPanCircleView) {
        return;
    }
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

#pragma mark - Gesture recognizer
- (void)handleSwipeUpGesture:(UISwipeGestureRecognizer *)sender{
    //swiped up
    NSLog(@"Swiped up in timeView");
}

- (void)handleSwipeDownGesture:(UISwipeGestureRecognizer*)sender{
    //swiped down
    NSLog(@"Swiped down in timeView");
}

@end
