//
//  FluxTextFieldCell.m
//  Flux
//
//  Created by Kei Turner on 11/8/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxTextFieldCell.h"

@implementation FluxTextFieldCell

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
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setupForPosition:(int)position andPlaceholder:(NSString *)placeholder{
    self.clipsToBounds = YES;
    [self.activityIndicator setHidden:YES];
    
    if (!roundBorderLayer) {
        roundBorderLayer = [CALayer layer];
    }
    
    if (!topLineLayer) {
        topLineLayer = [CALayer layer];
    }

    switch (position) {
            //top
        case 0:
        {
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+90);
            
            if (!roundBorderLayer.superlayer) {
                [self.layer addSublayer:roundBorderLayer];
            }
            [topLineLayer removeFromSuperlayer];
        }
            
            break;
            //sides + top
        case 1:
        {
            roundBorderLayer.cornerRadius = 0;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+10);
            if (!roundBorderLayer.superlayer) {
                [self.layer addSublayer:roundBorderLayer];
            }
            [topLineLayer removeFromSuperlayer];
        }
            break;
            
            //sides + top separator
        case 2:
        {
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, -10, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+10);
            
            if (!roundBorderLayer.superlayer) {
                [self.layer addSublayer:roundBorderLayer];
            }
            
            topLineLayer.borderWidth = 0.5;
            topLineLayer.borderColor = [UIColor whiteColor].CGColor;
            topLineLayer.frame = CGRectMake(0, 0.5, CGRectGetWidth(self.frame)-0.5, 0.5);
            
            if (!topLineLayer.superlayer) {
                [self.layer addSublayer:topLineLayer];
            }
        }
            break;
            
            //top+bottom
        case 3:
        {
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
            
            if (!roundBorderLayer.superlayer) {
                [self.layer addSublayer:roundBorderLayer];
            }
            [topLineLayer removeFromSuperlayer];
        }
            break;
            
            //middle no top/bottom
        case 4:
        {
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, -10, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+10);
            
            if (!roundBorderLayer.superlayer) {
                [self.layer addSublayer:roundBorderLayer];
            }
            [topLineLayer removeFromSuperlayer];
        }
            break;

            
            
        default:
            break;
    }
    //[self insertSubview:imgView belowSubview:self.checkImageView];
    if (!self.textField) {
        self.textField = [[FluxTextField alloc]initWithFrame:CGRectMake(35, 0, self.frame.size.width-35-35, self.frame.size.height) andPlaceholderText:placeholder];
        [self addSubview:self.textField];
    }
    else{
        [self.textField setPlaceholder:placeholder];
    }
    
    [self.checkImageView setImage:[UIImage imageNamed:@"check"]];
    [self.checkImageView setHidden:YES];
}

- (void)setChecked:(BOOL)checked{
    self.isChecked = checked;
    if (checked) {
        [self.checkImageView setHidden:NO];
    }
    else{
        [self.checkImageView setHidden:YES];
    }
}

- (void)setLoading:(BOOL)loading{
    if (loading) {
        [self setChecked:NO];
        [self.activityIndicator setHidden:NO];
        [self.activityIndicator startAnimating];
    }
    else{
        [self.activityIndicator setHidden:YES];
        [self.activityIndicator stopAnimating];
    }
}

@end
