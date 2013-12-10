//
//  FluxRegisterViewController.m
//  Flux
//
//  Created by Kei Turner on 11/4/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxRegisterViewController.h"
#import "ProgressHUD.h"
#import "FluxUserObject.h"
#import "FluxCameraObject.h"
#import "FluxTextFieldCell.h"
#import "UICKeyChainStore.h"


#import <FacebookSDK/FacebookSDK.h>
#import <sys/utsname.h>


#define ERROR_TITLE_MSG @"Uh oh..."
#define ERROR_NO_ACCOUNTS @"You must add a Twitter account in the Settings app to sign in with Twitter"
#define ERROR_PERM_ACCESS @"We weren't granted access your twitter accounts"
#define ERROR_OK @"OK"

@interface FluxRegisterViewController ()

@end

@implementation FluxRegisterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    if (!firstCheck) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Welcome"
                                                          message:@"Login / Signup is now partially implemented, please try it out. To save time in future launches, tap the flux logo to skip."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        
        
        [self checkCurrentLoginState];
        firstCheck = YES;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isInSignUp = YES;
    
    [loginTogglePromptLabel setFont:[UIFont fontWithName:@"Akkurat" size:loginTogglePromptLabel.font.pointSize]];
    [loginToggleButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:loginToggleButton.titleLabel.font.pointSize]];
    [twitterButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:twitterButton.titleLabel.font.pointSize]];
    [facebookButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:facebookButton.titleLabel.font.pointSize]];
    [createLoginButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:createLoginButton.titleLabel.font.pointSize]];
    [signInOptionsLabel setFont:[UIFont fontWithName:@"Akkurat" size:signInOptionsLabel.font.pointSize]];
    
    self.fluxDataManager = [[FluxDataManager alloc]init];
    
    textInputElements = [[NSMutableArray alloc]initWithObjects:@"Username", @"Password", @"Email", nil];
    
    //[logoImageView setFrame:CGRectMake(logoImageView.frame.origin.x, logoImageView.frame.origin.y+60, logoImageView.frame.size.width, logoImageView.frame.size.height)];
    [logoImageView setCenter:CGPointMake(logoImageView.center.x, logoImageView.center.y+100)];

    self.screenName = @"Registation View";
    
    self.accountStore = [[ACAccountStore alloc] init];
    self.apiManager = [[TWAPIManager alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterChanged) name:ACAccountStoreDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Text Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString * text;
    //hit backspace
    if (range.length>0) {
        text = [textField.text substringToIndex:textField.text.length-1];
    }
    //typed a character
    else{
        text = [textField.text stringByAppendingString:string];
    }
    [self checkTextCompletionForTextField:textField andString:text];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    if ([textField.placeholder isEqualToString:[textInputElements objectAtIndex:textInputElements.count-1]]) {
        [self createAccountButtonAction:nil];
        return YES;
    }
    for (int i = 0; i<textInputElements.count-1; i++) {
        if ([textField.placeholder isEqualToString:[textInputElements objectAtIndex:i]]) {
            FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i+1 inSection:0]];
            [cell.textField becomeFirstResponder];
        }
    }
    return YES;
}

