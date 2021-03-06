//
//  FluxRegisterViewController.m
//  Flux
//
//  Created by Kei Turner on 11/4/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxRegisterViewController.h"
#import "ProgressHUD.h"
#import "FluxRegistrationUserObject.h"
#import "FluxCameraObject.h"
#import "FluxTextFieldCell.h"
#import "UICKeyChainStore.h"
#import "UIAlertView+Blocks.h"
//#import "DTAlertView.h"


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
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (!firstCheck) {
        [self checkCurrentLoginState];
        firstCheck = YES;
    }
    self.screenName = @"Registation View";
    
    //coming back from a logout
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isInSignUp = YES;
    
    NSMutableArray*animationImages1 = [[NSMutableArray alloc]init];
    for (int i = 1; i<33; i++) {
        UIImage*img = [UIImage imageNamed:[NSString stringWithFormat:@"%i", i]];
        [animationImages1 addObject:img];
    }
    
    NSMutableArray*animationImages2 = [[NSMutableArray alloc]init];
    for (int i = 33; i<62; i++) {
        UIImage*img = [UIImage imageNamed:[NSString stringWithFormat:@"%i", i]];
        [animationImages2 addObject:img];
    }
    
    [forgotPasswordButton setHidden:YES];
    [forgotPasswordButton setAlpha:0.0];
//    [forgotPasswordButton removeFromSuperview];
    
    [logoImageView setFirstAnimationSet:animationImages1 andSecondAnimationSet:animationImages2];
    
    [loginTogglePromptLabel setFont:[UIFont fontWithName:@"Akkurat" size:loginTogglePromptLabel.font.pointSize]];
    [loginToggleButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:loginToggleButton.titleLabel.font.pointSize]];
    [twitterButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:twitterButton.titleLabel.font.pointSize]];
    [facebookButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:facebookButton.titleLabel.font.pointSize]];
    [createLoginButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:createLoginButton.titleLabel.font.pointSize]];
    [signInOptionsLabel setFont:[UIFont fontWithName:@"Akkurat" size:signInOptionsLabel.font.pointSize]];
    [forgotPasswordButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:forgotPasswordButton.titleLabel.font.pointSize]];
    
    self.fluxDataManager = [[FluxDataManager alloc]init];
    registrationOKArray = [[NSMutableArray alloc]initWithObjects:[NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO], nil];
    
    
    textInputElements = [[NSMutableArray alloc]initWithObjects:@"Username", @"Password", @"Email", nil];
    
    [logoImageView removeFromSuperview];
    [logoImageView setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.view addSubview:logoImageView];

    [logoImageView setCenter:self.view.center];

    
    self.accountStore = [[ACAccountStore alloc] init];
    self.apiManager = [[TWAPIManager alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterChanged) name:ACAccountStoreDidChangeNotification object:nil];
    
//    [twitterButton setEnabled:NO];
//    [facebookButton setEnabled:NO];
//    [signInOptionsLabel setAlpha:0.3];    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"pushUsernameSegue"]) {
//        FluxRegisterUsernameViewController*usernameVC = (FluxRegisterUsernameViewController*)segue.destinationViewController;
//        [usernameVC setFluxDataManager:self.fluxDataManager];
//        [usernameVC setUserInfo:[thirdPartyUserInfo mutableCopy]];
//        [usernameVC setSuggestedUsername:tempUsername];
//        [usernameVC setDelegate:self];
    }
    else if ([[segue identifier] isEqualToString:@"pushEmailSegue"]){
        FluxRegisterEmailViewController*emailVC = (FluxRegisterEmailViewController*)segue.destinationViewController;
        [emailVC setUserInfo:thirdPartyUserInfo];
        [emailVC setDelegate:self];
        [emailVC setFluxDataManager:self.fluxDataManager];
    }
    else{
        
    }
}

