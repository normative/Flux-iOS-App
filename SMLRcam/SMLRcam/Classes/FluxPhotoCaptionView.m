//
//  FluxPhotoCaptionView.m
//  Flux
//
//  Created by Kei Turner on 2014-04-29.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxPhotoCaptionView.h"
#import "UIActionSheet+Blocks.h"

@implementation FluxPhotoCaptionView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //[self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self ) {
        //[self commonInit];
    }
    
    return self;
}

- (void)commonInit{
    self.isActiveUser = NO;
    [self.editButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self.extraButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    
    [self.editButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.extraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.dateLabel setTextColor:[UIColor whiteColor]];
    [self.usernameLabel setTextColor:[UIColor whiteColor]];
    [self.captionLabel setTextColor:[UIColor whiteColor]];
    
    [self.editButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.editButton.titleLabel.font.pointSize]];
    [self.profilePicButton setTitle:@"" forState:UIControlStateNormal];
    [self.dateLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.dateLabel.font.pointSize]];
    [self.captionLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.captionLabel.font.pointSize]];
    [self.usernameLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.usernameLabel.font.pointSize]];
    
    [self.usernameButton setTitle:@"" forState:UIControlStateNormal];
    [self.usernameButton setAlpha:0.0];

    
    self.captionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.captionLabel.backgroundColor = [UIColor clearColor];
    self.captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.captionLabel.numberOfLines = 4;
    self.captionLabel.textColor = [UIColor whiteColor];
    [self.captionLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.captionLabel.font.pointSize]];
    
    [self.profilePicButton setBackgroundImage:[UIImage imageNamed:@"emptyProfileImage_small"]forState:UIControlStateNormal];
    self.profilePicButton.layer.cornerRadius = self.profilePicButton.frame.size.height/2;
    self.profilePicButton.layer.masksToBounds = YES;
    
    [self.editButton setHidden:YES];
    [self.extraButton setHidden:YES];
    
    [self.lineView setFrame:CGRectMake(self.lineView.frame.origin.x, self.lineView.frame.origin.y, self.lineView.frame.size.width, 0.5)];
}

-(void)setupWithPhoto:(IDMPhoto *)photo{
    [self commonInit];
    [self.usernameLabel setText:[NSString stringWithFormat:@"@%@",photo.username]];
    [self.dateLabel setText:[self relativeDateStringForDate:photo.timestamp]];
    [self.captionLabel setText:photo.caption];
//    [self.captionLabel setCenter:CGPointMake(self.captionLabel.center.x, self.captionLabel.center.y-20)];
    
    if ([photo respondsToSelector:@selector(caption)]) {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:[photo caption] ? [photo caption] : @" "];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineHeightMultiple:1.3];
        
        [str addAttribute:NSParagraphStyleAttributeName
                    value:style
                    range:NSMakeRange(0, str.length)];
        self.captionLabel.attributedText = str;
    }
    
}

- (NSString*)relativeDateStringForDate:(NSDate *)date{
    NSCalendar *c = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    NSCalendarUnit units = NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSWeekOfYearCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    NSDateComponents *components = [c components:units fromDate:date toDate:today options:0];
    
    if (components.year > 0) {
        if (components.year > 1) {
            return [NSString stringWithFormat:@"%ld years ago", (long)components.year];
        }
        else{
            return @"1 year ago";
        }
    } else if (components.month > 0) {
        if (components.month > 1) {
            return [NSString stringWithFormat:@"%ld months ago", (long)components.month];
        }
        else{
            return @"1 month ago";
        }
    } else if (components.weekOfYear > 0) {
        if (components.weekOfYear > 1) {
            return [NSString stringWithFormat:@"%ld weeks ago", (long)components.weekOfYear];
        }
        else{
            return @"1 week ago";
        }
    } else if (components.day > 0) {
        if (components.day > 1) {
            return [NSString stringWithFormat:@"%ld days ago", (long)components.day];
        } else {
            return @"Yesterday";
        }
    } else if (components.hour > 0){
        if (components.hour > 1) {
            return [NSString stringWithFormat:@"%ld hours ago", (long)components.hour];
        }
        else{
            return @"1 hour ago";
        }
    } else if (components.minute > 0){
        if (components.minute > 1) {
            return [NSString stringWithFormat:@"%ld minutes ago", (long)components.minute];
        }
        else{
            return @"1 minute ago";
        }
    }
    else {
        return @"Just now";
    }
}

- (IBAction)profilePicButtonAction:(id)sender {
    if (!self.isActiveUser) {
        if ([delegate respondsToSelector:@selector(FluxCaptionView:didSelectUsername:andProfileImage:)]) {
            [delegate FluxCaptionView:self didSelectUsername:self.usernameLabel.text andProfileImage:nil];
        }
    }
}

- (IBAction)usernameButtonAction:(id)sender {
    if (!self.isActiveUser) {
        if ([delegate respondsToSelector:@selector(FluxCaptionView:didSelectUsername:andProfileImage:)]) {
            [delegate FluxCaptionView:self didSelectUsername:self.usernameLabel.text andProfileImage:nil];
        }
    }
}

- (IBAction)extraButtonAction:(id)sender {
    NSString*savePhoto = @"Save Photo";
    NSString*reportPhoto = @"Report Photo";
    
    NSArray*buttonTitles;
    
    if (self.isActiveUser) {
        buttonTitles = [NSArray arrayWithObject:savePhoto];
    }
    else{
        buttonTitles = [NSArray arrayWithObjects:savePhoto, reportPhoto, nil];
    }
            [UIActionSheet showInView:self
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:nil
                    otherButtonTitles:buttonTitles
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     //link facebook
                                     if (buttonIndex == 0) {
                                         if ([delegate respondsToSelector:@selector(FluxCaptionViewShouldSavePhoto:)]) {
                                             [delegate FluxCaptionViewShouldSavePhoto:self];
                                         }
                                     }
                                     else{
                                         if ([delegate respondsToSelector:@selector(FluxCaptionViewShouldReportPhoto:)]) {
                                             [delegate FluxCaptionViewShouldReportPhoto:self];
                                         }
                                     }
                                 }
                             }];
}

- (void)setIsActiveUser:(BOOL)isActiveUser{
    self->_isActiveUser = isActiveUser;
    if (isActiveUser) {
//        [self.editButton setHidden:NO];
    }
}

- (IBAction)editButtonAction:(id)sender {
    if (self.isActiveUser) {
        if ([delegate respondsToSelector:@selector(FluxCaptionViewShouldEditAnnotation:)]) {
            [delegate FluxCaptionViewShouldEditAnnotation:self];
        }
    }
}
@end