#pragma mark - TableView Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return textInputElements.count;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"textFieldCell";
    FluxTextFieldCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxTextFieldCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    if (isInSignUp) {
        switch (indexPath.row)
        {
            case 0:
            {
                [cell setupForPosition:FluxTextFieldPositionTop andPlaceholder:[textInputElements objectAtIndex:indexPath.row]];
                [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.textField setReturnKeyType:UIReturnKeyNext];
            }
                break;
            case 1:
            {
                [cell setupForPosition:FluxTextFieldPositionMiddle andPlaceholder:[textInputElements objectAtIndex:indexPath.row]];
                [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.textField setSecureTextEntry:YES];
                [cell.textField setReturnKeyType:UIReturnKeyNext];
            }
                break;
            case 2:
            {
                [cell setupForPosition:FluxTextFieldPositionBottom andPlaceholder:[textInputElements objectAtIndex:indexPath.row]];
                [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
                [cell.textField setReturnKeyType:UIReturnKeyJoin];
            }
                break;
        }
    }
    else{
        switch (indexPath.row)
        {
            case 0:
                {
                    [cell setupForPosition:FluxTextFieldPositionTop andPlaceholder:[textInputElements objectAtIndex:indexPath.row]];
                    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [cell.textField setReturnKeyType:UIReturnKeyNext];
                }
                break;
            case 1:
                {
                    [cell setupForPosition:FluxTextFieldPositionBottom andPlaceholder:[textInputElements objectAtIndex:indexPath.row]];
                    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [cell.textField setSecureTextEntry:YES];
                    [cell.textField setReturnKeyType:UIReturnKeyGo];
                }
                break;
            }
    }

    [cell.textField setDelegate:self];
    cell.textField.textAlignment = NSTextAlignmentCenter;
    [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.textLabel.font.pointSize]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    if (shouldErase) {
        [cell.textField setText:@""];
    }
    return cell;
}

#pragma mark - Login/Signup

- (void)checkCurrentLoginState{
    NSString *username = [UICKeyChainStore stringForKey:@"username" service:@"com.flux"];
    NSString *userID = [UICKeyChainStore stringForKey:@"userID" service:@"com.flux"];
    NSString *token = [UICKeyChainStore stringForKey:@"token" service:@"com.flux"];
    
    [self checkFBLoginStatus];
    [self checkTWloginStatus];
    
    if (username && token && userID) {
        [self didLoginSuccessfullyWithUserID:userID.intValue];
    }
    else{
        [self showContainerViewAnimated:YES];
    }
}

- (void)fadeOutLogin
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self performSegueWithIdentifier:@"pushScanView" sender:self];
}

- (IBAction)createAccountButtonAction:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Welcome!" message:@"Thanks for taking the time to look into Flux. At the moment, Flux is still in beta, and requires a pin to continue. If you're one of the lucky ones, please enter your pin below." delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"Activate Pin", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert becomeFirstResponder];
    [alert show];
}

- (void)didLoginSuccessfullyWithUserID:(int)userID{
    FluxCameraObject*camObj = [[FluxCameraObject alloc]initWithdeviceID:[[[UIDevice currentDevice]identifierForVendor]UUIDString] model:[self deviceName] forUserID:userID];
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setPostCameraComplete:^(FluxDataRequest*completedRequest){
        [self fadeOutLogin];
    }];
    [dataRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
        [self showContainerViewAnimated:YES];
        NSString*str = [NSString stringWithFormat:@"Registration failed with error %d", (int)[e code]];
        [ProgressHUD showError:str];
    }];
    [self.fluxDataManager postCamera:camObj withDataRequest:dataRequest];
}

#pragma mark - 3rd Party Social

- (void)socialPartner:(NSString*)partner didAuthenticateWithToken:(NSString*)token andUserInfo:(NSDictionary*)userInfo{
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Welcome Friend" message:[NSString stringWithFormat:@"You (%@) successfully logged in with %@.",[userInfo objectForKey:@"username"],partner]  delegate:nil cancelButtonTitle:@"Coool" otherButtonTitles: nil];
    [alert becomeFirstResponder];
    [alert show];
    
    [UICKeyChainStore setString:token forKey:@"token" service:[NSString stringWithFormat:@"com.%@",partner]];
    
    //perform flux login, then post camera to the db to move forward.
    //for now just post the cam with default userID
    [self didLoginSuccessfullyWithUserID:1];
}

#pragma mark Twitter

