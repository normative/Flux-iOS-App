//
//  FluxImportContactCell.h
//  Flux
//
//  Created by Kei Turner on 2014-02-27.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxContactObject.h"



@class FluxImportContactCell;
@protocol FluxImportContactCellDelegate <NSObject>
@optional
- (void)ImportContactCell:(FluxImportContactCell *)importContactCell shouldInvite:(FluxContactObject*)contact;
- (void)ImportContactCellFriendFollowButtonWasTapped:(FluxImportContactCell *)importContactCell;
@end


@interface FluxImportContactCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
    NSString*serviceType;
}

@property (unsafe_unretained) id <FluxImportContactCellDelegate> delegate;

@property (nonatomic, strong)FluxContactObject*contactObject;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel*socialStatusLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIImageView *socialTypeImageView;
-(void)initCellWithType:(NSString*)type;
- (IBAction)inviteButtonAction:(id)sender;
- (IBAction)contactButtonAction:(id)sender;


@end