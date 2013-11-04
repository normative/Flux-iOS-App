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

    }
    return self;
}

- (void)awakeFromNib {
    circleView = [[UIImageView alloc]initWithFrame:self.frame];
//    [circleView setFrame:self.frame];
    [circleView setFrame:CGRectMake(-self.frame.size.width/2, -self.frame.size.height/2, self.frame.size.width*2, self.frame.size.height*2)];
    [circleView setImage:[UIImage imageNamed:@"thumbCircle"]];
    [circleView setAlpha:0.0];
    [circleView setHidden:YES];
    [self addSubview:circleView];
}

- (UIImageView*)getThumbView{
    return circleView;
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
