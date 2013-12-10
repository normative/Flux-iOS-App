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
    
    
    
    
    //[self.layer addSublayer:rightBorder];

    switch (position) {
        case 0:
        {
            CALayer *roundBorderLayer = [CALayer layer];
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+10);
            [self.layer addSublayer:roundBorderLayer];
        }
            
            break;
        case 1:
        {
            CALayer *roundBorderLayer = [CALayer layer];
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+10);
            [self.layer addSublayer:roundBorderLayer];
        }
            break;
        case 2:
        {
            CALayer *roundBorderLayer = [CALayer layer];
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, -10, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+10);
            [self.layer addSublayer:roundBorderLayer];
            
            CALayer *topLineLayer = [CALayer layer];
            topLineLayer.borderWidth = 0.5;
            topLineLayer.borderColor = [UIColor whiteColor].CGColor;
            topLineLayer.frame = CGRectMake(0, 0.5, CGRectGetWidth(self.frame)-0.5, 0.5);
            [self.layer addSublayer:topLineLayer];
        }
            break;
            
        case 3:
        {
            CALayer *roundBorderLayer = [CALayer layer];
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
            [self.layer addSublayer:roundBorderLayer];
        }
            break;
            
        default:
            break;
    }
    //[self insertSubview:imgView belowSubview:self.checkImageView];
    if (!self.textField) {
        self.textField = [[FluxTextField alloc]initWithFrame:self.bounds andPlaceholderText:placeholder];
        [self addSubview:self.textField];
    }
    else{
        [self.textField setPlaceholder:placeholder];
    }
    
    [self.checkImageView setImage:[UIImage imageNamed:@"check"]];
    [self.checkImageView setHidden:YES];
}

- (void)setChecked:(BOOL)checked{
    if (checked) {
        [self.checkImageView setHidden:NO];
    }
    else{
        [self.checkImageView setHidden:YES];
    }
}

@end
