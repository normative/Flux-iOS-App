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
    circleView = [[UIImageView alloc]initWithFrame:self.bounds];
    [circleView setFrame:CGRectMake(0, 0, self.frame.size.width*1.3, self.frame.size.height*1.3)];
    [circleView setCenter:CGPointMake(self.frame.size.width/2, self.frame.size.height/2)];
    [circleView setImage:[UIImage imageNamed:@"camCircle"]];
    [circleView setAlpha:0.0];
    [circleView setHidden:YES];
    [self addSubview:circleView];
}

- (UIImageView*)getThumbView{
    return circleView;
}

- (void)setCaptureMode:(FluxImageCaptureMode)captureMode{
    _captureMode = captureMode;
    if (captureMode == camera_mode) {
        [self setImage:[UIImage imageNamed:@"camButton"] forState:UIControlStateNormal];
    }
    else{
        [self setImage:[UIImage imageNamed:@"snapshotButton"] forState:UIControlStateNormal];
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
