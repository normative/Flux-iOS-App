//
//  FluxCameraRollButton.m
//  Flux
//
//  Created by Kei Turner on 1/21/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxCameraRollButton.h"

@implementation FluxCameraRollButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self generalInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]) {
        // Initialization code
        [self generalInit];
    }
    return self;
}

- (void)generalInit{
    imageView = [[UIImageView alloc]initWithFrame:self.bounds];
    [imageView setBackgroundColor:[UIColor clearColor]];
    imageView.layer.cornerRadius = 1.5;
    imageView.layer.masksToBounds = YES;
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self addSubview:imageView];
    
    [self addTarget:self action:@selector(touchedDown) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(touchEnded) forControlEvents:UIControlEventTouchCancel | UIControlEventTouchUpOutside | UIControlEventTouchUpInside];
}

- (void)addImage:(UIImage*)image{
    imageView.transform = CGAffineTransformMakeScale(0.2, 0.2);
    [imageView setImage:image];
    [self performSelector:@selector(animateAddingImage) withObject:nil afterDelay:0.25];
}


- (void)animateAddingImage{
    [UIView animateWithDuration:0.3 animations:^{
        imageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }completion:^(BOOL finished){
        
    }];
}


-(void)touchedDown{
    [imageView setAlpha:0.5];
}

- (void)touchEnded{
    [imageView setAlpha:1.0];
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