#pragma mark Text Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    //only letters and numbers
    NSCharacterSet *blockedCharacters = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    if (!([string rangeOfCharacterFromSet:blockedCharacters].location == NSNotFound) && (textField.tag == 10 || textField.tag == 88) && ![string isEqualToString:@"."]) {
        return NO;
    }
    
    NSString * text;
    //hit backspace
    if (range.length>0) {
        text = [textField.text substringToIndex:textField.text.length-1];
    }
    //typed a character
    else{
        text = [textField.text stringByAppendingString:string];
    }
    
    if ((textField.tag == 10 || textField.tag == 88) &&  text.length > 16) {
        return NO;
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

- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField.tag == 88 && textField.text.length > 3 && isInSignUp) {
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [cell setLoading:YES];
        
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setUsernameUniquenessComplete:^(BOOL unique, NSString*suggestion, FluxDataRequest*completedRequest){
            [cell setLoading:NO];
            if (unique) {
                if (showUernamePrompt) {
                    showUernamePrompt = NO;
                    
                    tempUsername = textField.text;
                    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    
                }
                [self performSelector:@selector(setUsernameCellChecked) withObject:nil afterDelay:0.0];
            }
            
            else{
//                if (suggestion.length > 0) {
//                    UIMenuItem*suggestionItem = [[UIMenuItem alloc]initWithTitle:suggestion action:@selector(setUsernameToSuggestion:)];
//                    UIMenuController *menu = [UIMenuController sharedMenuController];
//                    [menu setTargetRect:cell.frame inView:self.view];
//                    [menu setMenuItems:[NSArray arrayWithObject:suggestionItem]];
//                    [menu setMenuVisible:YES animated:YES];
//                }
                
                showUernamePrompt = YES;
                tempUsername = textField.text;
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }];
         [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
             [cell setLoading:NO];
             NSLog(@"Unique lookup failed with error %d", (int)[e code]);
        }];
        [self.fluxDataManager checkUsernameUniqueness:textField.text withDataRequest:dataRequest];
    }
}

- (void)setUsernameCellChecked{
    FluxTextFieldCell*cell1 = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [cell1 setChecked:YES];
    [self changeOKArrayIndex:0 andChecked:YES];
}

- (void)setUsernameToSuggestion:(id)sender{
    FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [cell.textField setText:[(UIButton*)sender titleLabel].text];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (showUernamePrompt) {
        if (indexPath.row == 0) {
            return 70;
        }
    }
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
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                [cell.textField setReturnKeyType:UIReturnKeyNext];
                [cell.textField setSecureTextEntry:NO];
                [cell.textField setTag:88];
                
                
                
                if (showUernamePrompt) {
                    if (!cell.warningLabel) {
                        cell.warningLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 40, cell.frame.size.width, 25)];
                        [cell.warningLabel setFont:loginTogglePromptLabel.font];
                        [cell.warningLabel setTextColor:loginTogglePromptLabel.textColor];
                        [cell.warningLabel setTextAlignment:NSTextAlignmentCenter];
                        [cell.warningLabel setText:@"this username has already been taken"];
                    }

                    [cell addSubview:cell.warningLabel];
                }
                else{
                    if (cell.warningLabel) {
                        [cell.warningLabel removeFromSuperview];
                    }
                }
                
                if (tempUsername) {
                    [cell.textField setText:tempUsername];
                }

                
                else{
                    if ([cell.warningLabel superview]) {
                        [cell.warningLabel removeFromSuperview];
                    }
                }
            }
                break;
            case 1:
            {
                [cell setupForPosition:FluxTextFieldPositionMiddle andPlaceholder:[textInputElements objectAtIndex:indexPath.row]];
                [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                [cell.textField setSecureTextEntry:YES];
                [cell.textField setReturnKeyType:UIReturnKeyNext];
                [cell.textField setTag:10];
                [cell.warningLabel removeFromSuperview];
            }
                break;
            case 2:
            {
                [cell setupForPosition:FluxTextFieldPositionBottom andPlaceholder:[textInputElements objectAtIndex:indexPath.row]];
                [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
                [cell.textField setSecureTextEntry:NO];
                [cell.textField setReturnKeyType:UIReturnKeyJoin];
                [cell.warningLabel removeFromSuperview];
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
                    [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                    [cell.textField setReturnKeyType:UIReturnKeyNext];
                    [cell.textField setSecureTextEntry:NO];
                    [cell.textField setTag:10];
                }
                break;
            case 1:
                {
                    [cell setupForPosition:FluxTextFieldPositionBottom andPlaceholder:[textInputElements objectAtIndex:indexPath.row]];
                    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                    [cell.textField setSecureTextEntry:YES];
                    [cell.textField setKeyboardType:UIKeyboardTypeDefault];
                    [cell.textField setReturnKeyType:UIReturnKeyGo];
                    [cell.textField setTag:10];
                }
                break;
            }
        if ([cell.warningLabel superview]) {
            [cell.warningLabel removeFromSuperview];
        }
    }

    [cell.textField setDelegate:self];
    cell.textField.textAlignment = NSTextAlignmentCenter;
    [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.textLabel.font.pointSize]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    if (shouldErase) {
        [cell setChecked:NO];
        [cell.textField setText:@""];
    }
    return cell;
}

