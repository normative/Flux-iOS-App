//
//  FluxProfileCell.h
//  Flux
//
//  Created by Kei Turner on 11/27/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTPlaceholderTextView.h"



@interface FluxProfileCell : UITableViewCell{
    UILabel*editLabel;
}
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *profileImageButton;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *bioLabel;
@property (strong, nonatomic) IBOutlet UILabel *imageCountLabel;
@property (strong, nonatomic) IBOutlet UIImageView *cameraImageView;

@property (strong, nonatomic) IBOutlet UIButton *editButton;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet KTPlaceholderTextView *bioField;


- (void)initCellisEditing:(BOOL)isEditing;
- (void)hideCamStats;

- (void)setUsernameText:(NSString*)text;
- (void)setBioText:(NSString*)text;

@end
