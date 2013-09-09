//
//  KTSegmentedButtonControl.m
//  Flux
//
//  Created by Kei Turner on 2013-09-09.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "KTSegmentedButtonControl.h"

#define buttonSpacing 30
#define buttonFrameWidth 50

@implementation KTSegmentedButtonControl

@synthesize delegate;

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

- (void)awakeFromNib {
    buttons = [[NSMutableArray alloc]init];
    self.selectedIndex = -1;
    [self setBackgroundColor:[UIColor clearColor]];
}



- (void)initWithImages:(NSArray*)selectionArr andStandardImages:(NSArray*)standardArr{
    NSAssert(selectionArr.count == standardArr.count, @"segmented control array sizes are mismatched");
    selectionImages = [[NSArray alloc]initWithArray:selectionArr];
    standardImages = [[NSArray alloc]initWithArray:standardArr];
    [self setupButtonsWithCount:selectionArr.count];
}

- (void)setSelectedSegmentIndex:(int)index{
    //[self performSelector:@selector(highlightButton:) withObject:(UIButton*)[buttons objectAtIndex:index] afterDelay:0.0];
    [(UIImageView*)[buttons objectAtIndex:index]setImage:[selectionImages objectAtIndex:index]];
    //[[buttons objectAtIndex:index] setHighlighted:YES];
    
    if (self.selectedIndex >=0) {
        [(UIImageView*)[buttons objectAtIndex:self.selectedIndex]setImage:[standardImages objectAtIndex:self.selectedIndex]];
    }
    self.selectedIndex = index;
}

- (void)setupButtonsWithCount:(int)count{
    
    //magic numbers :(
    float xpos = 5;
    
    for (int i = 0; i<count; i++) {
        UIImageView *btnView = [[UIImageView alloc]initWithFrame:CGRectMake(xpos, 0, buttonFrameWidth, self.frame.size.height)];
        [btnView setImage:[standardImages objectAtIndex:i]];
//        [btn setBackgroundImage:[standardImages objectAtIndex:i] forState:UIControlStateNormal];
//        [btn setBackgroundImage:[selectionImages objectAtIndex:i] forState:UIControlStateHighlighted];
//        //[btn addTarget:self action:@selector(buttonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
//        [btn setContentMode:UIViewContentModeScaleAspectFit];
//        [btn setAdjustsImageWhenHighlighted:NO];
        [self addSubview:btnView];
        [buttons addObject:btnView];
        xpos += buttonFrameWidth+buttonSpacing;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.bounds, touchLocation)) {
        NSInteger segment = touchLocation.x / (buttonFrameWidth+buttonSpacing);
        
        if (segment != self.selectedIndex) {
            [self setSelectedSegmentIndex:segment];
            if ([delegate respondsToSelector:@selector(SegmentedControlValueDidChange:)]) {
                [delegate SegmentedControlValueDidChange:self];
            }
        }
    }
}

- (void)buttonWasTapped:(id)sender{
    [self performSelector:@selector(highlightButton:) withObject:sender afterDelay:0.0];
    
    for (UIButton* btn in buttons){
        if (sender == btn) {
            self.selectedIndex = [buttons indexOfObject:btn];
            if ([delegate respondsToSelector:@selector(SegmentedControlValueDidChange:)]) {
                [delegate SegmentedControlValueDidChange:self];
            }
        }
        else{
            [btn setHighlighted:NO];
        }
    }
}

@end