#pragma mark - Login/Signup

- (void)checkCurrentLoginState{
    NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    NSString *username = [UICKeyChainStore stringForKey:FluxUsernameKey service:FluxService];

    
    if (token && userID && username) {
        [UIView animateWithDuration:0.2 animations:^{
                [logoImageView startAnimating];
            }];
        [self didLoginSuccessfullyWithUserID:[userID intValue]];
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

- (void)didLoginSuccessfullyWithUserID:(int)userID{
    FluxCameraObject*camObj = [[FluxCameraObject alloc]initWithdeviceID:[[[UIDevice currentDevice]identifierForVendor]UUIDString] model:[self deviceName] forUserID:userID];
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setPostCameraComplete:^(int cameraID,FluxDataRequest*completedRequest){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSString stringWithFormat:@"%i",cameraID] forKey:@"cameraID"];
        [defaults synchronize];
        [self fadeOutLogin];
    }];
    [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        NSString*str = [NSString stringWithFormat:@"Login failed, maybe give it another shot in a few minutes."];
        [self loginRegistrationFailedWithString:str];
    }];
    [self.fluxDataManager postCamera:camObj withDataRequest:dataRequest];
}

- (void)loginRegistrationFailedWithString:(NSString*)description{
    [self showContainerViewAnimated:YES];
    [self userDidLogOut];
    
    if ([description isKindOfClass:[NSString class]]) {
        [ProgressHUD showError:description];
    }
}

#pragma mark - 3rd Party Social

- (void)socialPartner:(NSString*)partner didAuthenticateWithUserInfo:(NSDictionary*)userInfo{
    
    if (partner) {
        thirdPartyUserInfo = [userInfo mutableCopy];
        [thirdPartyUserInfo setObject:partner forKey:@"partner"];
        
        [self performSegueWithIdentifier:@"pushEmailSegue" sender:self];
        
    }
}

- (void)RegisterEmailView:(FluxRegisterEmailViewController *)emailView didAddToUserInfo:(NSMutableDictionary *)userInfo{
    if (userInfo) {
        if ([userInfo objectForKey:@"token"]) {
            [self registerSocialPartnerWithUserInfo:userInfo];
        }
        // **should** never occur
        else{
            [self loginRegistrationFailedWithString:@"Unknown error occurred"];
        }
    }
    else{
        [self loginRegistrationFailedWithString:@"Registration cancelled"];
    }
}

- (void)registerSocialPartnerWithUserInfo:(NSDictionary*)userInfo{
    FluxRegistrationUserObject *newUser = [[FluxRegistrationUserObject alloc]init];
    
    NSString*username = (NSString*)[userInfo objectForKey:@"username"];
    NSString*email = (NSString*)[userInfo objectForKey:@"email"];
    NSString*socialName = (NSString*)[userInfo objectForKey:@"socialName"];
    if ([userInfo objectForKey:@"profilePic"]) {
        [newUser setProfilePic:(UIImage*)[userInfo objectForKey:@"profilePic"]];
    }
    
    [newUser setUsername:username];
    [newUser setEmail:email];
    [newUser setSocialName:socialName];
    
    if ([(NSString*)[userInfo objectForKey:@"partner"] isEqualToString:TwitterService]) {
        NSDictionary*twitter = [NSDictionary dictionaryWithObjectsAndKeys:(NSString*)[userInfo objectForKey:@"token"],@"access_token",(NSString*)[userInfo objectForKey:@"secret"],@"access_token_secret",  nil];
        [newUser setTwitter:twitter];
        [UICKeyChainStore setString:@"yep" forKey:FluxDidRegisterKey service:TwitterService];
    }
    else if ([(NSString*)[userInfo objectForKey:@"partner"] isEqualToString:FacebookService]){
        NSString*facebook = (NSString*)[userInfo objectForKey:@"token"];
        [newUser setFacebook:facebook];
        [UICKeyChainStore setString:@"yep" forKey:FluxDidRegisterKey service:FacebookService];
    }
    else{
        
    }
    
    [self createAccountForUser:newUser];
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
    FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
    [socialManager setDelegate:self];
    [self hideContainerViewAnimated:YES];
    [socialManager registerWithTwitter];

}

