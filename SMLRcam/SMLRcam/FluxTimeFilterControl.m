//
//  FluxClockSlidingControl.m
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxTimeFilterControl.h"
#import <QuartzCore/QuartzCore.h>

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define CELLS_PER_VIEW 5
#define RADIUS 28

@implementation FluxTimeFilterControl

@synthesize delegate;

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
        clockContainerView = [[UIView alloc]initWithFrame:CGRectMake(0, 38, 70, 70)];
        [clockContainerView setCenter:CGPointMake(self.center.x, clockContainerView.center.y)];
        
        timeGaugeImageView = [[UIImageView alloc]initWithFrame:clockContainerView.bounds];
        [timeGaugeImageView setImage:[UIImage imageNamed:@"timeControlBG"]];
        [clockContainerView addSubview:timeGaugeImageView];
        
//        timeGaugeClockView = [[UIImageView alloc]initWithFrame:clockContainerView.bounds];
//        [timeGaugeClockView setImage:[UIImage imageNamed:@"timeControlClock"]];
//        [clockContainerView addSubview:timeGaugeClockView];
//        
        UIView*rotatedView = [[UIView alloc]initWithFrame:clockContainerView.bounds];
        rotatedView.transform = CGAffineTransformMakeRotation(-DEGREES_TO_RADIANS(90));
        
        circularScrollerView = [[UIView alloc]initWithFrame:clockContainerView.bounds];
        circularScrollerView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        [rotatedView addSubview:circularScrollerView];
        
        [clockContainerView addSubview:rotatedView];
        
        [self addSubview:clockContainerView];
        
        self.timeScrollView = [[FluxTimeFilterScrollView alloc]initWithFrame:self.bounds];
        [self.timeScrollView setDelegate:self];
        [self.timeScrollView setTapDelegate:self];
        [self.timeScrollView setShowsVerticalScrollIndicator:NO];
        [self addSubview:self.timeScrollView];
        
        oldScrollPos =  0;
        
        isAnimating = NO;
        //invert it
        //self.transform = CGAffineTransformMakeScale(-1, 1);
        
        animatingThumbView = [[UIImageView alloc]initWithFrame:self.bounds];
        [animatingThumbView setAnimationDuration:1.2];
        NSMutableArray*images = [[NSMutableArray alloc]init];
        for (int i = 29; i>0; i--) {
            [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"thumbAnimation-%i", i]]];
        }
        [animatingThumbView setAnimationImages:images];
        //    [animatingThumbView setAlpha:0.0];
        animatingThumbView.animationRepeatCount = 1;
        
        [self addSubview:animatingThumbView];
    }
    return self;
}

- (void)setScrollIndicatorCenter:(CGPoint)centre{
    [clockContainerView setCenter:CGPointMake(centre.x, centre.y-self.frame.origin.y)];
}

