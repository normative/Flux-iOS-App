//
//  FluxTimeFilterScrollView.m
//  Flux
//
//  Created by Kei Turner on 2013-10-21.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxTimeFilterScrollView.h"

@implementation FluxTimeFilterScrollView

@synthesize tapDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setDelaysContentTouches:YES];
        tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleSingleTap:)];
        [tapRecognizer requireGestureRecognizerToFail:self.panGestureRecognizer];
        [self addGestureRecognizer:tapRecognizer];

    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        //custom init

        [self setDelaysContentTouches:YES];
        
        tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleSingleTap:)];
        [tapRecognizer requireGestureRecognizerToFail:self.panGestureRecognizer];
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:nil];
    if ([tapDelegate respondsToSelector:@selector(timeFilterScrollView:didTapAtPoint:)]) {
        [tapDelegate timeFilterScrollView:self didTapAtPoint:location];
    }
}

-(BOOL)touchesShouldCancelInContentView:(UIView *)view{
    NSLog(@"Cancelled scrollView tap");
    return YES;
}

- (void)setContentSize:(CGSize)contentSize{
    [super setContentSize:contentSize];
    if (!subview) {
        subview = [[UIView alloc]initWithFrame:CGRectMake(0, 0, contentSize.width, contentSize.height)];
        [self addSubview:subview];
    }
    else
        [subview setFrame:CGRectMake(0, 0, contentSize.width, contentSize.height)];
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
