//
//  IDMCaptionView.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 30/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IDMCaptionView.h"
#import "IDMPhoto.h"
#import <QuartzCore/QuartzCore.h>

#import "FluxDataManager.h"
#import "ProgressHUD.h"


static const CGFloat labelPadding = 10;

// Private
@interface IDMCaptionView () {
    id<IDMPhoto> _photo;
    UILabel *captionLabel;
    UILabel *timestampLabel;
    UIButton *userameButton;
    UIButton *userProfileImageButton;
    UIImageView *clockImageView;
}
@end

@implementation IDMCaptionView

@synthesize delegate, displaysProfileInfo;

- (id)initWithPhoto:(id<IDMPhoto>)photo {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
        [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenBound.size.height;
    }
    
    self = [super initWithFrame:CGRectMake(0, 0, screenWidth, 44)]; // Random initial frame
    if (self) {
        _photo = photo;
        self.opaque = NO;
        self.displaysProfileInfo = YES;
        
        [self setBackground];
        
        [self setupCaption];
    }
    

    
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat maxHeight = MAXFLOAT;
    //here is the part interesting us
    NSAttributedString* theText = captionLabel.attributedText;
    maxHeight = captionLabel.font.leading*captionLabel.numberOfLines;
    CGRect rectSize = [theText boundingRectWithSize:CGSizeMake(self.bounds.size.width, maxHeight) options:NSStringDrawingUsesLineFragmentOrigin context:NULL];
    return CGSizeMake(rectSize.size.width, rectSize.size.height+labelPadding * 2 + 40);
}

- (void)setupCaption {
    captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelPadding, 0,
                                                             self.bounds.size.width-labelPadding*2,
                                                             self.bounds.size.height-90)];
    captionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    captionLabel.backgroundColor = [UIColor clearColor];
    captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    captionLabel.numberOfLines = 4;
    captionLabel.textColor = [UIColor whiteColor];
    [captionLabel setFont:[UIFont fontWithName:@"Akkurat" size:14]];
    if ([_photo respondsToSelector:@selector(caption)]) {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:[_photo caption] ? [_photo caption] : @" "];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineHeightMultiple:1.1];
        [str addAttribute:NSParagraphStyleAttributeName
                    value:style
                    range:NSMakeRange(0, str.length)];
        captionLabel.attributedText = str;
    }
    [self addSubview:captionLabel];
    
    userameButton = [[UIButton alloc]initWithFrame:CGRectMake(37, self.bounds.size.height, 145, 20)];
    userameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    userameButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [userameButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [userameButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:14]];

    if ([_photo respondsToSelector:@selector(username)]) {
        [userameButton setTitle:[_photo username] ? [_photo username] : @" " forState:UIControlStateNormal];
    }
    [userameButton addTarget:self action:@selector(profileTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:userameButton];
    
    userProfileImageButton = [[UIButton alloc]initWithFrame:CGRectMake(10, self.bounds.size.height, 20, 20)];
    [userProfileImageButton setBackgroundImage:[UIImage imageNamed:@"emptyProfileImage_small"]forState:UIControlStateNormal];
    userProfileImageButton.layer.cornerRadius = userProfileImageButton.frame.size.height/2;
    userProfileImageButton.layer.masksToBounds = YES;
    
    // request the image
    FluxDataRequest *picRequest = [[FluxDataRequest alloc]init];
    [picRequest setUserPicReady:^(UIImage*img, int userID, FluxDataRequest *completedRequest){
        [userProfileImageButton setBackgroundImage:img forState:UIControlStateNormal];

    }];
    [picRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
//        NSString*str = [NSString stringWithFormat:@"Profile picture failed with error %d", (int)[e code]];
//        [ProgressHUD showError:str];
    }];
    [[FluxDataManager theFluxDataManager] requestUserProfilePicForID:[_photo userID] andSize:@"smallthumb" withDataRequest:picRequest];

    [userProfileImageButton setCenter:CGPointMake(userProfileImageButton.center.x, userameButton.center.y)];
    [userProfileImageButton addTarget:self action:@selector(profileTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:userProfileImageButton];
    
    timestampLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.bounds.size.width-168, self.bounds.size.height, 158, 20)];
    timestampLabel.backgroundColor = [UIColor clearColor];
    timestampLabel.textAlignment = NSTextAlignmentRight;
    timestampLabel.textColor = [UIColor whiteColor];
    [timestampLabel setFont:[UIFont fontWithName:@"Akkurat" size:14]];
    if ([_photo respondsToSelector:@selector(timestring)]) {
        timestampLabel.text = [_photo timestring] ? [_photo timestring] : @" ";
    }
    [self addSubview:timestampLabel];
    
    clockImageView = [[UIImageView alloc]initWithFrame:CGRectMake(timestampLabel.frame.origin.x-15, self.bounds.size.height, 20, 20)];
    [clockImageView setImage:[UIImage imageNamed:@"imageViewerClock"]];
    [clockImageView setCenter:CGPointMake(clockImageView.center.x, userameButton.center.y)];
    [self addSubview:clockImageView];
    
    [userameButton setCenter:CGPointMake(userameButton.center.x, userProfileImageButton.center.y)];
    [clockImageView setCenter:CGPointMake(clockImageView.center.x, userProfileImageButton.center.y)];
    [timestampLabel setCenter:CGPointMake(timestampLabel.center.x, userProfileImageButton.center.y)];
    
    if (!displaysProfileInfo) {
        [userameButton removeFromSuperview];
        [userProfileImageButton removeFromSuperview];
    }
}

- (void)setBackground {
    UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, -100, 10000, 130+100)]; // Static width, autoresizingMask is not working
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = fadeView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0 alpha:0.8] CGColor], nil];
    [fadeView.layer insertSublayer:gradient atIndex:0];
    fadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; //UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:fadeView];
}


- (void)profileTapped{
    if ([delegate respondsToSelector:@selector(CaptionView:didSelectUsername:andProfileImage:)]) {
        [delegate CaptionView:self didSelectUsername:[_photo username] ? [_photo username] : @"" andProfileImage:nil];
    }
}
@end
