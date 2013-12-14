//
//  FluxTextFieldCell.h
//  Flux
//
//  Created by Kei Turner on 11/8/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxTextField.h"

@class FluxTextFieldCell;
@protocol FluxTextFieldCellDelegate <NSObject>
@optional
- (void)textFieldCell:(FluxTextFieldCell*)textFieldCell textFieldDidChange:(NSString *)text;
@end


@interface FluxTextFieldCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}
@property (nonatomic, strong) FluxTextField*textField;
@property (nonatomic, strong) UILabel*warningLabel;
@property (strong, nonatomic) IBOutlet UIImageView *checkImageView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (unsafe_unretained) id <FluxTextFieldCellDelegate> delegate;

- (void)setupForPosition:(int)position andPlaceholder:(NSString*)placeholder;
- (void)setChecked:(BOOL)checked;
- (void)setLoading:(BOOL)loading;

@end
