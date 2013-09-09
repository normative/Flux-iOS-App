//
//  KTPlaceholderTextView.m
//  Flux
//
//  Created by Kei Turner on 2013-07-31.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "KTPlaceholderTextView.h"

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
    placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(12, -20, 200, 75)];
    [placeholderLabel setFont:self.font];
    [placeholderLabel setBackgroundColor:[UIColor clearColor]];
    [placeholderLabel setTextColor:[UIColor lightGrayColor]];
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
}


#pragma mark - Callbacks
//called on each keypress. Checks if the textView is blank. If it is, it shows the Placeholder label
- (void) isEditing:(NSNotification*) notification {
    if (![self.text isEqualToString:[NSString stringWithFormat:@""]]) {
        [placeholderLabel setHidden:YES];
        if (self.text.length >= 142) {
            self.text = [self.text substringToIndex:141];
        }
    }
    else{
        [placeholderLabel setHidden:NO];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if ([theDelegate respondsToSelector:@selector(PlaceholderTextViewDidBeginEditing:)]) {
        [theDelegate PlaceholderTextViewDidBeginEditing:self];
    }
    return YES;
}


@end
