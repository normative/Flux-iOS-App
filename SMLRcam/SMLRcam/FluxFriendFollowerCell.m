//
//  FluxFriendFollowerCell.m
//  Flux
//
//  Created by Kei Turner on 1/17/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxFriendFollowerCell.h"


@implementation FluxFriendFollowerCell

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

- (void)initCell{
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
    
    self.titleLabel.font = [UIFont fontWithName:@"Akkurat" size:self.titleLabel.font.pointSize];
    
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height/2;
    self.profileImageView.clipsToBounds = YES;
    
    //add a white stroke to the image
//    UIRectCorner corners = UIRectCornerBottomLeft | UIRectCornerBottomRight;
//    CGSize radii = CGSizeMake(self.profileImageView.frame.size.height/2, self.profileImageView.frame.size.height/2);
//    
//    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.profileImageView.bounds
//                                               byRoundingCorners:corners
//                                                     cornerRadii:radii];
//    
//    // Mask the container view’s layer to round the corners.
//    CAShapeLayer *cornerMaskLayer = [CAShapeLayer layer];
//    [cornerMaskLayer setPath:path.CGPath];
//    
//    // Make a transparent, stroked layer which will dispay the stroke.
//    CAShapeLayer *strokeLayer = [CAShapeLayer layer];
//    strokeLayer.path = path.CGPath;
//    strokeLayer.fillColor = [UIColor clearColor].CGColor;
//    strokeLayer.strokeColor = [UIColor whiteColor].CGColor;
//    strokeLayer.lineWidth = 1; // the stroke splits the width evenly inside and outside,
//    // but the outside part will be clipped by the containerView’s mask.
//    [self.profileImageView.layer addSublayer:strokeLayer];
}

- (IBAction)friendFollowButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(FriendFollowerCellButtonWasTapped:)]) {
        [delegate FriendFollowerCellButtonWasTapped:self];
    }
    
}
@end
