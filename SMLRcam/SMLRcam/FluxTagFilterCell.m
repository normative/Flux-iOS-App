//
//  FluxDrawerCheckboxFilterTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxTagFilterCell.h"

@implementation FluxTagFilterCell

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
        [self.descriptorLabel setTextColor:[UIColor whiteColor]];
        [self.checkbox setDelegate:self];
    }
    return self;
}

//for now setting the cell active just makes it bold, checks the checkmark
-(void)setIsActive:(BOOL)bActive{
    active = bActive;
    [self.checkbox setChecked:active];
}

//the checkbox was tapped
- (void)CheckBoxButtonWasTapped:(KTCheckboxButton *)checkButton andChecked:(BOOL)checked{
    [self setIsActive:checked];
    if ([delegate respondsToSelector:@selector(TagCell:boxWasChecked:)]) {
        [delegate TagCell:self boxWasChecked:checked];
    }

}

@end