-(void)twitterChanged{
#warning check if user is logged in and if they are, confirm the registered account still exists.
//    if (isLoggedIn) {
//        if (![TWAPIManager isLocalTwitterAccountAvailable]) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_TITLE_MSG message:ERROR_NO_ACCOUNTS delegate:nil cancelButtonTitle:ERROR_OK otherButtonTitles:nil];
//            [alert show];
//        }
//        else {
//            [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (granted) {
//                        //still cool.
//                    }
//                    else {
//                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_TITLE_MSG message:ERROR_PERM_ACCESS delegate:nil cancelButtonTitle:ERROR_OK otherButtonTitles:nil];
//                        [alert show];
//                        NSLog(@"You were not granted access to the Twitter accounts.");
//                    }
//                });
//            }];
//        }
//    }

}

- (IBAction)twitterSignInAction:(id)sender {
    
    
    if (![TWAPIManager isLocalTwitterAccountAvailable]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_TITLE_MSG message:ERROR_NO_ACCOUNTS delegate:nil cancelButtonTitle:ERROR_OK otherButtonTitles:nil];
        [alert show];
        return;
    }
    [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (granted) {
                if (_accounts.count > 1) {
                    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                    for (ACAccount *acct in _accounts) {
                        [sheet addButtonWithTitle:acct.username];
                    }
                    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
                    [sheet showInView:self.view];
                }
                else{
                    [self loginWithTwitterForAccountIndex:0];
                }
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_TITLE_MSG message:ERROR_PERM_ACCESS delegate:nil cancelButtonTitle:ERROR_OK otherButtonTitles:nil];
                [alert show];
                NSLog(@"You were not granted access to the Twitter accounts.");
                [self showContainerViewAnimated:YES];
            }
        });
    }];
    [self hideContainerViewAnimated:YES];
}

- (void)loginWithTwitterForAccountIndex:(int)index{
    [_apiManager performReverseAuthForAccount:_accounts[index] withHandler:^(NSData *responseData, NSError *error) {
        if (responseData) {
            NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            
            NSLog(@"Reverse Auth process returned: %@", responseStr);
            
            NSArray *parts = [responseStr componentsSeparatedByString:@"&"];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil];
            FluxRegisterEmailViewController*emailVC = [storyboard instantiateViewControllerWithIdentifier:@"registerEmailView"];

            NSDictionary*userInfo = [[NSDictionary alloc]initWithObjectsAndKeys:[parts objectAtIndex:3], @"username",[parts objectAtIndex:0], @"token", nil];
            emailVC.userInfo = [userInfo mutableCopy];
            [emailVC setDelegate:self];
            [self.navigationController pushViewController:emailVC animated:YES];
        }
        else {
            NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
        }
    }];
}

- (void)checkTWloginStatus
{
    NSLog(@"Refreshing Twitter Accounts \n");
}

- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block
{
    ACAccountType *twitterType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    ACAccountStoreRequestAccessCompletionHandler handler = ^(BOOL granted, NSError *error) {
        if (granted) {
            self.accounts = [_accountStore accountsWithAccountType:twitterType];
        }
        
        block(granted);
    };
    
    //  This method changed in iOS6. If the new version isn't available, fall back to the original (which means that we're running on iOS5+).
    [_accountStore requestAccessToAccountsWithType:twitterType options:nil completion:handler];
}

- (void)RegisterEmailView:(FluxRegisterEmailViewController *)emailView didAcceptAddEmailToUserInfo:(NSMutableDictionary *)userInfo{
    if (userInfo) {
        if ([userInfo objectForKey:@"token"]) {
            [self socialPartner:@"Twitter" didAuthenticateWithToken:[userInfo objectForKey:@"token"] andUserInfo:userInfo];
        }
        // **should** never occur
        else{
            [ProgressHUD showError:@"Unknown error occurred"];
        }
    }
    else{
        [ProgressHUD showError:@"Email is required for signup"];
        [self showContainerViewAnimated:YES];
    }
}

#pragma mark Facebook

