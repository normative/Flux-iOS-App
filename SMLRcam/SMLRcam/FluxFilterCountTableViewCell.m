//
//  FluxFilterCountTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2014-03-19.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxFilterCountTableViewCell.h"

@implementation FluxFilterCountTableViewCell

@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)hiddenButtonAciton:(id)sender {
    if ([delegate respondsToSelector:@selector(FilterCountTableViewCellButtonWasTapped:)]) {
        [delegate FilterCountTableViewCellButtonWasTapped:self];
    }
}

- (void)initCell{
    [self.descriptonLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.descriptonLabel.font.pointSize]];
    [self.countLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.countLabel.font.pointSize]];
    
    //Add a circle
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:CGPointMake(self.countLabel.center.x, self.countLabel.center.y-1)
                    radius:22.0
                startAngle:0.0
                  endAngle:M_PI * 2.0
                 clockwise:YES];
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.path = path.CGPath;
    circleLayer.strokeColor = [[UIColor whiteColor] CGColor];
    circleLayer.fillColor = nil;
    circleLayer.lineWidth = 0.5;
    [self.contentView.layer addSublayer:circleLayer];
    
    self.activityIndicatorContainerView.layer.cornerRadius = self.activityIndicatorContainerView.frame.size.width;
    [self.activityIndicatorContainerView setBackgroundColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:1.0]];
    
    self.activityIndicatorContainerView.layer.shadowColor = [[UIColor clearColor] CGColor];
    self.activityIndicatorContainerView.layer.shadowRadius = 1.0f;
    self.activityIndicatorContainerView.layer.shadowOpacity = 1.0;
    self.activityIndicatorContainerView.layer.shadowOffset = CGSizeMake(1, 1);
//    [self.activityIndicatorContainerView setAlpha:0.0];
    [self.activityIndicatorView startAnimating];
    
}

-(void)startAnimating{
//    [self.activityIndicatorContainerView setAlpha:1.0];
}

-(void)stopAnimating{
//    [self.activityIndicatorContainerView setAlpha:0.0];
}
-(void)setCount:(int)count{
    [self.countLabel setText:[NSString stringWithFormat:@"%i",count]];
}


@end