//this doesn't need to be implemented. If we've logged in previously, check the chainStore. If not, normal twiter login. We don't need to update keys for twitter because it's baked in the OS.
- (void)checkTWloginStatus
{
    
}



#pragma mark Facebook

- (IBAction)facebookSignInAction:(id)sender {
    FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
    [socialManager setDelegate:self];
    [self hideContainerViewAnimated:YES];
    [socialManager registerWithFacebook];
}

- (void)checkFBLoginStatus{
    if (FBSession.activeSession) {
//        // create a fresh session object
//        FBSession.activeSession = [[FBSession alloc] init];
//        [FBSession setActiveSession: FBSession.activeSession];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        NSLog(@"State Info: %i",FBSession.activeSession.state);
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            NSArray *permissions = [NSArray arrayWithObjects:@"email", nil];
            [FBSession openActiveSessionWithReadPermissions:permissions
                                               allowLoginUI:YES
                                          completionHandler:
             ^(FBSession *session,
               FBSessionState state, NSError *error) {
                 if (!error) {
//                     NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
                     [UICKeyChainStore setString:FBSession.activeSession.accessTokenData.accessToken forKey:@"token" service:[NSString stringWithFormat:@"com.%@",@"Facebook"]];
                     [self didLoginSuccessfullyWithUserID:1];
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

#pragma mark - Social Manager Delegate

- (void)SocialManager:(FluxSocialManager*)socialManager didRegisterFacebookAccountWithUserInfo: (NSDictionary*)userInfo{
    FluxRegistrationUserObject *newUser = [[FluxRegistrationUserObject alloc]init];
    NSString*facebook = (NSString*)[userInfo objectForKey:@"token"];
    [newUser setFacebook:facebook];
    
    //try to log in with facebook first, if no account exists then move to register
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setLoginUserComplete:^(FluxRegistrationUserObject*userObject, FluxDataRequest * completedDataRequest){
        UICKeyChainStore *store = [UICKeyChainStore keyChainStoreWithService:FluxService];
        
        [store setString:userObject.username forKey:FluxUsernameKey];
        [store setString:[NSString stringWithFormat:@"%i",userObject.userID] forKey:FluxUserIDKey];
        [store setString:userObject.auth_token forKey:FluxTokenKey];
        [store setString:userObject.email forKey:FluxEmailKey];
        [store synchronize];
        
        [UICKeyChainStore setString:[userInfo objectForKey:@"name"]forKey:FluxNameKey service:FacebookService];
        [UICKeyChainStore setString:[userInfo objectForKey:@"username"] forKey:FluxUsernameKey service:FacebookService];

//        [ProgressHUD showSuccess:[NSString stringWithFormat: @"Welcome back @%@", userObject.username]];
        [self didLoginSuccessfullyWithUserID:userObject.userID];
    }];
    [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        //if login failed, move ahead with registration
        [self socialPartner:FacebookService didAuthenticateWithUserInfo:userInfo];
    }];
    [self.fluxDataManager loginUser:newUser withDataRequest:dataRequest];
}
- (void)SocialManager:(FluxSocialManager*)socialManager didRegisterTwitterAccountWithUserInfo: (NSDictionary*)userInfo{
    FluxRegistrationUserObject *newUser = [[FluxRegistrationUserObject alloc]init];
    NSString *access_token = (NSString*)[userInfo objectForKey:@"token"];
    NSString *access_token_secret = (NSString*)[userInfo objectForKey:@"secret"];
    
    NSDictionary*twitter = [NSDictionary dictionaryWithObjectsAndKeys:access_token, @"access_token",access_token_secret, @"access_token_secret",  nil];
    [newUser setTwitter:twitter];
    
    //try to log in with Twitter first, if no account exists then move to register
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setLoginUserComplete:^(FluxRegistrationUserObject*userObject, FluxDataRequest * completedDataRequest){
        UICKeyChainStore *store = [UICKeyChainStore keyChainStoreWithService:FluxService];
        
        [store setString:userObject.username forKey:FluxUsernameKey];
        [store setString:userObject.password forKey:FluxPasswordKey];
        [store setString:[NSString stringWithFormat:@"%i",userObject.userID] forKey:FluxUserIDKey];
        [store setString:userObject.auth_token forKey:FluxTokenKey];
        [store setString:userObject.email forKey:FluxEmailKey];
        [store synchronize];

        
//        // [UICKeyChainStore setString:[userInfo objectForKey:@"username"] forKey:FluxUsernameKey service:TwitterService];
//        store = [UICKeyChainStore keyChainStoreWithService:TwitterService];
//        [store setString:[userInfo objectForKey:@"username"] forKey:FluxUsernameKey];
//        [store setString:access_token forKey:FluxAccessTokenKey];
//        [store setString:access_token_secret forKey:FluxAccessTokenSecretKey];

//        [ProgressHUD showSuccess:[NSString stringWithFormat: @"Welcome back @%@", userObject.username]];
        [self didLoginSuccessfullyWithUserID:userObject.userID];
    }];
    [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        //if login failed, move ahead with registration
        [self socialPartner:TwitterService didAuthenticateWithUserInfo:userInfo];
    }];
    [self.fluxDataManager loginUser:newUser withDataRequest:dataRequest];
}
- (void)SocialManager:(FluxSocialManager*)socialManager didFailToRegisterSocialAccount:(NSString*)accountType andMessage:(NSString *)message{
    NSString*str;
    if (message) {
        str = message;
    }
    else{
        str = [NSString stringWithFormat:@"Registration with %@ failed",accountType];
    }
    [self loginRegistrationFailedWithString:str];
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

#pragma mark local register/ signup (not 3rd party)

-(void)loginSignupWithPin:(NSString*)pin{
    if (isInSignUp) {
        
        FluxRegistrationUserObject *newUser = [[FluxRegistrationUserObject alloc]init];
        
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSString*username = cell.textField.text;
        
        cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        NSString*password = cell.textField.text;
        
        cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
        NSString*email = cell.textField.text;
        
        [newUser setUsername:username];
        [newUser setPassword:password];
        [newUser setEmail:email];
        
        [self createAccountForUser:newUser];
    }
    else{
        FluxRegistrationUserObject *signingInUser = [[FluxRegistrationUserObject alloc]init];
        
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSString*username = cell.textField.text;
        
        cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        NSString*password = cell.textField.text;
        
        [signingInUser setUsername:username];
        [signingInUser setPassword:password];
        
        [self loginWithUserObject:signingInUser andDidJustRegister:NO];
    }
}

- (void)createAccountForUser:(FluxRegistrationUserObject*)user{
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setUploadUserComplete:^(FluxRegistrationUserObject*createdUserObject, FluxDataRequest *completedDataRequest){
        [createdUserObject setPassword:user.password];
            [self loginWithUserObject:createdUserObject andDidJustRegister:YES];

        }];
        [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            NSString*str = [NSString stringWithFormat:@"Registration failed"];
        [self loginRegistrationFailedWithString:str];
        }];
        [self hideKeyboard];
    if (user.profilePic) {
        [self.fluxDataManager uploadNewUser:user withImage:user.profilePic withDataRequest:dataRequest];
    }
    else{
        [self.fluxDataManager uploadNewUser:user withImage:nil withDataRequest:dataRequest];
    }
}

