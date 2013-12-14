//
//  FluxLeftDrawerViewController.h
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "FluxDataManager.h"
#import "FluxUserObject.h"

@interface FluxLeftDrawerViewController : UITableViewController<MFMailComposeViewControllerDelegate>{
    NSMutableArray*tableViewArray;
}

@property (weak, nonatomic) IBOutlet UIView *copyrightView;
@property (strong, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLbl;

@property (nonatomic, strong) FluxDataManager *fluxDataManager;

- (IBAction)onSendFeedBackBtn:(id)sender;
- (IBAction)doneButtonAction:(id)sender;


@end
