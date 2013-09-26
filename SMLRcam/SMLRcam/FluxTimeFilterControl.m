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
        UIImageView *bgView = [[UIImageView alloc]initWithFrame:self.bounds];
        [bgView setImage:[UIImage imageNamed:@"timebar_outline"]];
        //[self addSubview:bgView];
        
        UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUpGesture:)];
        [swipeUpRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
        //[self addGestureRecognizer:swipeUpRecognizer];
        
        UISwipeGestureRecognizer *swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDownGesture:)];
        [swipeDownRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
        //[self addGestureRecognizer:swipeDownRecognizer];
        
        sliderSelectionView = [[UIImageView alloc]initWithFrame:CGRectMake(0, self.frame.size.height-20, self.frame.size.width, 20)];
        [sliderSelectionView setImage:[UIImage imageNamed:@"timebar_control"]];
        //[self addSubview:sliderSelectionView];
        
        timeSlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.height, self.frame.size.width)];
        timeSlider.transform=CGAffineTransformMakeRotation(M_PI/2);
        [timeSlider setFrame:CGRectMake(0, 0, timeSlider.frame.size.width, timeSlider.frame.size.height)];
        [timeSlider setTintColor:[UIColor colorWithWhite:0.72 alpha:1.0]];
        [timeSlider addTarget:self action:@selector(timerDidSlide:) forControlEvents:UIControlEventValueChanged];
        [timeSlider setValue:1.0];
        [self addSubview:timeSlider];
        
        UILabel *nowLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.frame.size.height+5, self.frame.size.width, 8)];
        [nowLabel setText:@"Now"];
        [nowLabel setFont:[UIFont fontWithName:@"Akkurat" size:13.0]];
        nowLabel.textAlignment = NSTextAlignmentCenter;
        [nowLabel setTextColor:[UIColor whiteColor]];
        [self addSubview:nowLabel];
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

- (void)timerDidSlide:(id)sender{
    if (self.fluxDisplayManager) {
        [self.fluxDisplayManager timeBracketDidChange:timeSlider.value];
    }
}

#pragma mark - Gesture recognizers
//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    NSLog(@"touched timeView");
//    UITouch *touch = [[event allTouches] anyObject];
//    CGPoint touchLocation = [touch locationInView:self];
//    [sliderSelectionView setCenter:CGPointMake(sliderSelectionView.center.x, touchLocation.y)];
//}
//
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
//    UITouch *touch = [[event allTouches] anyObject];
//    CGPoint touchLocation = [touch locationInView:self];
//    CGPoint moveMaxLocation = CGPointMake(touchLocation.x, touchLocation.y-sliderSelectionView.frame.size.height/2);
//    CGPoint moveMinLocation = CGPointMake(touchLocation.x, touchLocation.y+sliderSelectionView.frame.size.height/2);
//    if (CGRectContainsPoint(self.bounds, moveMaxLocation) && CGRectContainsPoint(self.bounds, moveMinLocation)) {
//        [sliderSelectionView setCenter:CGPointMake(sliderSelectionView.center.x, touchLocation.y)];
//    }
//}
- (void)handleSwipeUpGesture:(UISwipeGestureRecognizer *)sender{
    //swiped up
    NSLog(@"Swiped up in timeView");
}

- (void)handleSwipeDownGesture:(UISwipeGestureRecognizer*)sender{
    //swiped down
    NSLog(@"Swiped down in timeView");
}

@end
