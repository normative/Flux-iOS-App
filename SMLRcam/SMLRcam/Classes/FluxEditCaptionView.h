//
//  FluxEditCaptionView.h
//  Flux
//
//  Created by Kei Turner on 2014-04-28.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxEditCaptionView;
@protocol FluxEditCaptionViewDelegate <NSObject>
@optional
- (void)EditCaptionViewDidClear:(FluxEditCaptionView *)editCaptionView;
- (void)EditCaptionView:(FluxEditCaptionView *)editCaptionView shouldEditCaptionto:(NSString*)newCaption;
@end

@interface FluxEditCaptionView : UIView{
    UIView*darkView;
    UITextField*captionTextField;
    id __unsafe_unretained delegate;
    CGRect sourceRect;
}

@property (unsafe_unretained) id <FluxEditCaptionViewDelegate> delegate;

- (void)animateFromFrame:(CGRect)frame withCaption:(NSString*)caption;
- (void)fadeToSourceRect;

@end
