//
//  FluxLeftDrawerCustomTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-01.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDrawerSwitchTableViewCell.h"

@implementation FluxDrawerSwitchTableViewCell

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
        [self.theLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.theLabel.font.pointSize]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)SwtichDidChange:(id)sender {
    if([delegate respondsToSelector:@selector(SwitchCell:switchWasTapped:)])
    {
        [delegate SwitchCell:self switchWasTapped:sender];
    }
}
@end
