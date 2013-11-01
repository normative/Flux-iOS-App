//
//  FluxDrawerCheckboxFilterTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTCheckboxButton.h"

@class FluxTagFilterCell;
@protocol TagFilterTableViewCellDelegate <NSObject>
@optional
- (void)TagCell:(FluxTagFilterCell *)checkCell boxWasChecked:(BOOL)checked;
@end

@interface FluxTagFilterCell : UITableViewCell <KTCheckboxButtonDelegate>{
    BOOL active;
    id __unsafe_unretained delegate;
}
@property (weak, nonatomic) IBOutlet UILabel *descriptorLabel;
@property (weak, nonatomic) IBOutlet KTCheckboxButton *checkbox;


@property (unsafe_unretained) id <TagFilterTableViewCellDelegate> delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
-(void)setIsActive:(BOOL)bActive;

@end
