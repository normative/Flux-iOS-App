//
//  FluxSocialFilterCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTCheckboxButton.h"
#import "FluxDataFilter.h"
#import "FluxCheckboxCell.h"



@class FluxSocialFilterCell;
@protocol SocialFilterTableViewCellDelegate <NSObject>
@optional
- (void)SocialCell:(FluxSocialFilterCell *)checkCell boxWasChecked:(BOOL)checked;
@end

@interface FluxSocialFilterCell : FluxCheckboxCell <KTCheckboxButtonDelegate>{
    id __unsafe_unretained socialCellDelegate;
}

@property (nonatomic)FluxFilterType filterType;


@property (unsafe_unretained) id <SocialFilterTableViewCellDelegate> socialCellDelegate;

@end
