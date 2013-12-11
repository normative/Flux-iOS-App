//
//  FluxTextField.m
//  Flux
//
//  Created by Kei Turner on 11/8/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxTextField.h"

#define placeholderColor [UIColor colorWithRed:163/255.0 green:44/255.0 blue:44/255.0 alpha:1.0]
#define textColor [UIColor whiteColor]

int const FluxTextFieldPositionTop = 0;
int const FluxTextFieldPositionMiddle = 1;
int const FluxTextFieldPositionBottom = 2;
int const FluxTextFieldPositionTopBottom = 3;
int const FluxTextFieldPositionMiddleNoSep = 4;

@implementation FluxTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andPlaceholderText:(NSString *)placeholder{
    self = [super initWithFrame:frame];
    if (self) {

    
        self.borderStyle = UITextBorderStyleNone;
        [self setFont:[UIFont fontWithName:@"Akkurat" size:self.font.pointSize]];
        [self setTextColor:textColor];
        [self setPlaceholder:placeholder];
    }
    return self;
}


- (BOOL) canPerformAction:(SEL)action withSender:(id)sender{
    return NO;
}

@end
