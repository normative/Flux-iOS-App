//
//  FluxDrawerSegmentedTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-20.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxDrawerSegmentedTableViewCell.h"

@implementation FluxDrawerSegmentedTableViewCell

@synthesize delegate,segmentedControl;

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
        [[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Akkurat" size:13.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)segmentedChanged:(id)sender {
    if ([delegate respondsToSelector:@selector(SegmentedCell:segmentedControlWasTapped:)]) {
        [delegate SegmentedCell:self segmentedControlWasTapped:sender];
    }
}
@end
