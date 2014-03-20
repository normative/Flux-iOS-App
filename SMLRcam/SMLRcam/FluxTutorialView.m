//
//  FluxTutorialView.m
//  Flux
//
//  Created by Jacky So on 17/3/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxTutorialView.h"

#define IS_4INCHSCREEN  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE
const int HORIZONTAL_PADDING = 35;


@interface FluxTutorialView ()
@property (nonatomic, strong) NSArray *tutorialImagesArray;
@property (nonatomic, strong) NSArray *tutorialBarImagesArray;
@end

@implementation FluxTutorialView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        if (IS_4INCHSCREEN) {
            self = [[[NSBundle mainBundle] loadNibNamed:@"FluxTutorialView" owner:self options:nil] objectAtIndex:0];
        }
        else{
            self = [[[NSBundle mainBundle] loadNibNamed:@"FluxTutorialView_35" owner:self options:nil] objectAtIndex:0];
        }
        
        

        
        NSArray *tutorialTextArray = [[NSArray alloc] initWithObjects:
                                      @"Use the compass to find content around you. Tap it to explore the map.",
                                      @"Swipe up and down using the whole screen to browse images through time.",
                                      @"This shows the number of images around you. Tap it to bring up some filters.",
                                      @"View your profile, change settings and explore your access your followers.",
                                      @"Take a new photo and add it to Flux.",
                                      @"See something interesting? Take a freeze-frame snapshot and share it with friends.",
                                      @"Get Started!",
                                      nil];
        
        _tutorialImagesArray = [[NSArray alloc] initWithObjects: tutorialRadarIV, tutorialTimelineIV, tutorialImageCountIV, tutorialProfileIV, tutorialCameraIV, tutorialSnaphotIV, nil];
        _tutorialBarImagesArray = [[NSArray alloc] initWithObjects: tutorialRaderBarIV, tutorialTimelineBarIV, tutorialImageCountBarIV, tutorialProfileBarIV, tutorialCameraBarIV, tutorialWindowBarIV, nil];
        
        
        

        
        [tutorialScrollView setPagingEnabled:YES];
        [tutorialScrollView setContentSize:CGSizeMake(frame.size.width * tutorialTextArray.count, frame.size.height)];
        
        for (int i = 0; i < tutorialTextArray.count; i++) {
            if (i == tutorialTextArray.count - 1) {
                UIButton *tutorialButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width * i + 90, (IS_4INCHSCREEN ? 269 : 230), 150, 30)];
                tutorialButton.titleLabel.textColor = [UIColor whiteColor];
                tutorialButton.titleLabel.font = [UIFont fontWithName:@"Akkurat-Bold" size:18];
                [tutorialButton setTitle:[tutorialTextArray objectAtIndex:i] forState:UIControlStateNormal];
                
                [tutorialButton addTarget:self
                                   action:@selector(onGetStartedBtn:)
                         forControlEvents:UIControlEventTouchUpInside];
                
                [tutorialScrollView addSubview:tutorialButton];
            } else {
                CGRect rect = CGRectMake(frame.size.width * i + HORIZONTAL_PADDING, 0, frame.size.width - (HORIZONTAL_PADDING * 2), frame.size.height);
                
                UILabel *tutorialLabel = [[UILabel alloc] initWithFrame:rect];
                tutorialLabel.textColor = [UIColor whiteColor];
                
                // Setting the line height
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[tutorialTextArray objectAtIndex:i]];
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                [paragraphStyle setLineSpacing:8];
                [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [[tutorialTextArray objectAtIndex:i] length])];
                tutorialLabel.attributedText = attributedString;
                
                tutorialLabel.numberOfLines = 4;
                tutorialLabel.textAlignment = NSTextAlignmentCenter;
                tutorialLabel.font = [UIFont fontWithName:@"Akkurat" size:18];
                [tutorialScrollView addSubview:tutorialLabel];
            }
        }
    }
    return self;
}

#pragma mark - scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxOpenGLShouldRender object:self userInfo:nil];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    int currPageIndex = scrollView.contentOffset.x / scrollView.frame.size.width;
    
    if (currPageIndex == _tutorialImagesArray.count) {
        [UIView animateWithDuration: 0.5
                         animations:^{
                             for (int i = 0; i < _tutorialImagesArray.count; i++) {
                                 UIImageView *itemIV = [_tutorialImagesArray objectAtIndex:i];
                                 itemIV.alpha = 1;
                                 
                                 UIImageView *barItemIV = [_tutorialBarImagesArray objectAtIndex:i];
                                 barItemIV.alpha = 0;
                             }
                         }
                         completion:^(BOOL finished){
                         }];
    } else {
        [UIView animateWithDuration: 0.5
                         animations:^{
                             for (int i = 0; i < _tutorialImagesArray.count; i++) {
                                 if (i == currPageIndex) {
                                     UIImageView *fadeInItemIV = [_tutorialImagesArray objectAtIndex:i];
                                     fadeInItemIV.alpha = 1;
                                     UIImageView *fadeInBarItemIV = [_tutorialBarImagesArray objectAtIndex:i];
                                     fadeInBarItemIV.alpha = 1;
                                 } else {
                                     UIImageView *fadeOutItemIV = [_tutorialImagesArray objectAtIndex:i];
                                     if (fadeOutItemIV.alpha > 0.0 || i<currPageIndex) {
                                         fadeOutItemIV.alpha = 0.3;
                                         UIImageView *fadeOutBarItemIV = [_tutorialBarImagesArray objectAtIndex:i];
                                         fadeOutBarItemIV.alpha = 0.3;
                                     }
                                 }
                             }
                         }
                         completion:^(BOOL finished){
                         }];
    }
}

#pragma mark - IBAction

- (IBAction)onGetStartedBtn:(id)sender {
    if ([delegate respondsToSelector:@selector(didPressGetStartedBtn)]) {
        [delegate didPressGetStartedBtn];
    }
}

@end
