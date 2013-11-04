//
//  FluxAnnotationTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-12.
//  Copyright (c) 2013 SMLR. All rights reserved.
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
    }
    return self;
}

- (void)initCell{
    [self.descriptionLabel setAdjustsFontSizeToFitWidth:YES];
    [self.descriptionLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.descriptionLabel.font.pointSize]];
    [self.userLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.userLabel.font.pointSize]];
    [self.timestampLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.timestampLabel.font.pointSize]];
    [self.categoryLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.categoryLabel.font.pointSize]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCategory:(int)cat{
    switch (cat) {
        case 1:
            [self.categoryImageView setImage:[UIImage imageNamed:@"filter_People"]];
            [self.categoryLabel setText:@"Person"];
            break;
        case 2:
            [self.categoryImageView setImage:[UIImage imageNamed:@"filter_Places"]];
            [self.categoryLabel setText:@"Place"];
            break;
        case 3:
            [self.categoryImageView setImage:[UIImage imageNamed:@"filter_Things"]];
            [self.categoryLabel setText:@"Thing"];
            break;
        case 4:
            [self.categoryImageView setImage:[UIImage imageNamed:@"filter_Events"]];
            [self.categoryLabel setText:@"Event"];
            break;
            
        default:
            break;
    }
    
    float textWidth = [self.categoryLabel.text sizeWithFont:self.categoryLabel.font].width;
    float xSpacing = self.categoryLabel.frame.origin.x+textWidth+[@" " sizeWithFont:self.categoryLabel.font].width;
    [self.byLabel setFrame:CGRectMake(xSpacing, self.byLabel.frame.origin.y, self.byLabel.frame.size.width, self.byLabel.frame.size.height)];
    [self.userLabel setFrame:CGRectMake(xSpacing+[self.byLabel.text sizeWithFont:self.byLabel.font].width+[@" " sizeWithFont:self.categoryLabel.font].width, self.userLabel.frame.origin.y, self.userLabel.frame.size.width, self.userLabel.frame.size.height)];
}

//- (void)layoutSubviews{
//    [super layoutSubviews];
//    
//
//}



@end
