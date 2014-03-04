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
    
    if (count <= CELLS_PER_VIEW) {
        circleStartAngle = 0;
        circleEndAngle = 0;
    }
    else{
        circleStartAngle = 340;
        circleEndAngle = circleStartAngle-(320*(self.timeScrollView.bounds.size.height / self.timeScrollView.contentSize.height));
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
        CGPoint bottomOffset = CGPointMake(0, self.timeScrollView.contentSize.height - self.timeScrollView.bounds.size.height);
        [self.timeScrollView setContentOffset:bottomOffset animated:NO];
        
        isAnimating = YES;
        
        [self performSelector:@selector(startAnimationTimer) withObject:nil afterDelay:0.1];
        [UIView animateWithDuration:1.0
                              delay:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self.timeScrollView setContentOffset:CGPointZero animated:NO];

                             //shouldbe rotating the circle by the correct amount here. ran into trouble rotating the correct direction.
                             
//                             circularScrollerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-360));
//                             circularScrollerView.transform = CGAffineTransformScale(circularScrollerView.transform, 1.03, 1.03);
//                             CGFloat angle = atan2f(circularScrollerView.transform.b*circularScrollerView.transform.b, circularScrollerView.transform.b*circularScrollerView.transform.a);
//                             
//                             circularScrollerView.transform = CGAffineTransformRotate(circularScrollerView.transform, (DEGREES_TO_RADIANS(360)-angle)*3);
//                             circularScrollerView.transform = CGAffineTransformRotate(circularScrollerView.transform, <#CGFloat angle#>);
                                     }
                         completion:^(BOOL finished){
//                             [animationTimer invalidate];
//                             animationTimer = nil;
                             isAnimating = NO;
                         }];
    }
}

- (void)startAnimationTimer{
    animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(rotateScroller) userInfo:nil repeats:YES];
}

#pragma mark - UIScrollView delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (self.fluxDisplayManager) {
        [self.fluxDisplayManager timeBracketWillBeginScrolling];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (isAnimating) {
        return;
    }
    NSLog(@" Offset = %@ ",NSStringFromCGPoint(scrollView.contentOffset));
    //if it's outside the bounds of the scrollView
//    if ((scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.frame.size.height)) && (scrollView.contentOffset.y > 0))
    if ((scrollView.contentOffset.y < scrollView.contentSize.height) && (scrollView.contentOffset.y > 0))
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
    
    [self rotateScroller];
    
    oldScrollPos = scrollView.contentOffset.y;
}

- (void)rotateScroller{
    int numberOfDegrees = -(self.timeScrollView.contentOffset.y/self.timeScrollView.contentSize.height)*320;
    NSLog(@" Degrees = %i ",numberOfDegrees);
    circularScrollerView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(numberOfDegrees));
    circularScrollerView.transform = CGAffineTransformScale(circularScrollerView.transform, 1.03, 1.03);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    oldScrollPos = scrollView.contentOffset.y;
    if (self.fluxDisplayManager) {
        [self.fluxDisplayManager timeBracketDidEndScrolling];
    }
}


@end
