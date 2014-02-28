//
//  FluxSearchCell.m
//  Flux
//
//  Created by Kei Turner on 2014-02-27.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSearchCell.h"

@implementation FluxSearchCell

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


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if ([delegate respondsToSelector:@selector(SearchCell:didType:)]) {
        [delegate SearchCell:self didType:searchText];
    }
}

@end
