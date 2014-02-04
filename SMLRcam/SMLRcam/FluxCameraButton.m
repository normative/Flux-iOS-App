//
//  FluxCameraButton.m
//  Flux
//
//  Created by Kei Turner on 2013-09-04.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxCameraButton.h"

@implementation FluxCameraButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        circleLayer = [CAShapeLayer layer];
        circleLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.frame].CGPath;
        
        // Center the shape, with magic numbers :(
        circleLayer.position = CGPointMake(-10, -12);
        
        // Configure the apperence of the circle
        circleLayer.fillColor = [UIColor clearColor].CGColor;
        circleLayer.strokeColor = [UIColor whiteColor].CGColor;
        circleLayer.lineWidth = 1;
        
        circleLayer.masksToBounds = NO;
        circleLayer.shadowColor = [UIColor blackColor].CGColor;
        circleLayer.shadowOffset = CGSizeMake(0.0f, 5.0f);
        circleLayer.shadowOpacity = 0.5f;
        //circleLayer.shadowPath = circleLayer.path;
        
        [self.layer addSublayer:circleLayer];
        
        //[self setContentMode:UIViewContentModeCenter];
        
    }
    return self;
}

- (void)awakeFromNib {

}

- (void)setEnabled:(BOOL)enabled{
    [super setEnabled:enabled];
    if (!enabled) {
        [self setAlpha:0.4];
        [self setUserInteractionEnabled:NO];
        circleLayer.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.4].CGColor;
    }
    else{
        [self setAlpha:1.0];
        [self setUserInteractionEnabled:YES];
        circleLayer.strokeColor = [UIColor whiteColor].CGColor;
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
