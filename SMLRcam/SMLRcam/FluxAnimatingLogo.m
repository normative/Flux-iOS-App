//
//  FluxAnimatingLogo.m
//  Flux
//
//  Created by Kei Turner on 2014-03-12.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxAnimatingLogo.h"

@implementation FluxAnimatingLogo

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]) {
    }
    return self;
}

- (void)setFirstAnimationSet:(NSMutableArray*)animationSet1 andSecondAnimationSet:(NSMutableArray*)animationSet2{

    imageView1 = [[UIImageView alloc]initWithFrame:self.bounds];
    [imageView1 setImage:(UIImage*)[animationSet1 objectAtIndex:0]];
    [imageView1 setAnimationImages:[animationSet1 subarrayWithRange:NSMakeRange(1, animationSet1.count-2)]];
    [imageView1 setAnimationDuration:imageView1.animationImages.count/30.0];
    [imageView1 setAnimationRepeatCount:1];
    
    imageView2 = [[UIImageView alloc]initWithFrame:self.bounds];
    [imageView2 setAnimationImages:animationSet2];
    [imageView2 setAnimationDuration:imageView2.animationImages.count/30.0];

    
    [imageView1 setContentMode:UIViewContentModeScaleAspectFill];
    [imageView2 setContentMode:UIViewContentModeScaleAspectFill];
    
    [self addSubview:imageView1];
    [self addSubview:imageView2];
    
    isAnimating = NO;
    
    //disable 2-stage animation
    [imageView2 setImage:(UIImage*)[animationSet1 objectAtIndex:0]];
    [imageView1 setHidden:YES];
    [imageView2 setHidden:NO];
}

-(void)startAnimating{
    isAnimating = YES;
    [imageView2 startAnimating];
//    [self performSelector:@selector(swapImageViews) withObject:nil afterDelay:0.0];
}
-(void)stopAnimating{
    isAnimating = NO;
//    [imageView2 setHidden:YES];
    [imageView1 stopAnimating];
    [imageView2 stopAnimating];
}

- (void)swapImageViews{
    if (isAnimating) {
        [imageView2 setHidden:NO];
        [imageView1 setHidden:YES];
        [imageView1 stopAnimating];
        [imageView2 startAnimating];
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
