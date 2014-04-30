//
//  IDMCaptionView.m
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 30/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IDMCaptionView.h"
#import "IDMPhoto.h"
#import "UIActionSheet+Blocks.h"
#import <QuartzCore/QuartzCore.h>
#import "UICKeyChainStore.h"

#import "FluxDataManager.h"
#import "ProgressHUD.h"

#define IS_4INCHSCREEN  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE

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

@synthesize delegate;

- (id)initWithPhoto:(id<IDMPhoto>)photo {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
        [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenBound.size.height;
    }
    
    
    self = [super initWithFrame:CGRectMake(0, 0, screenWidth, 104)]; // Random initial frame
    if (self) {
        _photo = photo;
        self.opaque = NO;
        
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
    CGSize PETE = CGSizeMake(rectSize.size.width, rectSize.size.height+labelPadding * 2 + 40);
    return CGSizeMake(rectSize.size.width, 120);
}

- (void)resizeCaption:(CGRect)newFrame{
//    [self.captionView setFrame:CGRectMake(self.captionView.frame.origin.x, self.captionView.frame.origin.y, newFrame.size.width, newFrame.size.height)];
    [self.captionView layoutSubviews];
}

- (void)setupCaption {
    // Instantiate the nib content without any reference to it.
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"FluxPhotoCaptionView" owner:nil options:nil];
    
    // Find the view among nib contents (not too hard assuming there is only one view in it).
    self.captionView = (FluxPhotoCaptionView*)[nibContents lastObject];
    [self.captionView setDelegate:self];
    
    [self.captionView setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    if (!IS_4INCHSCREEN) {
        [self.captionView setCenter:CGPointMake(self.captionView.center.x, self.captionView.center.y-15)];
    }
    
    
    
    [self.captionView setupWithPhoto:_photo];
    [self.captionView setIsActiveUser:[self isActiveUserCheck]];
    
    [self addSubview:self.captionView];
}

- (void)setupProfilePicture{
    if (self.captionView.isActiveUser) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *picPath = [defaults objectForKey:@"profileImage"];
        if (picPath && ([[NSFileManager defaultManager] fileExistsAtPath:[defaults objectForKey:@"profileImage"]]))
        {
            NSData *pngData = [NSData dataWithContentsOfFile:[defaults objectForKey:@"profileImage"]];
            UIImage *image = [UIImage imageWithData:pngData];
            [self.captionView.profilePicButton setBackgroundImage:image forState:UIControlStateNormal];
        }
    }
    else{
        // request the image
        FluxDataRequest *picRequest = [[FluxDataRequest alloc]init];
        [picRequest setUserPicReady:^(UIImage*img, int userID, FluxDataRequest *completedRequest){
            if (img) {
                [self.captionView.profilePicButton setBackgroundImage:img forState:UIControlStateNormal];
            }
        }];
        [picRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            
        }];
        [[FluxDataManager theFluxDataManager] requestUserProfilePicForID:[_photo userID] andSize:@"smallthumb" withDataRequest:picRequest];
    }
}

- (void)setBackground {
    if (!IS_4INCHSCREEN) {
        UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, -300, 10000, 130+300)]; // Static width, autoresizingMask is not working
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = fadeView.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0 alpha:1.0] CGColor], nil];
        [fadeView.layer insertSublayer:gradient atIndex:0];
        fadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; //UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:fadeView];
    }
    else{
        UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, -100, 10000, 130+100)]; // Static width, autoresizingMask is not working
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = fadeView.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0 alpha:0.8] CGColor], nil];
        [fadeView.layer insertSublayer:gradient atIndex:0];
        fadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; //UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:fadeView];
    }
}


- (void)profileTapped{
    if ([delegate respondsToSelector:@selector(CaptionView:didSelectUsername:andProfileImage:)]) {
        [delegate CaptionView:self didSelectUsername:[_photo username] ? [_photo username] : @"" andProfileImage:nil];
    }
}

- (CGRect)captionFrame{
    return captionLabel.frame;
}

- (BOOL)isActiveUserCheck{
    NSString*activeUserID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    return [_photo userID] == activeUserID.intValue;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(NSStringFromCGPoint([(UITouch*)[touches anyObject]locationInView:self]));
}



#pragma mark - Flux CaptionView Delegate
- (void)FluxCaptionView:(FluxPhotoCaptionView *)captionView didSelectUsername:(NSString *)username andProfileImage:(UIImage *)profPic{
    if ([delegate respondsToSelector:@selector(CaptionView:didSelectUsername:andProfileImage:)]) {
        [delegate CaptionView:self didSelectUsername:[_photo username] ? [_photo username] : @"" andProfileImage:nil];
    }
}

- (void)FluxCaptionViewShouldEditAnnotation:(FluxPhotoCaptionView *)captionView{
    NSLog(@"Should Edit Annotation");
    if ([delegate respondsToSelector:@selector(CaptionViewShouldEditAnnotation:)]) {
        [delegate CaptionViewShouldEditAnnotation:self];
    }
}
- (void)FluxCaptionViewShouldSavePhoto:(FluxPhotoCaptionView *)captionView{
    NSLog(@"Should Save it locally");
    if ([_photo underlyingImage]) {
        UIImageWriteToSavedPhotosAlbum([_photo underlyingImage], nil, nil, nil);
    }
}
- (void)FluxCaptionViewShouldReportPhoto:(FluxPhotoCaptionView *)captionView{
    NSLog(@"Should report the image");
}

@end
