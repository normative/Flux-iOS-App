//
//  CameraButtonView.h
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-26.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraButtonView;
@protocol CameraButtonViewDelegate <NSObject>
@optional
- (void)CameraButtonView:(CameraButtonView *)CamView buttonWasTapped:(UIButton *)theButton;
@end

@interface CameraButtonView : UIView{
    UIButton * cameraButton;
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <CameraButtonViewDelegate> delegate;


- (void)buttonTapped:(id)sender;



@end
