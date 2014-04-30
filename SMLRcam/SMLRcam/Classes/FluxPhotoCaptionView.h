//
//  FluxPhotoCaptionView.h
//  Flux
//
//  Created by Kei Turner on 2014-04-29.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IDMPhoto.h"

@class FluxPhotoCaptionView;
@protocol FluxPhotoCaptionViewDelegate <NSObject>
@optional
- (void)FluxCaptionView:(FluxPhotoCaptionView *)captionView didSelectUsername:(NSString*)username andProfileImage:(UIImage*)profPic;
- (void)FluxCaptionViewShouldEditAnnotation:(FluxPhotoCaptionView *)captionView;
- (void)FluxCaptionViewShouldSavePhoto:(FluxPhotoCaptionView *)captionView;
- (void)FluxCaptionViewShouldReportPhoto:(FluxPhotoCaptionView *)captionView;

@end


@interface FluxPhotoCaptionView : UIView{
    
    id __unsafe_unretained delegate;
}
@property (nonatomic) BOOL isActiveUser;
@property (unsafe_unretained) id <FluxPhotoCaptionViewDelegate> delegate;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UIButton *usernameButton;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UIButton *profilePicButton;
@property (strong, nonatomic) IBOutlet UIButton *extraButton;
@property (strong, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) IBOutlet UILabel *captionLabel;
@property (strong, nonatomic) IBOutlet UIView *lineView;
- (IBAction)profilePicButtonAction:(id)sender;
- (IBAction)usernameButtonAction:(id)sender;
- (IBAction)extraButtonAction:(id)sender;
- (IBAction)editButtonAction:(id)sender;

-(void)setupWithPhoto:(IDMPhoto*)photo;

@end
