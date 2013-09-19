//
//  DWTagList.m
//
//  Created by Dominic Wroblewski on 07/07/2012.
//  Copyright (c) 2012 Terracoding LTD. All rights reserved.
//

#import "DWTagList.h"
#import <QuartzCore/QuartzCore.h>
#import "FluxTagObject.h"

#define CORNER_RADIUS 0.0f
#define LABEL_MARGIN_DEFAULT 5.0f
#define BOTTOM_MARGIN_DEFAULT 5.0f
#define FONT_SIZE_DEFAULT 13.0f
#define HORIZONTAL_PADDING_DEFAULT 7.0f
#define VERTICAL_PADDING_DEFAULT 3.0f
#define BACKGROUND_COLOR [UIColor colorWithRed:0.0 green:182/255.0 blue:235/255.0 alpha:1.00]
#define TEXT_COLOR [UIColor whiteColor]
#define TEXT_SHADOW_COLOR [UIColor whiteColor]
#define TEXT_SHADOW_OFFSET CGSizeMake(0.0f, 1.0f)
#define BORDER_COLOR [UIColor lightGrayColor].CGColor
#define BORDER_WIDTH 1.0f
#define HIGHLIGHTED_BACKGROUND_COLOR [UIColor colorWithRed:0.40 green:0.80 blue:1.00 alpha:0.5]
#define DEFAULT_AUTOMATIC_RESIZE NO

@implementation DWTagList

@synthesize view, textArray, automaticResize;
@synthesize tagDelegate = _tagDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:view];
        [self setClipsToBounds:YES];
        self.automaticResize = DEFAULT_AUTOMATIC_RESIZE;
        self.highlightedBackgroundColor = HIGHLIGHTED_BACKGROUND_COLOR;
        self.font = [UIFont fontWithName:@"Akkurat" size:FONT_SIZE_DEFAULT];
        self.labelMargin = LABEL_MARGIN_DEFAULT;
        self.bottomMargin = BOTTOM_MARGIN_DEFAULT;
        self.horizontalPadding = HORIZONTAL_PADDING_DEFAULT;
        self.verticalPadding = VERTICAL_PADDING_DEFAULT;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addSubview:view];
        [self setClipsToBounds:YES];
        self.highlightedBackgroundColor = HIGHLIGHTED_BACKGROUND_COLOR;
        self.font = [UIFont fontWithName:@"Akkurat" size:FONT_SIZE_DEFAULT];
        self.labelMargin = LABEL_MARGIN_DEFAULT;
        self.bottomMargin = BOTTOM_MARGIN_DEFAULT;
        self.horizontalPadding = HORIZONTAL_PADDING_DEFAULT;
        self.verticalPadding = VERTICAL_PADDING_DEFAULT;
    }
    return self;
}

- (void)setTags:(NSArray *)array
{
    textArray = [[NSArray alloc] initWithArray:array];
    sizeFit = CGSizeZero;
    if (automaticResize) {
        [self display];
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, sizeFit.width, sizeFit.height);
    }
    else {
        [self setNeedsLayout];
    }
}

- (void)setTagBackgroundColor:(UIColor *)color
{
    lblBackgroundColor = color;
    [self setNeedsLayout];
}

- (void)setTagHighlightColor:(UIColor *)color
{
    self.highlightedBackgroundColor = color;
    [self setNeedsLayout];
}

- (void)setViewOnly:(BOOL)viewOnly
{
    if (_viewOnly != viewOnly) {
        _viewOnly = viewOnly;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self display];
}

