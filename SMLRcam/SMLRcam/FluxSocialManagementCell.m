//
//  FluxSocialManagementCell.m
//  Flux
//
//  Created by Kei Turner on 1/9/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSocialManagementCell.h"

@implementation FluxSocialManagementCell

@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.isActivated = NO;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)cellButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(SocialManagementCellButtonWasTapped:)]) {
        [delegate SocialManagementCellButtonWasTapped:self];
    }
}

-(void)initCell{
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
    [self.cellButton setHidden:NO];
    
    [self.socialPartnerLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.socialPartnerLabel.font.pointSize]];
    [self.socialDescriptionLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.socialDescriptionLabel.font.pointSize]];
    [self.cellButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.cellButton.titleLabel.font.pointSize]];
}

@end
