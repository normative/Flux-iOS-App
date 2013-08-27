//
//  FluxHashtagTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-22.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxHashtagTableViewCell.h"

@implementation FluxHashtagTableViewCell

@synthesize hashTextView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
        [self.hashTextView setDelegate:self];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //[super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    NSLog(@"Should begin editing");
}

-(void)textViewDidChange:(UITextView *)textView{
    NSLog(@"I'm typing");
}





@end
