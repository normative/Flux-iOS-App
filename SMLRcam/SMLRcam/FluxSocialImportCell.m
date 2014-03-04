//
//  FluxSocialImportCell.m
//  Flux
//
//  Created by Kei Turner on 2/19/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSocialImportCell.h"


@implementation FluxSocialImportCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)initCell{
    [self.headerLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.headerLabel.font.pointSize]];
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTheTitle:(NSString*)title{
    [self.headerLabel setText:title];
    if ([title isEqualToString:@"Twitter"]) {
        [self.serviceImageView setImage:[UIImage imageNamed:@"import_twitter"]];
    }
    else if ([title isEqualToString:@"Facebook"]){
        [self.serviceImageView setImage:[UIImage imageNamed:@"import_facebook"]];
    }
    else if ([title isEqualToString:@"Contacts"]){
        [self.serviceImageView setImage:[UIImage imageNamed:@"import_contact"]];
    }
    else{
        
    }
}
@end
