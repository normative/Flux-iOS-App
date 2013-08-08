//
//  FluxCheckboxButton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>


@class KTCheckboxButton;
@protocol KTCheckboxButtonDelegate <NSObject>
@optional
- (void)CheckBoxButtonWasTapped:(KTCheckboxButton *)checkButton andChecked:(BOOL)checked;
@end


@interface KTCheckboxButton : UIButton{
    UIImage*checkImg;
    UIImage*uncheckedImg;
    BOOL checked;
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <KTCheckboxButtonDelegate> delegate;

- (void)setCheckedImage:(UIImage*)aCheckedImg
        andUncheckedImg:(UIImage*)aUncheckedImg;

//used within this class to change the image
- (void)setCheckImage:(BOOL)aChecked;
- (void)buttonWasTapped:(KTCheckboxButton*)sender;

//used outside of this class to set the button state
- (void)setChecked:(BOOL)aChecked;

@end
