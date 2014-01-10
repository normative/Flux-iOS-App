//
//  FluxSocialManagementCell.m
//  Flux
//
//  Created by Kei Turner on 1/9/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSocialManagementCell.h"

@implementation FluxSocialManagementCell

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

@end
