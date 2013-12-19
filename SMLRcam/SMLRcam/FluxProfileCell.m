//
//  FluxProfileCell.m
//  Flux
//
//  Created by Kei Turner on 11/27/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxProfileCell.h"

@implementation FluxProfileCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)hideCamStats{
    [self.imageCountLabel setHidden:YES];
    [self.cameraImageView setHidden:YES];
}

- (void)initCellisEditing:(BOOL)isEditing{
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
    
    [self.usernameLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.usernameLabel.font.pointSize]];
    self.bioLabel.font = self.imageCountLabel.font = [UIFont fontWithName:@"Akkurat" size:self.imageCountLabel.font.pointSize];
    
    self.profileImageButton.layer.cornerRadius = self.profileImageButton.frame.size.height/2;
    self.profileImageButton.clipsToBounds = YES;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if (isEditing) {
        if (!editLabel) {
            editLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.profileImageButton.frame.size.height-25, self.profileImageButton.frame.size.width, 25)];
            editLabel.textColor = self.bioLabel.textColor;
            [editLabel setTextAlignment:NSTextAlignmentCenter];
            [editLabel setText:@"Edit"];
            editLabel.font = [UIFont fontWithName:@"Akkurat" size:13.0];
            [editLabel setBackgroundColor:[UIColor lightGrayColor]];
            [editLabel setAlpha:0.5];
        }
        if (!editLabel.superview) {
            [self.profileImageButton addSubview:editLabel];
        }
        [self.editButton setHidden:YES];
        [self.profileImageButton setUserInteractionEnabled:YES];
    }
    else{
        [editLabel removeFromSuperview];
        [self.editButton setHidden:NO];
        [self.profileImageButton setUserInteractionEnabled:NO];
    }
}

@end