- (void)display
{
    NSMutableArray *tagViews = [NSMutableArray array];
    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:[DWTagView class]]) {
            DWTagView *tagView = (DWTagView*)subview;
            for (UIGestureRecognizer *gesture in [subview gestureRecognizers]) {
                [subview removeGestureRecognizer:gesture];
            }
            
            [tagView.button removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            
            [tagViews addObject:subview];
        }
        [subview removeFromSuperview];
    }

    CGRect previousFrame = CGRectZero;
    BOOL gotPreviousFrame = NO;
    
    for (int i = 0;i<textArray.count;i++)
    {
        NSString * hashText = [@"#" stringByAppendingString:(NSString*)[[textArray objectAtIndex:i]tagText]];
        DWTagView *tagView;
        if (tagViews.count > 0) {
            tagView = [tagViews lastObject];
            [tagViews removeLastObject];
        }
        else {
            tagView = [[DWTagView alloc] init];
        }
        
        [tagView updateWithString:hashText
                           font:self.font
              constrainedToWidth:self.frame.size.width - (self.horizontalPadding * 2)
                        padding:CGSizeMake(self.horizontalPadding, self.verticalPadding)
                     minimumWidth:self.minimumWidth
         ];
        
        if (gotPreviousFrame) {
            CGRect newRect = CGRectZero;
            if (previousFrame.origin.x + previousFrame.size.width + tagView.frame.size.width + self.labelMargin > self.frame.size.width) {
                newRect.origin = CGPointMake(0, previousFrame.origin.y + tagView.frame.size.height + self.bottomMargin);
            } else {
                newRect.origin = CGPointMake(previousFrame.origin.x + previousFrame.size.width + self.labelMargin, previousFrame.origin.y);
            }
            newRect.size = tagView.frame.size;
            [tagView setFrame:newRect];
        }

        previousFrame = tagView.frame;
        gotPreviousFrame = YES;

        [tagView setBackgroundColor:BACKGROUND_COLOR];
        [tagView setAlpha:(1.0-i*0.05)];
        
        [self addSubview:tagView];

        if (!_viewOnly) {
            [tagView.button addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        }
    }

    sizeFit = CGSizeMake(self.frame.size.width, previousFrame.origin.y + previousFrame.size.height + self.bottomMargin + 1.0f);
    self.contentSize = sizeFit;
}

- (CGSize)fittedSize
{
    return sizeFit;
}

- (void)touchUpInside:(id)sender
{
    UIButton *button = (UIButton*)sender;
    DWTagView *tagView = (DWTagView*)button.superview;
    if (!tagView.isSelected) {
        [self setTagBackgroundStateForTagView:tagView andTagstate:tagActive];
        tagView.isSelected = YES;
    }
    else{
        [self setTagBackgroundStateForTagView:tagView andTagstate:tagInactive];
        tagView.isSelected = NO;
    }
    
    if(button && self.tagDelegate && [self.tagDelegate respondsToSelector:@selector(tagList:selectedTagWithTitle:andActive:)])
        [self.tagDelegate tagList:self selectedTagWithTitle:[button.accessibilityLabel substringFromIndex:1] andActive:tagView.isSelected];
}

- (void)setTagBackgroundStateForTagView:(UIView*)tagView andTagstate:(tagState)tagState{
    switch (tagState) {
        case tagInactive:
        {
            [tagView setBackgroundColor:BACKGROUND_COLOR];
        }
            break;
        case tagActive:
        {
            [tagView setBackgroundColor:self.highlightedBackgroundColor];
        }
        break;
        default:
            break;
    }
}

- (void)dealloc
{
    view = nil;
    textArray = nil;
    lblBackgroundColor = nil;
}

@end


@implementation DWTagView

- (id)init {
    self = [super init];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        [_label setTextColor:TEXT_COLOR];
        [_label setBackgroundColor:[UIColor clearColor]];
        [_label setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:_label];
        
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_button setFrame:self.frame];
        [self addSubview:_button];
        
        [self.layer setMasksToBounds:YES];
        self.isSelected = NO;
    }
    return self;
}

- (void)updateWithString:(NSString*)text font:(UIFont*)font constrainedToWidth:(CGFloat)maxWidth padding:(CGSize)padding minimumWidth:(CGFloat)minimumWidth
{
    CGSize textSize = [text sizeWithFont:font forWidth:maxWidth lineBreakMode:NSLineBreakByTruncatingTail];
    
    textSize.width = MAX(textSize.width, minimumWidth);
    textSize.height += padding.height*2;

    self.frame = CGRectMake(0, 0, textSize.width+padding.width*2, textSize.height);
    _label.frame = CGRectMake(padding.width, 0, MIN(textSize.width, self.frame.size.width), textSize.height);
    _label.font = font;
    _label.text = text;
    
    [_button setAccessibilityLabel:self.label.text];
}

- (void)setLabelText:(NSString*)text
{
    [_label setText:text];
}

- (void)dealloc
{
    _label = nil;
    _button = nil;
}

@end
