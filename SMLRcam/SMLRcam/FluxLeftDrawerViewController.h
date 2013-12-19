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

@interface FluxLeftDrawerViewController : UITableViewController<MFMailComposeViewControllerDelegate,UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    NSMutableArray*tableViewArray;
    FluxUserObject*userObj;
    
    BOOL isEditing;
}

@property (weak, nonatomic) IBOutlet UIView *copyrightView;
@property (strong, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLbl;

@property (nonatomic, strong) FluxDataManager *fluxDataManager;

- (IBAction)onSendFeedBackBtn:(id)sender;
- (IBAction)editProfileAction:(id)sender;
- (IBAction)editProfleImageAction:(id)sender;


@end
