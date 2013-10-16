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
        
        sliderSelectionView = [[UIImageView alloc]initWithFrame:CGRectMake(0, self.frame.size.height/2, self.frame.size.width, 20)];
        [sliderSelectionView setImage:[UIImage imageNamed:@"timebar_control"]];
        //[self addSubview:sliderSelectionView];
        
//        timePickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 216)];
//        [timePickerView setShowsSelectionIndicator:YES];
////        timePickerView.transform = CGAffineTransformMakeScale(1.0, 2.0);
//        //[timePickerView setFrame:CGRectMake(0, 0, self.frame.size.width, timePickerView.frame.size.height*2)];
//        //[timePickerView setCenter:CGPointMake(timePickerView.center.x, self.center.y)];
//        [self addSubview:timePickerView];
//        timePickerView.delegate = self;
//        timePickerView.dataSource = self;
        
        timeSlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.height, self.frame.size.width)];
        timeSlider.transform=CGAffineTransformMakeRotation(-M_PI/2);
        [timeSlider setFrame:CGRectMake(0, 0, timeSlider.frame.size.width, timeSlider.frame.size.height)];
        [timeSlider setMinimumTrackTintColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
        [timeSlider setMaximumTrackTintColor:[UIColor colorWithWhite:1.0 alpha:0.3]];
        [timeSlider setThumbTintColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
        [timeSlider addTarget:self action:@selector(timerDidSlide:) forControlEvents:UIControlEventValueChanged];
        [timeSlider setValue:0.0];
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

#pragma mark - Picker Delegate

//- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
//    // Handle the selection
//}
//
//// tell the picker how many rows are available for a given component
//- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
//    NSUInteger numRows = 50;
//    
//    return numRows;
//}
//
//// tell the picker how many components it will have
//- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
//    return 1;
//}
//
//// tell the picker the title for a given component
//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
//    NSString *title = @"-";
////    title = [@"" stringByAppendingFormat:@"%d",row];
//    
//    return title;
//}
//
//- (UIView*)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 44)]; // your frame, so picker gets "colored"
//    label.backgroundColor = [UIColor clearColor];
//    label.textColor = [UIColor whiteColor];
//    label.font = [UIFont systemFontOfSize:25];
//    label.text = @"-";
//    
//    return label;
//}
//
//// tell the picker the width of each row for a given component
//- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
//    return self.frame.size.width;
//}

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
