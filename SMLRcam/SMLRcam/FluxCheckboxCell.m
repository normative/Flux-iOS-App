//
//  FluxDrawerCheckboxFilterTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxCheckboxCell.h"

@implementation FluxCheckboxCell

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
        [self.countLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.countLabel.font.pointSize]];
        [self.descriptorLabel setTextColor:[UIColor whiteColor]];
        [self.countLabel setTextColor:[UIColor whiteColor]];
        [self.checkbox setDelegate:self];
    }
    return self;
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    [self setIsActive:!active];
//    [self CheckBoxButtonWasTapped:self.checkbox andChecked:active];
//}

//for now setting the cell active just makes it bold, checks the checkmark
-(void)setIsActive:(BOOL)bActive{
    active = bActive;
    [self.checkbox setChecked:active];
}

-(void)cellWasTapped{
    [self CheckBoxButtonWasTapped:self.checkbox andChecked:!active];
}

//the checkbox was tapped
- (void)CheckBoxButtonWasTapped:(KTCheckboxButton *)checkButton andChecked:(BOOL)checked{
    [self setIsActive:checked];
    if ([delegate respondsToSelector:@selector(checkboxCell:boxWasChecked:)]) {
        [delegate checkboxCell:self boxWasChecked:checked];
    }
}

-(BOOL)isChecked{
    return active;
}

@end
