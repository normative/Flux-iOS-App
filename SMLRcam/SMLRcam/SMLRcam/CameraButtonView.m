//
//  CameraButtonView.m
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-26.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import "CameraButtonView.h"

@implementation CameraButtonView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)buttonTapped:(id)sender{
    
    if([delegate respondsToSelector:@selector(CameraButtonView:buttonWasTapped:)])
    {
        [delegate CameraButtonView:self buttonWasTapped:sender];
    }
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
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
