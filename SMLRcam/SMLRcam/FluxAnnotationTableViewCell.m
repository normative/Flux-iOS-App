//
//  FluxAnnotationTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxAnnotationTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@implementation FluxAnnotationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code

    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]) {
        [self.descriptionLabel setAdjustsFontSizeToFitWidth:YES];
        [self.descriptionLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.descriptionLabel.font.pointSize]];
        [self.userLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.userLabel.font.pointSize]];
        [self.timestampLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.timestampLabel.font.pointSize]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



@end
