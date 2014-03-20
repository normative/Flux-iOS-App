//
//  FluxTutorialView.h
//  Flux
//
//  Created by Jacky So on 17/3/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxDisplayManager.h"

@protocol FluxTutorialDelegate;

extern const int LABEL_HORIZONTAL_PADDING;

@interface FluxTutorialView : UIView <UIScrollViewDelegate>
{
    __weak IBOutlet UIImageView *tutorialRadarIV;
    __weak IBOutlet UIImageView *tutorialTimelineIV;
    __weak IBOutlet UIImageView *tutorialImageCountIV;
    __weak IBOutlet UIImageView *tutorialProfileIV;
    __weak IBOutlet UIImageView *tutorialCameraIV;
    __weak IBOutlet UIImageView *tutorialSnaphotIV;
    
    __weak IBOutlet UIImageView *tutorialRaderBarIV;
    __weak IBOutlet UIImageView *tutorialTimelineBarIV;
    __weak IBOutlet UIImageView *tutorialImageCountBarIV;
    __weak IBOutlet UIImageView *tutorialProfileBarIV;
    __weak IBOutlet UIImageView *tutorialCameraBarIV;
    __weak IBOutlet UIImageView *tutorialWindowBarIV;
    
    __weak IBOutlet UIScrollView *tutorialScrollView;
    
    id<FluxTutorialDelegate> delegate;
}
@property id<FluxTutorialDelegate> delegate;
@end

@protocol FluxTutorialDelegate <NSObject>
- (void) didPressGetStartedBtn;
@end