- (IBAction)facebookSignInAction:(id)sender {
    if (!FBSession.activeSession.isOpen) {
        [self hideContainerViewAnimated:YES];
        if (FBSession.activeSession.state != FBSessionStateCreated) {
            // Create a new, logged out session.
            FBSession.activeSession = [[FBSession alloc] init];
        }
        
        // if the session isn't open, let's open it now and present the login UX to the user
        NSArray *permissions = [NSArray arrayWithObjects:@"email", nil];
        [FBSession openActiveSessionWithReadPermissions:permissions
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session,
           FBSessionState state, NSError *error) {
             if (!error) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     NSLog(@"Token: %@",FBSession.activeSession.accessTokenData.accessToken);
                     
                     if (FBSession.activeSession.isOpen) {
                         [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                         if (!error) {
                             
                             NSDictionary*userInfo = [[NSDictionary alloc]initWithObjectsAndKeys:user.username, @"username", nil];
                             [self socialPartner:@"Facebook" didAuthenticateWithToken:FBSession.activeSession.accessTokenData.accessToken andUserInfo:userInfo];
                         }

                         else{
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 NSString * errorstring = [NSString stringWithFormat:@"Error: %@",error.localizedDescription];
                                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:errorstring delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                 [alert show];
                                 [self showContainerViewAnimated:YES];
                                 });
                             }
                         }];
                     }
                 });
             }
             else{
                 dispatch_async(dispatch_get_main_queue(), ^{
                     NSString * errorstring = [NSString stringWithFormat:@"Error: %@",error.localizedDescription];
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:errorstring delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [alert show];
                 });
                 [self showContainerViewAnimated:YES];
             }
         }];
    }
}

- (void)checkFBLoginStatus{
    if (!FBSession.activeSession) {
        // create a fresh session object
        FBSession.activeSession = [[FBSession alloc] init];
        [FBSession setActiveSession: FBSession.activeSession];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            NSArray *permissions = [NSArray arrayWithObjects:@"email", nil];
            [FBSession openActiveSessionWithReadPermissions:permissions
                                               allowLoginUI:YES
                                          completionHandler:
             ^(FBSession *session,
               FBSessionState state, NSError *error) {
                 if (!error) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         NSString * string = [NSString stringWithFormat:@"Token: %@",FBSession.activeSession.accessTokenData.accessToken];
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:string delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     });
                 }
                 else{
                     dispatch_async(dispatch_get_main_queue(), ^{
                         NSString * errorstring = [NSString stringWithFormat:@"Error: %@",error.localizedDescription];
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:errorstring delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     });
                 }
             }];
        }
    }
}

#pragma mark Pin


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
        NSLog(@"Entered: %@",[[alertView textFieldAtIndex:0] text]);
    if (buttonIndex > 0 && [[alertView textFieldAtIndex:0] text].length > 0) {
        [self hideContainerViewAnimated:YES];
        [self loginSignupWithPin:[[alertView textFieldAtIndex:0] text]];
    }
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}

