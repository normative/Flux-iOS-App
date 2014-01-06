//
//  FluxRegisterViewController.h
//  Flux
//
//  Created by Kei Turner on 11/4/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxLeftDrawerViewController.h"
#import "FluxScanViewController.h"
#import "FluxRegisterEmailViewController.h"
#import "FluxRegisterUsernameViewController.h"

#import "FluxDataManager.h"

#import "GAITrackedViewController.h"

#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "OAuth+Additions.h"
#import "TWAPIManager.h"
#import "TWSignedRequest.h"



@interface FluxRegisterViewController : GAITrackedViewController <UITextFieldDelegate ,UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate, FluxRegisterEmailViewDelegate, FluxRegisterUsernameViewDelegate>{
    __strong FluxLeftDrawerViewController * leftSideDrawerViewController;
    __strong FluxScanViewController * scanViewController;
    
    NSString*socialOauthPin;
    NSDictionary*thirdPartyUserInfo;
    
    NSMutableArray*textInputElements;
    NSMutableArray*registrationOKArray;
    
    BOOL isInSignUp;
    BOOL shouldErase;
    BOOL firstCheck;
    BOOL showUernamePrompt;
    NSString*tempUsername;
    
    
    IBOutlet UITextField *usernameField;
    IBOutlet UITextField *passwordField;
    IBOutlet UITextField *emailField;
    IBOutlet UIView *loginElementsContainerView;
    IBOutlet UILabel *loginTogglePromptLabel;
    IBOutlet UILabel *signInOptionsLabel;
    IBOutlet UIButton *loginToggleButton;
    IBOutlet UIButton *twitterButton;
    IBOutlet UIButton *facebookButton;
    IBOutlet UIButton *createLoginButton;
    IBOutlet UIView *topSeparator;
    IBOutlet UIImageView *logoImageView;
    UIMenuController *menuController;
    
    UIActivityIndicatorView * loadingActivityIndicator;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;

- (void)hideKeyboard;
- (void)userDidLogOut;
- (IBAction)createAccountButtonAction:(id)sender;
- (IBAction)twitterSignInAction:(id)sender;
- (IBAction)facebookSignInAction:(id)sender;
- (IBAction)loginSignupToggleAction:(id)sender;
- (IBAction)backdoorButtonAction:(id)sender;


@end
