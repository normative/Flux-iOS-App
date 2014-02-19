//
//  FluxDrawerCheckboxFilterTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxCheckboxCell.h"

@implementation FluxCheckboxCell

@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit{
    [self setBackgroundColor:[UIColor clearColor]];
    [self.descriptorLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.descriptorLabel.font.pointSize]];
    [self.countLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.countLabel.font.pointSize]];
    [self.descriptorLabel setTextColor:[UIColor whiteColor]];
    [self.countLabel setTextColor:[UIColor whiteColor]];
    [self.checkbox setDelegate:self];
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    [self setIsActive:!active];
//    [self CheckBoxButtonWasTapped:self.checkbox andChecked:active];
//}

//for now setting the cell active just makes it bold, checks the checkmark
-(void)setIsActive:(BOOL)bActive{
    active = bActive;
    [self.checkbox setChecked:active];
    
    if (active) {
        [self.countLabel setAlpha:1.0];
    }
    else{
        [self.countLabel setAlpha:0.5];
    }
}

-(void)cellWasTapped{
    [self CheckBoxButtonWasTapped:self.checkbox andChecked:!active];
}

//the checkbox was tapped
- (void)CheckBoxButtonWasTapped:(KTCheckboxButton *)checkButton andChecked:(BOOL)checked{
    [self setIsActive:checked];
    if ([delegate respondsToSelector:@selector(checkboxCell:boxWasChecked:)]) {
        [delegate checkboxCell:self boxWasChecked:checked];
    }
}

- (void)setTextTitle:(NSString*)title{
    if (self.isNotApplicable) {
//        NSNumber *strikeSize = [NSNumber numberWithInt:2];
//        
//        NSDictionary *attribs = @{
//                                  NSForegroundColorAttributeName: [UIColor whiteColor],
//                                  NSFontAttributeName: self.descriptorLabel.font,
//                                  NSStrikethroughStyleAttributeName : strikeSize
//                                  };
//        
//        NSAttributedString* strikeThroughText = [[NSAttributedString alloc] initWithString:title attributes:attribs];
//        
//        self.descriptorLabel.attributedText = strikeThroughText;
        
        [self.descriptorLabel setText:title];
        [self.countLabel setEnabled:NO];
        
        [self.descriptorLabel setAlpha:0.2];
        [self.checkbox setAlpha:0.5];
        [self.countLabel setAlpha:0.2];
    }
    else{
        [self.countLabel setEnabled:YES];
        [self.descriptorLabel setAlpha:1.0];
        [self.descriptorLabel setText:title];
    }
}

-(BOOL)isChecked{
    return active;
}

@end