-(void)loginSignupWithPin:(NSString*)pin{
    if (isInSignUp) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL isremote = [[defaults objectForKey:@"Server Location"]intValue];
        if (!isremote) {
            [self fadeOutLogin];
            return;
        }
        
        FluxUserObject *newUser = [[FluxUserObject alloc]init];
        
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSString*username = cell.textField.text;
        
        cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        NSString*password = cell.textField.text;
        
        cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
        NSString*email = cell.textField.text;
        
        [newUser setUsername:username];
        [newUser setPassword:password];
        [newUser setEmail:email];
        
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setUploadUserComplete:^(FluxUserObject*createdUserObject, FluxDataRequest *completedDataRequest){
            [UICKeyChainStore setString:createdUserObject.username forKey:@"username" service:@"com.flux"];
            [UICKeyChainStore setString:[NSString stringWithFormat:@"%i",createdUserObject.userID] forKey:@"userID" service:@"com.flux"];
            [UICKeyChainStore setString:createdUserObject.auth_token forKey:@"token" service:@"com.flux"];
            
            [ProgressHUD showSuccess:@"Account Created!"];
            [self didLoginSuccessfullyWithUserID:createdUserObject.userID];

        }];
        [dataRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            [self showContainerViewAnimated:YES];
            NSString*str = [NSString stringWithFormat:@"Registration failed with error %d", (int)[e code]];
            [ProgressHUD showError:str];
        }];
        [self hideKeyboard];
        [self.fluxDataManager uploadNewUser:newUser withImage:nil withDataRequest:dataRequest];
    }
    else{
        FluxUserObject *newUser = [[FluxUserObject alloc]init];
        
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSString*username = cell.textField.text;
        
        cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        NSString*password = cell.textField.text;
        
        [newUser setUsername:username];
        [newUser setPassword:password];
        
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setLoginUserComplete:^(FluxUserObject*userObject, FluxDataRequest * completedDataRequest){
            [UICKeyChainStore setString:userObject.username forKey:@"username" service:@"com.flux"];
            [UICKeyChainStore setString:[NSString stringWithFormat:@"%i",userObject.userID] forKey:@"userID" service:@"com.flux"];
            [UICKeyChainStore setString:userObject.auth_token forKey:@"token" service:@"com.flux"];
            
            [ProgressHUD showSuccess:@"Login Successful"];
            [self didLoginSuccessfullyWithUserID:userObject.userID];
        }];
        [dataRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
            [self showContainerViewAnimated:YES];
            if ([e.userInfo objectForKey:@"NSLocalizedRecoverySuggestion"]) {
                if ([(NSString*)[e.userInfo objectForKey:@"NSLocalizedRecoverySuggestion"]length] < 30) {
                    [ProgressHUD showError:(NSString*)[e.userInfo objectForKey:@"NSLocalizedRecoverySuggestion"]];
                }
                else{
                    NSString*str = [NSString stringWithFormat:@"Login failed with error %d", (int)[e code]];
                    [ProgressHUD showError:str];
                }
                
            }
            else{
                NSString*str = [NSString stringWithFormat:@"Login failed with error %d", (int)[e code]];
                [ProgressHUD showError:str];
            }
        }];
        [self hideKeyboard];
        [self.fluxDataManager loginUser:newUser withDataRequest:dataRequest];
    }
}

- (IBAction)loginSignupToggleAction:(id)sender {
    
    if (![createLoginButton translatesAutoresizingMaskIntoConstraints]) {
        [createLoginButton removeFromSuperview];
        [createLoginButton setTranslatesAutoresizingMaskIntoConstraints:YES];
        [loginElementsContainerView addSubview:createLoginButton];
    }
    if (isInSignUp) {
        isInSignUp = NO;
        [textInputElements removeObjectAtIndex:2];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self performSelector:@selector(reloadTheRow) withObject:nil afterDelay:0.0];
        [loginTogglePromptLabel setText:@"Don't have an acount yet?"];
        [loginToggleButton setTitle:@"Sign up!" forState:UIControlStateNormal];
        [loginToggleButton setEnabled:NO];
        
        [UIView setAnimationsEnabled:NO];
        [createLoginButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [UIView setAnimationsEnabled:YES];
        
        
        
        [UIView animateWithDuration:0.3 animations:^{
            [twitterButton setAlpha:0.0];
            [facebookButton setAlpha:0.0];
            [topSeparator setAlpha:0.0];
            [signInOptionsLabel setAlpha:0.0];
        } completion:^(BOOL finished){
            [loginToggleButton setEnabled:YES];
        }];
    }
    else{
        isInSignUp = YES;
        [textInputElements insertObject:@"email" atIndex:2];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [self performSelector:@selector(reloadTheRow) withObject:nil afterDelay:0.0];
        [loginTogglePromptLabel setText:@"Already have an Account?"];
        [loginToggleButton setTitle:@"Sign in!" forState:UIControlStateNormal];
        [loginToggleButton setEnabled:NO];
        
        [UIView setAnimationsEnabled:NO];
        [createLoginButton setTitle:@"Create Account" forState:UIControlStateNormal];
        [UIView setAnimationsEnabled:YES];

        
        [UIView animateWithDuration:0.3 animations:^{
            [twitterButton setAlpha:1.0];
            [facebookButton setAlpha:1.0];
            [topSeparator setAlpha:1.0];
            [signInOptionsLabel setAlpha:1.0];
        } completion:^(BOOL finished){
            [loginToggleButton setEnabled:YES];
        }];
    }
}

