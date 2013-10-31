//
//  FluxDrawerButtonTableViewCell.m
//  Flux
//
//  Created by Denis Delorme on 9/4/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDrawerButtonTableViewCell.h"

@implementation FluxDrawerButtonTableViewCell

@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onButtonPress:(id)sender
{
    if([delegate respondsToSelector:@selector(ButtonCell:buttonWasTapped:)])
    {
        [delegate ButtonCell:self buttonWasTapped:sender];
    }
}
@end
