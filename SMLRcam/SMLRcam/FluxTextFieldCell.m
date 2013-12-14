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

    switch (position) {
            //top
        case 0:
        {
            CALayer *roundBorderLayer = [CALayer layer];
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+90);
            [self.layer addSublayer:roundBorderLayer];
        }
            
            break;
            //sides + top
        case 1:
        {
            CALayer *roundBorderLayer = [CALayer layer];
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+10);
            [self.layer addSublayer:roundBorderLayer];
        }
            break;
            
            //sides + top separator
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
            
            //top+bottom
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
            
            //middle no top/bottom
        case 4:
        {
            CALayer *roundBorderLayer = [CALayer layer];
            roundBorderLayer.cornerRadius = 5;
            roundBorderLayer.borderWidth = 0.5;
            roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
            roundBorderLayer.frame = CGRectMake(0, -10, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)+10);
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