- (IBAction)backdoorButtonAction:(id)sender {
    [(UIButton*)sender setEnabled:NO];
    [self hideContainerViewAnimated:YES];
    [self performSelector:@selector(fadeOutLogin) withObject:Nil afterDelay:0.5];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [self loginWithTwitterForAccountIndex:buttonIndex];
    }
}

#pragma mark - View Helpers

- (void)hideContainerViewAnimated:(BOOL)animated{
    if (animated) {
        [UIView animateWithDuration:0.3  animations:^{
            [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
            if (self.view.bounds.size.height < 500) {
                [logoImageView setFrame:CGRectMake(self.view.center.x-logoImageView.frame.size.width, self.view.center.y-logoImageView.frame.size.height, logoImageView.frame.size.width*2, logoImageView.frame.size.height*2)];
            }
            else{
                [logoImageView setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
            }
        }];
    }
    else{
        [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
        if (self.view.bounds.size.height < 500) {
            [logoImageView setFrame:CGRectMake(self.view.center.x-logoImageView.frame.size.width, self.view.center.y-logoImageView.frame.size.height, logoImageView.frame.size.width*2, logoImageView.frame.size.height*2)];
        }
        else{
            [logoImageView setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
        }
    }
}

- (void)showContainerViewAnimated:(BOOL)animated{
    if (![loginElementsContainerView translatesAutoresizingMaskIntoConstraints]) {
        [loginElementsContainerView removeFromSuperview];
        [loginElementsContainerView setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self.view addSubview:loginElementsContainerView];
        
        [logoImageView removeFromSuperview];
        [logoImageView setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self.view addSubview:logoImageView];
    }

    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height-loginElementsContainerView.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
            if (self.view.bounds.size.height < 500) {
                [logoImageView setFrame:CGRectMake(self.view.center.x-(logoImageView.frame.size.width/2/2), 25, logoImageView.frame.size.width/2, logoImageView.frame.size.height/2)];
            }
            else{
                [logoImageView setCenter:CGPointMake(self.view.center.x, 94)];
            }
        }];
    }
    else{
        [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height-loginElementsContainerView.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
        if (self.view.bounds.size.height < 500) {
            [logoImageView setFrame:CGRectMake(self.view.center.x-(logoImageView.frame.size.width/2/2), 25, logoImageView.frame.size.width/2, logoImageView.frame.size.height/2)];
        }
        else{
            [logoImageView setCenter:CGPointMake(self.view.center.x, 94)];
        }
    }
}

-(void)checkTextCompletionForTextField:(UITextField*)textField andString:(NSString*)string{
    if (isInSignUp) {
        for (int i = 0; i<textInputElements.count; i++) {
            if ([textField.placeholder isEqualToString:[textInputElements objectAtIndex:i]]) {
                FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                switch (i) {
                    case 0:
                        //
                        break;
                    case 1:
                    {
                        if (string.length > 5) {
                            [cell setChecked:YES];
                        }
                        else{
                            [cell setChecked:NO];
                        }
                    }
                        break;
                    case 2:
                    {
                        if ([self NSStringIsValidEmail:string]) {
                            [cell setChecked:YES];
                        }
                        else{
                            [cell setChecked:NO];
                        }
                    }
                        break;
                        
                    default:
                        break;
                }
                [cell.textField becomeFirstResponder];
            }
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self hideKeyboard];
}

- (void)hideKeyboard{
    for (int i = 0; i<textInputElements.count; i++) {
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [cell.textField resignFirstResponder];
    }
}

- (BOOL)keyboardIsVisible{
    for (int i = 0; i<textInputElements.count; i++) {
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([cell.textField isFirstResponder]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (NSString*)deviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

- (void)reloadTheRow{
    shouldErase = YES;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    shouldErase = NO;
}

@end
