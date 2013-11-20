//
//  KTPlaceholderTextView.m
//  Flux
//
//  Created by Kei Turner on 2013-07-31.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "KTPlaceholderTextView.h"
#import <QuartzCore/QuartzCore.h>


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
    placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(12, -22, self.frame.size.width, 75)];
    
    //font
    [placeholderLabel setFont:self.font];
    [placeholderLabel setBackgroundColor:[UIColor clearColor]];
    [placeholderLabel setTextColor:[UIColor lightGrayColor]];
    
    
    UIImageView*dottedBorder = [[UIImageView alloc]initWithFrame:placeholderLabel.frame];
    [dottedBorder setImage:[UIImage imageNamed:@""]];
    [self addSubview:dottedBorder];
    
    charCount = [[UILabel alloc]initWithFrame:CGRectMake(self.frame.size.width-50, self.frame.size.height-20, 30, 15)];
    [charCount setTextAlignment:NSTextAlignmentRight];
    [charCount setFont:self.font];
    [charCount setBackgroundColor:[UIColor clearColor]];
    [charCount setTextColor:[UIColor whiteColor]];
    [charCount setHidden:YES];
    [self addSubview:charCount];
    
//    // Create the path (with only the top-left corner rounded)
//    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
//                                                   byRoundingCorners:UIRectCornerTopLeft
//                                                         cornerRadii:CGSizeMake(10.0, 10.0)];
//    
//    // Create the shape layer and set its path
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.frame = self.bounds;
//    maskLayer.path = maskPath.CGPath;
//    
//    // Set the newly created shape layer as the mask for the image view's layer
//    self.layer.mask = maskLayer;
    
    [self setDelegate:self];
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

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetLineWidth(context, kDashedBorderWidth);
//    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
//    //CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount) ;
//    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
//    CGContextStrokeRect(context, rect);
    
    
//    // Drawing with a white stroke color
//    CGContextRef context=UIGraphicsGetCurrentContext();
//    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
//    
//    // If you were making this as a routine, you would probably accept a rectangle
//    // that defines its bounds, and a radius reflecting the "rounded-ness" of the rectangle.
//    CGFloat radius = 10.0;
//    // NOTE: At this point you may want to verify that your radius is no more than half
//    // the width and height of your rectangle, as this technique degenerates for those cases.
//    
//    // In order to draw a rounded rectangle, we will take advantage of the fact that
//    // CGContextAddArcToPoint will draw straight lines past the start and end of the arc
//    // in order to create the path from the current position and the destination position.
//    
//    // In order to create the 4 arcs correctly, we need to know the min, mid and max positions
//    // on the x and y lengths of the given rectangle.
//    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
//    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);
//    
//    // Next, we will go around the rectangle in the order given by the figure below.
//    //       minx    midx    maxx
//    // miny    2       3       4
//    // midy   1 9              5
//    // maxy    8       7       6
//    // Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't
//    // form a closed path, so we still need to close the path to connect the ends correctly.
//    // Thus we start by moving to point 1, then adding arcs through each pair of points that follows.
//    // You could use a similar tecgnique to create any shape with rounded corners.
//    
//    // Start at 1
//    CGContextMoveToPoint(context, minx, midy);
//    // Add an arc through 2 to 3
//    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
//    // Add an arc through 4 to 5
//    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
//    // Add an arc through 6 to 7
//    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
//    // Add an arc through 8 to 9
//    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
//    // Close the path 
//    CGContextClosePath(context); 
//    // Fill & stroke the path 
//    CGContextDrawPath(context, kCGPathFillStroke);
    CGFloat radius = 10.0;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetLineWidth(context, kDashedBorderWidth);
    
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height - radius);
    CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + rect.size.height - radius,
                    radius, M_PI, M_PI / 2, 1); //STS fixed
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - radius,
                            rect.origin.y + rect.size.height);
    CGContextAddArc(context, rect.origin.x + rect.size.width - radius,
                    rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + radius);
    CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius,
                    radius, 0.0f, -M_PI / 2, 1);
    CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y);
    CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius,
                    -M_PI / 2, M_PI, 1);
    
    CGContextFillPath(context);

}




@end
