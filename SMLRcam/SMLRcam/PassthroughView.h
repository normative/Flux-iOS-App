//
//  CameraButtonView.h
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-26.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PassthroughView;
@protocol PassthroughViewDelegate <NSObject>
@optional
- (void)PassthroughView:(PassthroughView *)CamView buttonWasTapped:(UIButton *)theButton;
@end

@interface PassthroughView : UIView{
    UIButton * cameraButton;
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <PassthroughViewDelegate> delegate;


- (void)buttonTapped:(id)sender;
- (void)camButtonAction;



@end
