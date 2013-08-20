//
//  FluxDrawerSegmentedTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-20.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxDrawerSegmentedTableViewCell.h"

@implementation FluxDrawerSegmentedTableViewCell

@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
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
