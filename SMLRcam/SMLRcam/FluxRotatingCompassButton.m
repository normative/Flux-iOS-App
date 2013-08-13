//
//  FluxRotatingCompassButton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxRotatingCompassButton.h"

@implementation FluxRotatingCompassButton

#pragma mark - Init Methods

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
        //custom init
        
        locationManager = [FluxLocationServicesSingleton sharedManager];
        [locationManager addObserver:self forKeyPath:@"heading" options:NSKeyValueObservingOptionNew context:nil];
        
        rotatingView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [rotatingView setImage:[UIImage imageNamed:@"compassButton_Exterior.png"]];
        [rotatingView setContentMode:UIViewContentModeScaleAspectFit];        
        
        [self.imageView addSubview:rotatingView];
        
        
    }
    return self;
}


#pragma mark - Heading observation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"heading"] )
    {
        #warning vastly incomplete implementation here, at this point it merely rotates the view based off of heading.
        CGAffineTransform transform = CGAffineTransformMakeRotation((float)locationManager.heading/36);
        rotatingView.transform = transform;
    }
}

//button highlight
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.imageView setAlpha:0.55];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.imageView setAlpha:1.0];
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