- (void)loginWithUserObject:(FluxRegistrationUserObject*)user andDidJustRegister:(BOOL)new{
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setLoginUserComplete:^(FluxRegistrationUserObject*userObject, FluxDataRequest * completedDataRequest){
        
        [UICKeyChainStore setString:userObject.auth_token forKey:FluxTokenKey service:FluxService];
        
        UICKeyChainStore *store = [UICKeyChainStore keyChainStoreWithService:FluxService];
        
        [store setString:userObject.username forKey:FluxUsernameKey];
        [store setString:userObject.password forKey:FluxPasswordKey];
        [store setString:[NSString stringWithFormat:@"%i",userObject.userID] forKey:FluxUserIDKey];
//        [store setString:[NSString stringWithString:userObject.auth_token] forKey:FluxTokenKey];
        [store setString:userObject.email forKey:FluxEmailKey];
        [store synchronize];

        if (![NSString stringWithFormat:@"%i",userObject.userID]) {
            NSLog(@"Login didn't return a valid userID");
        }
        
        if (![NSString stringWithFormat:@"%@",userObject.auth_token]) {
            NSLog(@"Login didn't return a valid token");
        }
        
        //I have a socialName, just not which social service it is yet. maybe check for @?
        if (userObject.socialName) {
            if (userObject.twitter) {
                [UICKeyChainStore setString:userObject.socialName forKey:FluxUsernameKey service:TwitterService];
            }
            else{
                [UICKeyChainStore setString:userObject.socialName forKey:FluxNameKey service:FacebookService];
            }
        }

        
        
        
        if (new) {
            //be sure the tutorial is shown
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:@"showedTutorial"];
            [defaults synchronize];
            
            [ProgressHUD showSuccess:@"Welcome To Flux!"];
        }
        else{
//            [ProgressHUD showSuccess:[NSString stringWithFormat: @"Welcome back @%@", userObject.username]];
        }
        [self didLoginSuccessfullyWithUserID:userObject.userID];
    }];
    [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        NSString*str;
        if (new) {
            str = [NSString stringWithFormat:@"Login failed"];
        }
        else{
            str = [description stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[description substringToIndex:1] capitalizedString]];
        }
        [self loginRegistrationFailedWithString:str];
    }];
    [self hideKeyboard];
    [self.fluxDataManager loginUser:user withDataRequest:dataRequest];
}