-(void)setViewForContentCount:(int)count reverseAnimated:(BOOL)reverseAnimated{
    
    
    float height = [[UIScreen mainScreen] bounds].size.height;
    float heightPerCell = height / CELLS_PER_VIEW;

    // add extra to allow to scroll to last image
    if (count > 1)
    {
        // add buffer to count
        count += (CELLS_PER_VIEW - 1);
    }
    
    //shows lines where the scrollView is, used for debug
//    for (int i = 0; i<count; i++) {
//        UIView*line = [[UIView alloc]initWithFrame:CGRectMake(0, heightPerCell*i, 320, 1)];
//        [line setBackgroundColor:[UIColor whiteColor]];
//        [self.timeScrollView addSubview:line];
//    }

    self.timeScrollView.contentSize = CGSizeMake(self.frame.size.width, heightPerCell * count);
    if (self.timeScrollView.contentSize.height < self.frame.size.height) {
        self.timeScrollView.contentSize = CGSizeMake(self.timeScrollView.contentSize.width, self.frame.size.height);
    }
    
    // Set up the shape of the circle
    circleLayer = [CAShapeLayer layer];
    
    CGFloat circleStartAngle;
    CGFloat circleEndAngle;
    
//    if (count <= (CELLS_PER_VIEW + CELLS_PER_VIEW - 1)) {
//        circleStartAngle = 0;
//        circleEndAngle = 0;
//    }
//    else{
        circleStartAngle = 340;
        circleEndAngle = circleStartAngle-(320*(self.timeScrollView.bounds.size.height / self.timeScrollView.contentSize.height));
//    }
    if (circleEndAngle > 320) {
        sizeRatio = 320/circleEndAngle;
        circleEndAngle = 320;
    }
    else{
        sizeRatio = 1;
    }

    circleStartAngle = DEGREES_TO_RADIANS(circleStartAngle);
    circleEndAngle = DEGREES_TO_RADIANS(circleEndAngle);

    
    // Make a circular shape
    circleLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(0,0)
                                                 radius:RADIUS
                                             startAngle:circleStartAngle
                                               endAngle:circleEndAngle
                                                   clockwise:NO].CGPath;
    
    // Center the shape in performanceCircleView
    circleLayer.position = CGPointMake(CGRectGetMidX(timeGaugeImageView.frame),
                                  CGRectGetMidY(timeGaugeImageView.frame));
    
    // Configure the apperence of the circle
    circleLayer.fillColor = [UIColor clearColor].CGColor;
    circleLayer.strokeColor = [UIColor whiteColor].CGColor;
    circleLayer.lineWidth = 2;
    
    circleLayer.shadowColor = [[UIColor whiteColor] CGColor];
    circleLayer.shadowRadius = 4.0f;
    circleLayer.shadowOpacity = .9;
    circleLayer.shadowOffset = CGSizeZero;
    circleLayer.masksToBounds = NO;
    
    // Add to parent layer
    if ([circularScrollerView.layer sublayers].count == 0) {
        [circularScrollerView.layer insertSublayer:circleLayer atIndex:0];
    }
    else{
        [circularScrollerView.layer replaceSublayer:[[circularScrollerView.layer sublayers]objectAtIndex:0] with:circleLayer];
#warning when a new imageList is downloaded and the image count changes, we should consider where the image list scroll point is, for now we are not.
        //[self.timeScrollView setContentOffset:CGPointMake(0.0, 0.0)];
    }
    
    if (reverseAnimated) {
        isAnimating = YES;
        CGPoint bottomOffset = CGPointMake(0, self.timeScrollView.contentSize.height - self.timeScrollView.bounds.size.height);
        [self.timeScrollView setContentOffset:bottomOffset animated:NO];
        [self scrollScrollerToCalculatedPosition];
        
        
        int numberOfDegrees = -(self.timeScrollView.contentOffset.y/self.timeScrollView.contentSize.height)*320;
        if (numberOfDegrees > -180) {
            //if it's less than halfway to 0 degrees already, just go to 0
            [UIView animateWithDuration:1.0 animations:^{
                circularScrollerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
                //circularScrollerView.transform = CGAffineTransformScale(circularScrollerView.transform, 1.03, 1.03);
                [self.timeScrollView setContentOffset:CGPointZero animated:NO];
            }completion:^(BOOL finished){
                isAnimating = NO;
            }];
        }
        else{
            //else, stage it at 180 degrees first, then go to 0
            [UIView animateWithDuration:0.5
                                  delay:0.1
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 circularScrollerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
                                 //circularScrollerView.transform = CGAffineTransformScale(circularScrollerView.transform, 1.03, 1.03);
                             }
                             completion:^(BOOL finished){
                                 [UIView animateWithDuration:0.5
                                                       delay:0.0
                                                     options:UIViewAnimationOptionCurveEaseOut
                                                  animations:^{
                                                    circularScrollerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
                                                    [self.timeScrollView setContentOffset:CGPointZero animated:NO];
                                                  }
                                                  completion:^(BOOL finished){
                                                    isAnimating = NO;
                                                    circularScrollerView.transform = CGAffineTransformScale(circularScrollerView.transform, 1.03, 1.03);
                                                  }];
                             }];
        }
    }
}

