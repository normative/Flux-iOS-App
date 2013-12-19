//
//  FluxProfileCell.h
//  Flux
//
//  Created by Kei Turner on 11/27/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface FluxProfileCell : UITableViewCell{
    UILabel*editLabel;
}
@property (strong, nonatomic) IBOutlet UIButton *profileImageButton;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *bioLabel;
@property (strong, nonatomic) IBOutlet UILabel *imageCountLabel;
@property (strong, nonatomic) IBOutlet UIImageView *cameraImageView;
@property (strong, nonatomic) IBOutlet UIButton *editButton;


- (void)initCellisEditing:(BOOL)isEditing;
- (void)hideCamStats;

@end
