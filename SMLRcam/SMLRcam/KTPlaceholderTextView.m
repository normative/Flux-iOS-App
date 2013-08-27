//
//  KTPlaceholderTextView.m
//  Flux
//
//  Created by Kei Turner on 2013-07-31.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "KTPlaceholderTextView.h"

@implementation KTPlaceholderTextView

@synthesize delegate;

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
    placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, -18, 200, 75)];
    [placeholderLabel setFont:self.font];
    [placeholderLabel setBackgroundColor:[UIColor clearColor]];
    [placeholderLabel setTextColor:[UIColor lightGrayColor]];
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


#pragma mark - Callbacks
//called on each keypress. Checks if the textView is blank. If it is, it shows the Placeholder label
- (void) isEditing:(NSNotification*) notification {
    if (![self.text isEqualToString:[NSString stringWithFormat:@""]]) {
        [placeholderLabel setHidden:YES];
        if (self.text.length >= 131) {
            self.text = [self.text substringToIndex:130];
        }
    }
    else{
        [placeholderLabel setHidden:NO];
    }
    
    //tests for return key - remove for now.
    
//    if ([[self.text substringFromIndex:self.text.length-1] isEqualToString:@"\n"]) {
//        if ([delegate respondsToSelector:@selector(PlaceholderTextViewReturnButtonWasPressed:)]) {
//            [delegate PlaceholderTextViewReturnButtonWasPressed:self];
//        }
//        self.text = [self.text substringToIndex:self.text.length-1];
//    }
    
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
