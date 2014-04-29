//
//  FluxEditCaptionView.m
//  Flux
//
//  Created by Kei Turner on 2014-04-28.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxEditCaptionView.h"

@implementation FluxEditCaptionView

@synthesize delegate;

- (UIView*)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        darkView = [[UIView alloc]initWithFrame:frame];
        [darkView setBackgroundColor:[UIColor blackColor]];
        [darkView setAlpha:0.0];
        [self addSubview:darkView];
        
        captionTextField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, 300, 45)];

        [captionTextField setFont:[UIFont fontWithName:@"Akkurat" size:captionTextField.font.pointSize]];
        [captionTextField setBackgroundColor:[UIColor clearColor]];
        [captionTextField setTextColor:[UIColor lightGrayColor]];
        [self addSubview:captionTextField];
    }
    return self;
}

- (void)animateFromFrame:(CGRect)frame withCaption:(NSString*)caption{
    sourceRect = frame;
    [captionTextField setFrame:frame];
    [captionTextField setText:caption];
    [captionTextField becomeFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        [darkView setAlpha:0.9];
        [captionTextField setCenter:self.center];
    }completion:^(BOOL finished){
        UITapGestureRecognizer*tapper = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureAction:)];
        [self addGestureRecognizer:tapper];
    }];
}

- (void)fadeToSourceRect{
    [UIView animateWithDuration:0.3 animations:^{
        [darkView setAlpha:0.0];
        [captionTextField setFrame:sourceRect];
    }completion:^(BOOL finished){
        
    }];
}


- (void)tapGestureAction:(UITapGestureRecognizer*)tapGesture{
    [self removeGestureRecognizer:tapGesture];
    [self fadeToSourceRect];
    if ([delegate respondsToSelector:@selector(EditCaptionViewDidClear:)]) {
        [delegate EditCaptionViewDidClear:self];
    }
}

@end
