//
//  FluxCheckboxButton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "KTCheckboxButton.h"

@implementation KTCheckboxButton

@synthesize delegate;


- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]) {
        checked = NO;
        [self setCheckedImage:[UIImage imageNamed:@"filter_Checked.png"] andUncheckedImg:[UIImage imageNamed:@"filter_Unchecked.png"]];
        
        
        [self setCheckImage:checked];
        [self setTitle:@"" forState:UIControlStateNormal];
        
        [self setAdjustsImageWhenHighlighted:NO];
        [self addTarget:self action:@selector(buttonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setCheckedImage:(UIImage *)aCheckedImg andUncheckedImg:(UIImage *)aUncheckedImg{
    checkImg = aCheckedImg;
    uncheckedImg = aUncheckedImg;
}

- (void)buttonWasTapped:(KTCheckboxButton*)sender{
    checked = !checked;
    
    if ([delegate respondsToSelector:@selector(CheckBoxButtonWasTapped:andChecked:)]) {
        [delegate  CheckBoxButtonWasTapped:self andChecked:checked];
    }
}

- (void)setCheckImage:(BOOL)aChecked{
    if (aChecked) {
        [self setBackgroundImage:checkImg forState:UIControlStateNormal];
        [self setAlpha:1.0];
    }
    else{
        [self setBackgroundImage:uncheckedImg forState:UIControlStateNormal];
        [self setAlpha:0.3];
    }
}

- (void)setChecked:(BOOL)aChecked{
    checked = aChecked;
    [self setCheckImage:checked];
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
