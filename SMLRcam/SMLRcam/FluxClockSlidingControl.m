//
//  FluxClockSlidingControl.m
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxClockSlidingControl.h"

@implementation FluxClockSlidingControl

@synthesize timeLabel, startingYCoord, minuteHandView, hourHandView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *circleView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 15, 100, 100)];
        [circleView setImage:[UIImage imageNamed:@"thumbCircle.png"]];
        [self addSubview:circleView];
        
        UIImageView *clockView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 15, 15)];
        [clockView setContentMode:UIViewContentModeScaleAspectFit];
        [clockView setImage:[UIImage imageNamed:@"rotatingClock_empty.png"]];
        [self addSubview:clockView];
        
        self.minuteHandView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 15, 15)];
        //[clockView setContentMode:UIViewContentModeScaleAspectFill];
        [self.minuteHandView setImage:[UIImage imageNamed:@"rotatingClock_minute.png"]];
        [self addSubview:self.minuteHandView];
        
        self.hourHandView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 15, 15)];
        //[clockView setContentMode:UIViewContentModeScaleAspectFill];
        [self.hourHandView setImage:[UIImage imageNamed:@"rotatingClock_hour.png"]];
        [self addSubview:self.hourHandView];
        
        self.timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(25, -1, 80, 15)];
        [self.timeLabel setTextColor:[UIColor whiteColor]];
        [self.timeLabel setFont:[UIFont systemFontOfSize:10.0]];
        [self insertSubview:self.timeLabel aboveSubview:circleView];
        
    }
    return self;
}


- (void)changeTimeString:(NSString*)string adding:(BOOL)add{
    [self.timeLabel setText:string];
    
    if (add) {
        [self.minuteHandView setTransform:CGAffineTransformRotate(self.minuteHandView.transform,0.2)];
        [self.hourHandView setTransform:CGAffineTransformRotate(self.hourHandView.transform,0.05)];
    }
    else
    {
        [self.minuteHandView setTransform:CGAffineTransformRotate(self.minuteHandView.transform,-0.2)];
        [self.hourHandView setTransform:CGAffineTransformRotate(self.hourHandView.transform,-0.05)];
    }
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
