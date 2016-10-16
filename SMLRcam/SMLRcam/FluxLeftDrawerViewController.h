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
#import "FluxPhotosViewController.h"

#import "FluxDataManager.h"

@interface FluxLeftDrawerViewController : UITableViewController<MFMailComposeViewControllerDelegate,UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PhotosViewDelegate>{
    NSMutableArray*tableViewArray;
    FluxUserObject*userObj;
    int newImageCount;
    
    
    IBOutlet UIView *fakeSeparator;
    BOOL isEditing;
}

@property (weak, nonatomic) IBOutlet UIView *copyrightView;
@property (strong, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLbl;
@property (nonatomic)int badgeCount;

@property (nonatomic, strong) FluxDataManager *fluxDataManager;

- (IBAction)onSendFeedBackBtn:(id)sender;
- (IBAction)editProfileAction:(id)sender;
- (IBAction)editProfleImageAction:(id)sender;

- (void)didUpdateProfileWithChanges:(NSDictionary*)changesDict;


@end
