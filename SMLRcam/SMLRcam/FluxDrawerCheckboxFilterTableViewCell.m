//
//  FluxDrawerCheckboxFilterTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDrawerCheckboxFilterTableViewCell.h"

@implementation FluxDrawerCheckboxFilterTableViewCell

@synthesize delegate;

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
        [self setBackgroundColor:[UIColor clearColor]];
        [self.descriptorLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.descriptorLabel.font.pointSize]];
    }
    return self;
}

//callback when the cell was tapped. this will set the cell to active for now.
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [self setIsActive:selected];
    [super setSelected:selected animated:animated];
    
//    [self setIsActive:!active];
//    active = !active;
//    
//    if ([delegate respondsToSelector:@selector(CheckboxCell:boxWasChecked:)]) {
//        [delegate  CheckboxCell:self boxWasChecked:active];
//    }
}

//for now setting the cell active just makes it bold, checks the checkmark
-(void)setIsActive:(BOOL)bActive{
    active = bActive;
    if (active) {
        //[self.descriptorLabel setFont:[UIFont boldSystemFontOfSize:self.descriptorLabel.font.pointSize]];
        [self.descriptorLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.descriptorLabel.font.pointSize]];
        [self.descriptorLabel setTextColor:[UIColor whiteColor]];
    }
    else{
        //[self.descriptorLabel setFont:[UIFont systemFontOfSize:self.descriptorLabel.font.pointSize]];
        [self.descriptorLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.descriptorLabel.font.pointSize]];
        [self.descriptorLabel setTextColor:[UIColor lightGrayColor]];
    }
    [self.checkbox setChecked:active];
}

//the checkbox was tapped
- (void)CheckBoxButtonWasTapped:(KTCheckboxButton *)checkButton andChecked:(BOOL)checked{
    [self setIsActive:checked];
    
    if ([delegate respondsToSelector:@selector(CheckboxCell:boxWasChecked:)]) {
        [delegate  CheckboxCell:self boxWasChecked:checked];
    }
}

@end
