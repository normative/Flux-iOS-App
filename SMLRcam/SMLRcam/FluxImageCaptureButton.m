//
//  FluxImageCaptureButton.m
//  Flux
//
//  Created by Kei Turner on 2/3/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxImageCaptureButton.h"
#import "FluxImageCaptureViewController.h"

@implementation FluxImageCaptureButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib{
    [self commonInit];
}

- (void)commonInit{
    self.picCount = 0;
    self.singleImageCaptureMode = NO;
    self.button = [[FluxCameraButton alloc]initWithFrame:CGRectMake(10, 14, 70, 70)];
    boxedCountView = [[FluxBoxedImageCountView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 8)];
    [boxedCountView setCenter:CGPointMake(88, boxedCountView.center.y)];
    [self addSubview:self.button];
    [self addSubview:boxedCountView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUndoCapture) name:FluxImageCaptureDidUndoCapture object:nil];
}

- (void)dealloc{
    if (self.buttonEnableTimer)
    {
        [self.buttonEnableTimer invalidate];
        self.buttonEnableTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxImageCaptureDidUndoCapture object:nil];
}

- (void)setCaptureMode:(FluxImageCaptureMode)captureMode{
    _captureMode = captureMode;
    if (captureMode == camera_mode) {
        [self.button setImage:[UIImage imageNamed:@"camButton"] forState:UIControlStateNormal];
        [boxedCountView setHidden:NO];
    }
    else{
        [self.button setImage:[UIImage imageNamed:@"snapshotButton"] forState:UIControlStateNormal];
        [boxedCountView setHidden:YES];
    }
}

- (void)didUndoCapture{
    [self removeImageCapture];
}

//- (void)targetMethod:(NSTimer*)theTimer {
//    [self.button setEnabled:YES];
//    [self setButtonEnableTimer:nil];
//}

- (void)addImageCapture{
    self.picCount ++;
    if (boxedCountView.markCount > 0) {
        [UIView animateWithDuration:0.3 animations:^{
            [boxedCountView setFrame:CGRectMake(boxedCountView.frame.origin.x-3.8, boxedCountView.frame.origin.y, boxedCountView.frame.size.width,boxedCountView.frame.size.height)];
        }];
    }
    [boxedCountView addImageCapture];
    
    if ((self.picCount == 4) || self.singleImageCaptureMode)
    {
        [self.button setEnabled:NO];
    }
    else
    {
        [self.button setEnabled:YES];
//        self.buttonEnableTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
//                                                                  target:self
//                                                                selector:@selector(targetMethod:)
//                                                                userInfo:nil
//                                                                 repeats:NO];
    }

}

- (void)removeImageCapture{
    self.picCount --;
    if (boxedCountView.markCount > 1) {
        [UIView animateWithDuration:0.3 animations:^{
            [boxedCountView setFrame:CGRectMake(boxedCountView.frame.origin.x+3.8, boxedCountView.frame.origin.y, boxedCountView.frame.size.width,boxedCountView.frame.size.height)];
        }];
    }
    if ((self.picCount == 3) || self.singleImageCaptureMode)
    {
        [self.button setEnabled:YES];
    }

    [boxedCountView removeImageCapture];
}

- (void)restoreAllImages{
    self.picCount = 0;
    [boxedCountView restoreAllBoxes];
    [boxedCountView setCenter:CGPointMake(86, boxedCountView.center.y)];
    [self.button setEnabled:YES];
}



@end
