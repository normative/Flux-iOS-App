//
//  KTPlaceholderTextView.m
//  Flux
//
//  Created by Kei Turner on 2013-07-31.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "KTPlaceholderTextView.h"


static CGFloat const kDashedBorderWidth     = (2.0f);
static CGFloat const kDashedPhase           = (0.0f);
static CGFloat const kDashedLinesLength[]   = {4.0f, 2.0f};
static size_t const kDashedCount            = (2.0f);


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
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isEditing:) name:UITextViewTextDidChangeNotification object:self];
    placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(12, -20, self.frame.size.width, 75)];
    
    //font
    [placeholderLabel setFont:self.font];
    [placeholderLabel setBackgroundColor:[UIColor clearColor]];
    [placeholderLabel setTextColor:[UIColor lightGrayColor]];
    
    
    UIImageView*dottedBorder = [[UIImageView alloc]initWithFrame:placeholderLabel.frame];
    [dottedBorder setImage:[UIImage imageNamed:@""]];
    [self addSubview:dottedBorder];
    
    charCount = [[UILabel alloc]initWithFrame:CGRectMake(self.frame.size.width-30, self.frame.size.height-15, 30, 15)];
    [charCount setTextAlignment:NSTextAlignmentRight];
    [charCount setFont:self.font];
    [charCount setBackgroundColor:[UIColor clearColor]];
    [charCount setTextColor:[UIColor whiteColor]];
    [charCount setHidden:YES];
    [self addSubview:charCount];
    
    [self setDelegate:self];
}

#pragma mark - setters

- (void)SetPlaceholderText:(NSString*)thePlaceholder{
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
    if (![self.text isEqualToString:[NSString stringWithFormat:@""]]) {
        [placeholderLabel setHidden:YES];
        [charCount setHidden:NO];
        [charCount setText:[NSString stringWithFormat:@"%i",141-self.text.length]];
        if (self.text.length > 135) {
            [charCount setTextColor:[UIColor redColor]];
        }
        else{
            [charCount setTextColor:[UIColor whiteColor]];
        }
        if (self.text.length >= 141) {
            self.text = [self.text substringToIndex:141];
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
#warning add dotted border here
//- (void)drawRect:(CGRect)rect
//{
//    [super drawRect:rect];
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetLineWidth(context, kDashedBorderWidth);
//    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
//    CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount) ;
//    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
//    CGContextStrokeRect(context, rect);
//}




@end