#pragma mark Login IB Actions

- (IBAction)createAccountButtonAction:(id)sender {
    if (isInSignUp) {
        //if they got here by pressing "join" on the keyboard, but didn't get all checkmarks yet.
        if (![self canCreateAccount]) {
            [ProgressHUD showError:@"Please fill out the fields to create an account"];
            return;
        }
//        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Welcome!" message:@"Thanks for your interest in Flux. At the moment, Flux is still in beta, and requires a pin to continue. If you're one of the lucky ones, please enter your pin below." delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"Activate Pin", nil];
//        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
//        [alert show];
//        [alert becomeFirstResponder];
        
        
        //skip pin for now
        [self hideContainerViewAnimated:YES];
        [self loginSignupWithPin:0];
    }
    else{
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSString*username = cell.textField.text;
        
        cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        NSString*password = cell.textField.text;
        
        if (username.length == 0 || password.length == 0) {
            [ProgressHUD showError:@"Please fill out the\n fields to sign in"];
//            [self showContainerViewAnimated:YES];
        }
        else{
            [self hideContainerViewAnimated:YES];
            [self loginSignupWithPin:0];
        }
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
        showUernamePrompt = NO;
        [textInputElements removeObjectAtIndex:2];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self performSelector:@selector(reloadTheRow) withObject:nil afterDelay:0.0];
        [loginTogglePromptLabel setText:@"Don't have an acount yet?"];
        [loginToggleButton setTitle:@"Sign up!" forState:UIControlStateNormal];
        [loginToggleButton setEnabled:NO];
        
        [UIView setAnimationsEnabled:NO];
        [createLoginButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [UIView setAnimationsEnabled:YES];
        [createLoginButton setEnabled:NO];
        
        [forgotPasswordButton setHidden:NO];
        [UIView animateWithDuration:0.3 animations:^{
            [twitterButton setAlpha:0.0];
            [facebookButton setAlpha:0.0];
            [topSeparator setAlpha:0.0];
            [signInOptionsLabel setAlpha:0.0];
            [createLoginButton setCenter:CGPointMake(createLoginButton.center.x, createLoginButton.center.y-50)];
            [forgotPasswordButton setAlpha:0.8];
        } completion:^(BOOL finished){
            [loginToggleButton setEnabled:YES];
            [createLoginButton setEnabled:YES];
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
        [createLoginButton setEnabled:NO];
        
        [UIView setAnimationsEnabled:NO];
        [createLoginButton setTitle:@"Create Account" forState:UIControlStateNormal];
        [UIView setAnimationsEnabled:YES];

        
        [UIView animateWithDuration:0.3 animations:^{
            [twitterButton setAlpha:1.0];
            [facebookButton setAlpha:1.0];
            [topSeparator setAlpha:1.0];
            [signInOptionsLabel setAlpha:1.0];
            [createLoginButton setCenter:CGPointMake(createLoginButton.center.x, createLoginButton.center.y+50)];
            [forgotPasswordButton setAlpha:0.0];
        } completion:^(BOOL finished){
            [loginToggleButton setEnabled:YES];
            [createLoginButton setEnabled:YES];
            [forgotPasswordButton setHidden:YES];
        }];
    }
}

- (IBAction)backdoorButtonAction:(id)sender {
//    // set userid and cameraid to 1 here, trigger a camera registration too.
//    [UICKeyChainStore setString:@"" forKey:FluxUsernameKey service:FluxService];
//    [UICKeyChainStore setString:@"1" forKey:FluxUserIDKey service:FluxService];
//    [UICKeyChainStore setString:@"" forKey:FluxTokenKey service:FluxService];
//    [self didLoginSuccessfullyWithUserID:1];
//    [self hideKeyboard];
//    [self hideContainerViewAnimated:YES];
//    [self performSelector:@selector(fadeOutLogin) withObject:Nil afterDelay:0.5];
}

//shows an alert with email keyboard and waits for a valid email before it sends a password reset email request.
- (IBAction)forgetPasswordButtonAction:(id)sender {

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"We've all done it."
                                                        message:@"To which email do you want us to send a password reset?"
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Send", nil];
    
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [(UITextField*)[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    [(UITextField*)[alertView textFieldAtIndex:0] setTintColor:[UIColor blackColor]];
    
    [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            UITextField *emailTextField = [alertView textFieldAtIndex:0];
            if ([self NSStringIsValidEmail:emailTextField.text]) {
                
                FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
                [dataRequest setSendPasswordResetComplete:^(FluxDataRequest*completedRequest){
                    [ProgressHUD showSuccess:[NSString stringWithFormat:@"We sent an email to %@",emailTextField.text]];
                    [self hideKeyboard];
                }];
                [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                    [ProgressHUD showError:@"The email failed to send."];
                }];
                [self.fluxDataManager sendPasswordResetTo:emailTextField.text withRequest:dataRequest];
            }
            //not a valid email
            else{
                [ProgressHUD showError:@"Sorry, but that's not a valid email address."];
            }
        }
    }];
}

//#pragma mark - UIActionSheetDelegate
//
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex != actionSheet.cancelButtonIndex) {
//        [self loginWithTwitterForAccountIndex:buttonIndex];
//    }
//    else{
//        [self showContainerViewAnimated:YES];
//    }
//}

#pragma mark - View Helpers

- (void)hideContainerViewAnimated:(BOOL)animated{
    //don't hide it if it's already hidden
    if (logoImageView.frame.origin.y > 100) {
        return;
    }
    if (animated) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [UIView animateWithDuration:0.3  animations:^{
            [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
            if (self.view.bounds.size.height < 500) {
                [logoImageView setFrame:CGRectMake(self.view.center.x-logoImageView.frame.size.width, self.view.center.y-logoImageView.frame.size.height, logoImageView.frame.size.width*2, logoImageView.frame.size.height*2)];
            }
            else{
                [logoImageView setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
            }
            [logoImageView startAnimating];
        }];
    }
    else{
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
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
    //don't show it if it's already shown
    if (logoImageView.frame.origin.y < 100) {
        return;
    }
    if (![loginElementsContainerView translatesAutoresizingMaskIntoConstraints]) {
        [loginElementsContainerView removeFromSuperview];
        [loginElementsContainerView setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self.view addSubview:loginElementsContainerView];
        
    }

    if (animated) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [UIView animateWithDuration:0.5 animations:^{
            [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height-loginElementsContainerView.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
            if (self.view.bounds.size.height < 500) {
                [logoImageView setFrame:CGRectMake(self.view.center.x-(logoImageView.frame.size.width/2/2), 25, logoImageView.frame.size.width/2, logoImageView.frame.size.height/2)];
            }
            else{
                [logoImageView setCenter:CGPointMake(self.view.center.x, 97)];
            }
            [logoImageView stopAnimating];
        }];
    }
    else{
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height-loginElementsContainerView.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
        if (self.view.bounds.size.height < 500) {
            [logoImageView setFrame:CGRectMake(self.view.center.x-(logoImageView.frame.size.width/2/2), 25, logoImageView.frame.size.width/2, logoImageView.frame.size.height/2)];
        }
        else{
            [logoImageView setCenter:CGPointMake(self.view.center.x, 97)];
        }
        [logoImageView stopAnimating];
    }
}

-(void)checkTextCompletionForTextField:(UITextField*)textField andString:(NSString*)string{
    if (isInSignUp) {
        for (int i = 0; i<textInputElements.count; i++) {
            if ([textField.placeholder isEqualToString:[textInputElements objectAtIndex:i]]) {
                FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                switch (i) {
                    case 0:
                        [cell setChecked:NO];
                        [self changeOKArrayIndex:i andChecked:NO];
                        
                        break;
                    case 1:
                    {
                        if (string.length > 5) {
                            
                            [cell setChecked:YES];
                            [self changeOKArrayIndex:i andChecked:YES];
                        }
                        else{
                            [cell setChecked:NO];
                            [self changeOKArrayIndex:i andChecked:NO];
                        }
                    }
                        break;
                    case 2:
                    {
                        if ([self NSStringIsValidEmail:string]) {
                            [cell setChecked:YES];
                            [self changeOKArrayIndex:i andChecked:YES];
                        }
                        else{
                            [cell setChecked:NO];
                            [self changeOKArrayIndex:i andChecked:NO];
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

- (void)changeOKArrayIndex:(int)i andChecked:(BOOL)checked{
    [registrationOKArray replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:checked]];
    [createLoginButton setEnabled:[self canCreateAccount]];
}

-(BOOL)canCreateAccount{
    if ([registrationOKArray containsObject:[NSNumber numberWithBool:NO]]) {
        return NO;
    }
    else{
        return YES;
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
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:0],[NSIndexPath indexPathForRow:1 inSection:0], nil] withRowAnimation:UITableViewRowAnimationFade];
    shouldErase = NO;
}

#pragma mark - Logout
- (void)userDidLogOut{
    //force the view to show registration (not signup) if they're logging out (view is not visible)
    if (!isInSignUp) {
        //if we're in sign in, test if view is visible
        if(!self.view.window){
            //we're in sign-in, and the view isn;t visible
           [self loginSignupToggleAction:nil];
        }
    }
    
    //close facebook session
    if (FBSession.activeSession.isOpen) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    
    //remove profile pic
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"image.png"]; //Add the file name
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtPath:filePath error:nil];
    NSLog((success ? @"Successfully delete profile pic" : @"Didn't Delete the profile pic"));
    
    //remove settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"profileImage"];
    [defaults removeObjectForKey:@"cameraID"];
    [defaults removeObjectForKey:@"bio"];
    [defaults removeObjectForKey:@"snapshotImages"];
    [defaults synchronize];
    //clear keychain _after_ other elements have had a chance to close down
    [UICKeyChainStore removeAllItemsForService:FluxService];
    [UICKeyChainStore removeAllItemsForService:FacebookService];
    [UICKeyChainStore removeAllItemsForService:TwitterService];
    
    
    // log out of the server...
    // ZZZ
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        NSLog(@"Logout failed with error %d", (int)[e code]);
    }];
    [self.fluxDataManager logoutWithDataRequest:dataRequest];

    for (int i = 0; i<[self.tableView numberOfRowsInSection:0]; i++) {
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        cell.textField.text = @"";
        [cell setChecked:NO];
    }
    
    [self showContainerViewAnimated:YES];
    
    //delete all failed imagery
    NSString*failedImagesFolderDirectory = [NSString stringWithFormat:@"%@%@",[paths objectAtIndex:0],@"/imageUploadCache/"];
    NSError *error = nil;
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:failedImagesFolderDirectory error:&error]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", failedImagesFolderDirectory, file] error:&error];
        if (!success || error) {
            // it failed.
        }
    }
    
    
}

@end
