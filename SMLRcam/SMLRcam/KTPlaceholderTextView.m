//
//  KTPlaceholderTextView.m
//  Flux
//
//  Created by Kei Turner on 2013-07-31.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "KTPlaceholderTextView.h"
#import <QuartzCore/QuartzCore.h>


//static CGFloat const kDashedBorderWidth     = (2.0f);
//static CGFloat const kDashedPhase           = (0.0f);
//static CGFloat const kDashedLinesLength[]   = {4.0f, 2.0f};
//static size_t const kDashedCount            = (2.0f);


@implementation KTPlaceholderTextView

@synthesize theDelegate;

- (id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib {
    [self setFont:[UIFont fontWithName:@"Akkurat" size:self.font.pointSize]];
    [self setTextColor:[UIColor whiteColor]];
    
    self.layoutManager.delegate = self;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isEditing:) name:UITextViewTextDidChangeNotification object:self];
    placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(12, -22, self.frame.size.width, 75)];
    
    //font
    [placeholderLabel setFont:self.font];
    [placeholderLabel setBackgroundColor:[UIColor clearColor]];
    [placeholderLabel setTextColor:[UIColor lightGrayColor]];
    
    charCount = [[UILabel alloc]initWithFrame:CGRectMake(self.frame.size.width-50, self.frame.size.height-20, 30, 15)];
    [charCount setTextAlignment:NSTextAlignmentRight];
    [charCount setFont:self.font];
    [charCount setBackgroundColor:[UIColor clearColor]];
    [charCount setTextColor:[UIColor whiteColor]];
    [charCount setHidden:YES];
    
    maxCount = 141;
    [self addSubview:charCount];
    
    [self setDelegate:self];
}

- (void)setCharCountVisible:(BOOL)visible{
    if (visible) {
        if (![charCount superview]) {
            [self addSubview:charCount];
            [placeholderLabel setCenter:CGPointMake(placeholderLabel.center.x, placeholderLabel.center.y+2)];
        }
    }
    else{
        [charCount removeFromSuperview];
        [placeholderLabel setCenter:CGPointMake(placeholderLabel.center.x, placeholderLabel.center.y-2)];
    }
}

- (void)setMaxCharCount:(int)count{
    maxCount = count;
}

#pragma mark - setters

- (void)setPlaceholderText:(NSString*)thePlaceholder{
    placeholderString = thePlaceholder;
    [placeholderLabel setText: placeholderString];
    [self addSubview:placeholderLabel];
}

- (void)setPlaceholderColor:(UIColor*)color{
    [placeholderLabel setTextColor:color];
}

- (void)resetView{
    self.text = @"";
    [placeholderLabel setHidden:NO];
    [charCount setHidden:YES];
}


#pragma mark - Callbacks
//called on each keypress. Checks if the textView is blank. If it is, it shows the Placeholder label
- (void) isEditing:(NSNotification*) notification {
    
    if ([theDelegate respondsToSelector:@selector(PlaceholderTextViewDidEdit:)]) {
        [theDelegate PlaceholderTextViewDidEdit:self];
    }
    
    if (![self.text isEqualToString:[NSString stringWithFormat:@""]]) {
        [placeholderLabel setHidden:YES];
        [charCount setHidden:NO];
        
        if (self.text.length > maxCount) {
            self.text = [self.text substringToIndex:maxCount];
            if ([theDelegate respondsToSelector:@selector(PlaceholderTextViewDidGoBeyondMax:)]) {
                [theDelegate PlaceholderTextViewDidGoBeyondMax:self];
            }
        }
        else{
            if ([theDelegate respondsToSelector:@selector(PlaceholderTextViewDidReturnWithinMax:)]) {
                [theDelegate PlaceholderTextViewDidReturnWithinMax:self];
            }
            [charCount setText:[NSString stringWithFormat:@"%i",maxCount-(int)self.text.length]];
            if (self.text.length > 135) {
                [charCount setTextColor:[UIColor redColor]];
            }
            else{
                [charCount setTextColor:[UIColor whiteColor]];
            }
        }
    }
    else{
        [placeholderLabel setHidden:NO];
        [charCount setHidden:YES];
    }
}

- (void)setText:(NSString *)text{
    [super setText:text];
    if (![self.text isEqualToString:[NSString stringWithFormat:@""]]) {
        [placeholderLabel setHidden:YES];
        [charCount setHidden:NO];
        
        if (self.text.length > maxCount) {
            self.text = [self.text substringToIndex:maxCount];
            if ([theDelegate respondsToSelector:@selector(PlaceholderTextViewDidGoBeyondMax:)]) {
                [theDelegate PlaceholderTextViewDidGoBeyondMax:self];
            }
        }
        else{
            if ([theDelegate respondsToSelector:@selector(PlaceholderTextViewDidReturnWithinMax:)]) {
                [theDelegate PlaceholderTextViewDidReturnWithinMax:self];
            }
            [charCount setText:[NSString stringWithFormat:@"%i",maxCount-(int)self.text.length]];
            if (self.text.length > 135) {
                [charCount setTextColor:[UIColor redColor]];
            }
            else{
                [charCount setTextColor:[UIColor whiteColor]];
            }
        }
    }
    else{
        [placeholderLabel setHidden:NO];
        [charCount setHidden:YES];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if ([theDelegate respondsToSelector:@selector(PlaceholderTextViewDidBeginEditing:)]) {
        [theDelegate PlaceholderTextViewDidBeginEditing:self];
    }
    return YES;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    CGRect originalRect = [super caretRectForPosition:position];
    // Resize the rect. For example make it 75% by height:
    originalRect.size.height = self.font.lineHeight;
    return originalRect;
}

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect
{
    return 4;
}




@end
