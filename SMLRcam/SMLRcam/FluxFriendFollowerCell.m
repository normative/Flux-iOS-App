//
//  FluxFriendFollowerCell.m
//  Flux
//
//  Created by Kei Turner on 1/17/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxFriendFollowerCell.h"


@implementation FluxFriendFollowerCell

@synthesize delegate;

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

- (void)initCell{
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
    
    self.titleLabel.font = [UIFont fontWithName:@"Akkurat" size:self.titleLabel.font.pointSize];
    
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height/2;
    self.profileImageView.clipsToBounds = YES;
    //add a white stroke to the image
    self.profileImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    self.profileImageView.layer.borderWidth = 1;
}

- (void)setUserObject:(FluxUserObject *)userObject{
    _userObject = userObject;
    
    [self.titleLabel setText:[NSString stringWithFormat:@"@%@",userObject.username]];
    if (userObject.bio) {
        [self.bioLabel setText:[NSString stringWithFormat:@"%@",userObject.bio]];
    }
    else{
        [self.bioLabel setText:@""];
    }
    
}

- (IBAction)friendFollowButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(FriendFollowerCellButtonWasTapped:)]) {
        [delegate FriendFollowerCellButtonWasTapped:self];
    }
    
}
@end
