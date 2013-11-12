//
//  FluxRegisterViewController.h
//  Flux
//
//  Created by Kei Turner on 11/4/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMDrawerController.h"
#import "FluxLeftDrawerViewController.h"
#import "FluxScanViewController.h"

#import "FluxDataManager.h"


@interface FluxRegisterViewController : UIViewController <UITextFieldDelegate ,UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>{
    __strong FluxLeftDrawerViewController * leftSideDrawerViewController;
    __strong FluxScanViewController * scanViewController;
    __strong MMDrawerController * drawerController;
    
    NSMutableArray*textInputElements;
    BOOL isInSignUp;
    
    IBOutlet UITextField *usernameField;
    IBOutlet UITextField *passwordField;
    IBOutlet UITextField *emailField;
    IBOutlet UIView *loginElementsContainerView;
    IBOutlet UILabel *loginTogglePromptLabel;
    IBOutlet UIButton *loginToggleButton;
    IBOutlet UIButton *twitterButton;
    IBOutlet UIButton *facebookButton;
    IBOutlet UIButton *createLoginButton;
    IBOutlet UIView *topSeparator;
    IBOutlet UIImageView *logoImageView;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
- (void)hideKeyboard;
- (IBAction)createAccountButtonAction:(id)sender;
- (IBAction)loginSignupToggleAction:(id)sender;


@end
