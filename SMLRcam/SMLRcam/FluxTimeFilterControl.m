//
//  FluxClockSlidingControl.m
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxTimeFilterControl.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@implementation FluxTimeFilterControl

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
        clockContainerView = [[UIView alloc]initWithFrame:CGRectMake(0, 45, 60, 60)];
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
        [rotatedView addSubview:circularScrollerView];
        
        [clockContainerView addSubview:rotatedView];
        
        [self addSubview:clockContainerView];
        
        self.timeScrollView = [[FluxTimeFilterScrollView alloc]initWithFrame:self.bounds];
        [self.timeScrollView setDelegate:self];
        [self.timeScrollView setTapDelegate:self];
        [self.timeScrollView setShowsVerticalScrollIndicator:NO];
        [self addSubview:self.timeScrollView];
        
        oldScrollPos =  0;
    }
    return self;
}

- (void)setScrollIndicatorCenter:(CGPoint)centre{
    [clockContainerView setCenter:CGPointMake(centre.x, centre.y-self.frame.origin.y)];
}

-(void)setViewForContentCount:(int)count{
    
    
    float height = [[UIScreen mainScreen] bounds].size.height;
    float heightPerCell = height/5;
    self.timeScrollView.contentSize = CGSizeMake(self.frame.size.width, heightPerCell*count);
    
    // Set up the shape of the circle
    int radius = 28;
    circleLayer = [CAShapeLayer layer];
    
    CGFloat circleStartAngle;
    CGFloat circleEndAngle;
    
    if (count < 6) {
        circleStartAngle = 340;
        circleEndAngle = 20;
    }
    else{
        circleStartAngle = 340;
        circleEndAngle = circleStartAngle-(320*(self.timeScrollView.bounds.size.height / self.timeScrollView.contentSize.height));
    }

    circleStartAngle = DEGREES_TO_RADIANS(circleStartAngle);
    circleEndAngle = DEGREES_TO_RADIANS(circleEndAngle);

    
    // Make a circular shape
    circleLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(0,0)
                                                 radius:radius
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
    
    // Add to parent layer
    if ([circularScrollerView.layer sublayers].count == 0) {
        [circularScrollerView.layer insertSublayer:circleLayer atIndex:0];
    }
    else{
        [circularScrollerView.layer replaceSublayer:[[circularScrollerView.layer sublayers]objectAtIndex:0] with:circleLayer];
#warning when a new imageList is downloaded and the image count changes, a loading screen should appear, then the scrollView should go back to 0.
        //[self.timeScrollView setContentOffset:CGPointMake(0.0, 0.0)];
    }
}

#pragma mark - UIScrollView delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (self.fluxDisplayManager) {
        [self.fluxDisplayManager timeBracketWillBeginScrolling];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    //if it's outside the bounds of the scrollView
    if ((scrollView.contentOffset.y < scrollView.contentSize.height - scrollView.frame.size.height) && scrollView.contentOffset.y > 0) {
        if (self.fluxDisplayManager && self.fluxDisplayManager.nearbyListCount > 5) {
            [self.fluxDisplayManager timeBracketDidChange:(scrollView.contentOffset.y/scrollView.contentSize.height)];
        }
    }
    
    int numberOfDegrees = -(scrollView.contentOffset.y/scrollView.contentSize.height)*320;
    circularScrollerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(numberOfDegrees));
    
//    float angleToMove = DEGREES_TO_RADIANS(((oldScrollPos-scrollView.contentOffset.y)/(scrollView.contentSize.height))*300);
//    timeGaugeClockView.transform = CGAffineTransformRotate(timeGaugeClockView.transform, angleToMove*17);

    
    oldScrollPos = scrollView.contentOffset.y;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    oldScrollPos = scrollView.contentOffset.y;
    if (self.fluxDisplayManager) {
        [self.fluxDisplayManager timeBracketDidEndScrolling];
    }
}


@end
