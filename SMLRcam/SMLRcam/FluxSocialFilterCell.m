//
//  FluxSocialFilterCell.m
//  Flux
//
//  Created by Kei Turner on 11/1/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxSocialFilterCell.h"

@implementation FluxSocialFilterCell

@synthesize socialCellDelegate;


-(void)setFilterType:(FluxFilterType)filterType{
    _filterType = filterType;
    if (filterType == myPhotos_filterType) {
        [self.descriptorLabel setText:@"My Photos"];
    }
    else if (filterType == followers_filterType){
        [self.descriptorLabel setText:@"People I follow"];
    }
    else if (filterType == friends_filterType){
        [self.descriptorLabel setText:@"Friends"];
    }
    else{
        
    }
}

- (void)CheckBoxButtonWasTapped:(KTCheckboxButton *)checkButton andChecked:(BOOL)checked{
    [self setIsActive:checked];
    if ([socialCellDelegate respondsToSelector:@selector(SocialCell:boxWasChecked:)]) {
        [socialCellDelegate SocialCell:self boxWasChecked:checked];
    }
}

@end