#pragma mark - UIScrollView delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (self.fluxDisplayManager) {
        [self.fluxDisplayManager timeBracketWillBeginScrolling];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{

//    NSLog(@" Offset = %@ ",NSStringFromCGPoint(scrollView.contentOffset));
    
    //if it's outside the bounds of the scrollView
//    if ((scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.frame.size.height)) && (scrollView.contentOffset.y > 0))
    if ((scrollView.contentOffset.y < scrollView.contentSize.height) && (scrollView.contentOffset.y >= 0))
    {
        int nlc = self.fluxDisplayManager.nearbyListCount;
        if (self.fluxDisplayManager && (nlc > 1))
        {
            // adjust for the buffer to allow scrolling to the last item in the real list.  Make sure it doesn't go beyond that.
            int nlc = self.fluxDisplayManager.nearbyListCount;
            int idx = (nlc + (CELLS_PER_VIEW - 1)) * (scrollView.contentOffset.y / scrollView.contentSize.height);
            if (idx >= nlc)
                idx = nlc - 1;
            [self.fluxDisplayManager timeBracketDidChange:idx];

        }
    }
    if (!isAnimating) {
        [self scrollScrollerToCalculatedPosition];
    }
    
    
    oldScrollPos = scrollView.contentOffset.y;
}

- (void)scrollScrollerToCalculatedPosition{
    int numberOfDegrees = -(self.timeScrollView.contentOffset.y/self.timeScrollView.contentSize.height)*320;
    numberOfDegrees = numberOfDegrees*sizeRatio;
//    NSLog(@" Degrees = %i ",numberOfDegrees);
    circularScrollerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(numberOfDegrees));
    circularScrollerView.transform = CGAffineTransformScale(circularScrollerView.transform, 1.03, 1.03);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    oldScrollPos = scrollView.contentOffset.y;
    if (self.fluxDisplayManager) {
        [self.fluxDisplayManager timeBracketDidEndScrolling];
    }
}
#pragma mark - Tap Delegate
- (void)timeFilterScrollView:(FluxTimeFilterScrollView *)scrollView didTapAtPoint:(CGPoint)point{
    if (CGRectContainsPoint(clockContainerView.frame, point)) {
        [self buttonWasPressed];
        [self performSelector:@selector(endbuttonPress) withObject:nil afterDelay:0.05];
    }
    else{
        if ([delegate respondsToSelector:@selector(timeFilterControl:didTapAtPoint:)]) {
            [delegate timeFilterControl:self didTapAtPoint:point];
        }
    }
}

-(void)timeFilterScrollView:(FluxTimeFilterScrollView *)scrollView shouldBeginTouchAtPoint:(CGPoint)point{
    if (CGRectContainsPoint(clockContainerView.frame, point) && scrollView.contentSize.height != self.frame.size.height) {
        [clockContainerView setAlpha:0.4];
    }
    
}

- (void)timeFilterScrollView:(FluxTimeFilterScrollView *)scrollView shouldEndTouchAtPoint:(CGPoint)point{
    [clockContainerView setAlpha:1.0];
}

- (void)timeFilterScrollViewShouldBeginTouches:(FluxTimeFilterScrollView *)scrollView{

}

- (void)timeFilterScrollViewShouldEndTouches:(FluxTimeFilterScrollView *)scrollView{
    
}

- (void)buttonWasPressed{
    [self showThumbView];
}

- (void)endbuttonPress{
    [clockContainerView setAlpha:1.0];
}

- (void)showThumbView{

    
//    [animatingThumbView startAnimating];
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        [animatingThumbView setAlpha:1.0];
//    }completion:^(BOOL finished){
//        [UIView animateWithDuration:0.5 animations:^{
//            [animatingThumbView setAlpha:0.0];
//             }completion:^(BOOL finished){
//                 [animatingThumbView stopAnimating];
//        }];
//    }];
}


@end
