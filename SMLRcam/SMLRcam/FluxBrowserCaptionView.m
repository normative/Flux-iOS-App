//
//  FluxBrowserCaptionView.m
//  Flux
//
//  Created by Kei Turner on 11/18/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxBrowserCaptionView.h"

@implementation FluxBrowserCaptionView

- (void)setupCaption{
    captionLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, self.bounds.size.width-10*2, self.bounds.size.height-50)];
    captionLabel.backgroundColor = [UIColor clearColor];
    captionLabel.textAlignment = NSTextAlignmentCenter;
    captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    captionLabel.numberOfLines = 3;
    captionLabel.textColor = [UIColor whiteColor];
    [captionLabel setFont:[UIFont fontWithName:@"Akkurat" size:17]];
    if ([_photo respondsToSelector:@selector(caption)]) {
        captionLabel.text = [_photo caption] ? [_photo caption] : @" ";
    }
    [self addSubview:captionLabel];
    
    usernameLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, self.bounds.size.height-50, 100, 50)];
    usernameLabel.backgroundColor = [UIColor clearColor];
    usernameLabel.textAlignment = NSTextAlignmentLeft;
    usernameLabel.textColor = [UIColor whiteColor];
    [usernameLabel setFont:[UIFont fontWithName:@"Akkurat" size:17]];
    if ([_photo respondsToSelector:@selector(username)]) {
        usernameLabel.text = [(FluxBrowserPhoto*)_photo username] ? [(FluxBrowserPhoto*)_photo username] : @" ";
    }
    [self addSubview:usernameLabel];
    
    usernameImageView = [[UIImageView alloc]initWithFrame:CGRectMake(10, self.bounds.size.height-50, 30, 30)];
    [usernameImageView setImage:[UIImage imageNamed:@"checkbox_checked"]];
    [usernameImageView setCenter:CGPointMake(usernameImageView.center.x, usernameLabel.center.y)];
    [self addSubview:usernameImageView];
    
    timestampLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.bounds.size.width-200, self.bounds.size.height-50, 200-10, 50)];
    timestampLabel.backgroundColor = [UIColor clearColor];
    timestampLabel.textAlignment = NSTextAlignmentRight;
    timestampLabel.textColor = [UIColor whiteColor];
    [timestampLabel setFont:[UIFont fontWithName:@"Akkurat" size:17]];
    if ([_photo respondsToSelector:@selector(timestring)]) {
        timestampLabel.text = [(FluxBrowserPhoto*)_photo timestring] ? [(FluxBrowserPhoto*)_photo timestring] : @" ";
    }
    [self addSubview:timestampLabel];
    
    clockImageView = [[UIImageView alloc]initWithFrame:CGRectMake(self.bounds.size.width-240, self.bounds.size.height-50, 30, 30)];
    [clockImageView setImage:[UIImage imageNamed:@"imageViewerClock"]];
    [clockImageView setCenter:CGPointMake(clockImageView.center.x, usernameLabel.center.y)];
    [self addSubview:clockImageView];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat maxHeight = 9999;
    if (captionLabel.numberOfLines > 0) maxHeight = captionLabel.font.lineHeight*captionLabel.numberOfLines;
    CGSize textSize = [captionLabel.text sizeWithFont:captionLabel.font
                              constrainedToSize:CGSizeMake(size.width - 10*2, maxHeight)
                                  lineBreakMode:captionLabel.lineBreakMode];
    return CGSizeMake(size.width, textSize.height + 10 * 2);
}

@end
