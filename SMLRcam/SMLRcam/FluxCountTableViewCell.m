//
//  FluxLeftMenuCell.m
//  Flux
//
//  Created by Kei Turner on 11/11/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxCountTableViewCell.h"

@implementation FluxCountTableViewCell

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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCell{
    [badge removeFromSuperview];
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
    
    self.titleLabel.font = self.countLabel.font = [UIFont fontWithName:@"Akkurat" size:self.titleLabel.font.pointSize];
}

- (void)addBadge:(int)count{
    badge = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%i",count]
                                             withStringColor:[UIColor whiteColor]
                                              withInsetColor:[UIColor colorWithRed:234/255.0 green:63/255.0 blue:63/255.0 alpha:1.0]
                                              withBadgeFrame:NO
                                         withBadgeFrameColor:[UIColor clearColor]
                                                   withScale:1.0
                                                 withShining:NO];
    [badge setFrame:CGRectMake(self.countLabel.frame.origin.x+self.countLabel.frame.size.width-badge.frame.size.width, self.countLabel.frame.origin.y, badge.frame.size.width, badge.frame.size.height)];
    [self addSubview:badge];
}

- (void)clearBadge{
    [badge removeFromSuperview];
}


@end
