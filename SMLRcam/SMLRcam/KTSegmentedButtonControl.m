//
//  KTSegmentedButtonControl.m
//  Flux
//
//  Created by Kei Turner on 2013-09-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
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

- (void)awakeFromNib {
    buttons = [[NSMutableArray alloc]init];
    self.selectedIndex = -1;
    [self setBackgroundColor:[UIColor clearColor]];
}



- (void)initWithImages:(NSArray*)selectionArr andStandardImages:(NSArray*)standardArr{
    NSAssert(selectionArr.count == standardArr.count, @"segmented control array sizes are mismatched");
    selectionImages = [[NSArray alloc]initWithArray:selectionArr];
    standardImages = [[NSArray alloc]initWithArray:standardArr];
    [self setupButtonsWithCount:(int)selectionArr.count];
}

- (void)setSelectedSegmentIndex:(int)index{
    [(UIImageView*)[buttons objectAtIndex:index]setImage:[selectionImages objectAtIndex:index]];
    
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
            [self setSelectedSegmentIndex:(int)segment];
            if ([delegate respondsToSelector:@selector(SegmentedControlValueDidChange:)]) {
                [delegate SegmentedControlValueDidChange:self];
            }
        }
    }
}

@end
