//
//  CameraButtonView.m
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-26.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import "PassthroughView.h"

@implementation PassthroughView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cameraButton addTarget:self
                   action:@selector(buttonTapped:)
         forControlEvents:UIControlEventTouchUpInside];
        [cameraButton setImage:[UIImage imageNamed:@"camButton.png"] forState:UIControlStateNormal];
        cameraButton.frame = CGRectMake(0, 0, 36, 36);
        [cameraButton setCenter:CGPointMake(self.center.x, self.bounds.size.height-cameraButton.frame.size.height - 10)];
        [self addSubview:cameraButton];
    }
    return self;
}

- (void)buttonTapped:(id)sender{
    
    if([delegate respondsToSelector:@selector(PassthroughView:buttonWasTapped:)])
    {
        [delegate PassthroughView:self buttonWasTapped:sender];
    }
    [self camButtonAction];
    
}

- (void)camButtonAction{
    if (CGAffineTransformIsIdentity(cameraButton.transform)) {
        //if the button is in the 'inactive state, i.e the camera is not active
        
        [UIView beginAnimations:@"button" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.3];
        //[UIView setAnimationDelay:1.0];
        CGAffineTransform newTransform;
        newTransform = CGAffineTransformMakeTranslation(0, -15);
        cameraButton.transform = CGAffineTransformScale(newTransform,2,2);
        [UIView commitAnimations];
        
        UIImage *trans_img = [UIImage imageNamed:@"camButton_axtive.png"];
        
        //some ind of anuimation to switch images
        [UIView animateWithDuration:0.5 animations:^{
            //cameraButton.alpha = 0.8f;
        } completion:^(BOOL finished) {
            cameraButton.imageView.animationImages = [NSArray arrayWithObjects:trans_img,nil];
            [cameraButton.imageView startAnimating];
            [UIView animateWithDuration:0.5 animations:^{
                //cameraButton.alpha = 1.0f;
            }];
        }];
    }
    else{
        [UIView beginAnimations:@"button" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.3];
        //[UIView setAnimationDelay:1.0];
        //CameraButton.transform = CGAffineTransformScale(CameraButton.transform, 0.0001, 0.0001);
        CGAffineTransform newTransform;
        newTransform = CGAffineTransformMakeTranslation(0, 0);
        cameraButton.transform = CGAffineTransformScale(newTransform,1,1);
        [UIView commitAnimations];
        
        
        //some ind of anuimation to switch images back
        UIImage *trans_img = [UIImage imageNamed:@"camButton.png"];
        [UIView animateWithDuration:0.5 animations:^{
            //cameraButton.alpha = 0.8f;
        } completion:^(BOOL finished) {
            cameraButton.imageView.animationImages = [NSArray arrayWithObjects:trans_img,nil];
            [cameraButton.imageView startAnimating];
            [UIView animateWithDuration:0.5 animations:^{
                //cameraButton.alpha = 1.0f;
            }];
        }];
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
