//
//  FluxLeftDrawerViewController.h
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "FluxDataManager.h"
#import "MMDrawerController.h"

@interface FluxLeftDrawerViewController : UITableViewController<MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *profileUsernameLbl;
@property (weak, nonatomic) IBOutlet UILabel *profileNumberOfPostLbl;
@property (weak, nonatomic) IBOutlet UILabel *profileJoinedDateLbl;

@property (weak, nonatomic) IBOutlet UIView *copyrightView;
@property (weak, nonatomic) IBOutlet UILabel *versionLbl;

@property (nonatomic, strong) FluxDataManager *fluxDataManager;
@property (nonatomic, strong) MMDrawerController *drawerController;

- (IBAction)onSendFeedBackBtn:(id)sender;


@end
