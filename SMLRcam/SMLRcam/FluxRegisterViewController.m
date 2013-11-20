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
#import "FluxTextFieldCell.h"
#import "UICKeyChainStore.h"

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
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Welcome"
                                                      message:@"In order to bypass the signup flow, just tap on the create account button, or the sign in button."
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
    

    [self checkCurrentLoginState];
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
    
    self.fluxDataManager = [[FluxDataManager alloc]init];
    
    textInputElements = [[NSMutableArray alloc]initWithObjects:@"Username", @"Password", @"Email", nil];
    
    //[logoImageView setFrame:CGRectMake(logoImageView.frame.origin.x, logoImageView.frame.origin.y+60, logoImageView.frame.size.width, logoImageView.frame.size.height)];
    [logoImageView setCenter:CGPointMake(logoImageView.center.x, logoImageView.center.y+100)];

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
    return cell;
}

#pragma mark - Login/Signup
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

}

- (void)fadeOutLogin
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self performSegueWithIdentifier:@"pushScanView" sender:self];
}

- (IBAction)createAccountButtonAction:(id)sender {
    [self hideContainerViewAnimated:YES];
    [self performSelector:@selector(fadeOutLogin) withObject:nil afterDelay:0.5];
    return;
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Welcome!" message:@"Thanks for taking the time to look into Flux. At the moment, Flux is still in beta, and requires a pin to continue. If you're one of the lucky ones, please enter your pin below." delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"Activate Pin", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert becomeFirstResponder];
    [alert show];
}


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
        
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        BOOL isremote = [[defaults objectForKey:@"Server Location"]intValue];
//        if (!isremote) {
//            [self fadeOutLogin];
//            return;
//        }
        
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
        [dataRequest setUploadUserComplete:^(FluxUserObject*uploadedUserObject, FluxDataRequest *completedDataRequest){
            [ProgressHUD showSuccess:@"Account Created!"];
            [self performSelector:@selector(fadeOutLogin) withObject:nil afterDelay:0.3];
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
        [dataRequest setLoginUserComplete:^(NSString*token, FluxDataRequest * completedDataRequest){
            [UICKeyChainStore setString:username forKey:@"username" service:@"com.flux"];
            [UICKeyChainStore setString:password forKey:@"password" service:@"com.flux"];
            [UICKeyChainStore setString:token forKey:@"token" service:@"com.flux"];
            
            [ProgressHUD showSuccess:@"Login Successful"];
            [self performSelector:@selector(fadeOutLogin) withObject:nil afterDelay:0.3];
        }];
        [dataRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
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

- (void)checkCurrentLoginState{
    NSString *username = [UICKeyChainStore stringForKey:@"username" service:@"com.flux"];
    NSString *password = [UICKeyChainStore stringForKey:@"password" service:@"com.flux"];
    NSString *token = [UICKeyChainStore stringForKey:@"token" service:@"com.flux"];
    
    if (username && token && password) {
        [self fadeOutLogin];
    }
    else{
        [self showContainerViewAnimated:YES];
    }
}

- (IBAction)loginSignupToggleAction:(id)sender {
    if (isInSignUp) {
        isInSignUp = NO;
        [textInputElements removeObjectAtIndex:2];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self performSelector:@selector(reloadTheRow) withObject:nil afterDelay:0.0];
        [loginTogglePromptLabel setText:@"Don't have an acount yet?"];
        [loginToggleButton setTitle:@"Sign up!" forState:UIControlStateNormal];
        
        [UIView setAnimationsEnabled:NO];
        [createLoginButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [UIView setAnimationsEnabled:YES];
        
        [UIView animateWithDuration:0.2 animations:^{
            [twitterButton setAlpha:0.0];
            [facebookButton setAlpha:0.0];
            [topSeparator setAlpha:0.0];
        } completion:nil];
    }
    else{
        isInSignUp = YES;
        [textInputElements insertObject:@"email" atIndex:2];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [self performSelector:@selector(reloadTheRow) withObject:nil afterDelay:0.0];
        [loginTogglePromptLabel setText:@"Already have an Account?"];
        [loginToggleButton setTitle:@"Sign in!" forState:UIControlStateNormal];
        
        [UIView setAnimationsEnabled:NO];
        [createLoginButton setTitle:@"Create Account" forState:UIControlStateNormal];
        [UIView setAnimationsEnabled:YES];

        
        [UIView animateWithDuration:0.2 animations:^{
            [twitterButton setAlpha:1.0];
            [facebookButton setAlpha:1.0];
            [topSeparator setAlpha:1.0];
        } completion:nil];
    }
}

#pragma mark - View Helpers

- (void)hideContainerViewAnimated:(BOOL)animated{
    if (animated) {
        [UIView animateWithDuration:0.3  animations:^{
            [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
            [logoImageView setCenter:CGPointMake(logoImageView.center.x, self.view.center.y)];
        }];
    }
    else{
        [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
        [logoImageView setCenter:CGPointMake(logoImageView.center.x, self.view.center.y)];
    }
}

- (void)showContainerViewAnimated:(BOOL)animated{
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height-loginElementsContainerView.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
            [logoImageView setCenter:CGPointMake(logoImageView.center.x, 94)];
        }];
    }
    else{
        [loginElementsContainerView setFrame:CGRectMake(0, self.view.frame.size.height-loginElementsContainerView.frame.size.height, loginElementsContainerView.frame.size.width, loginElementsContainerView.frame.size.height)];
        [logoImageView setCenter:CGPointMake(logoImageView.center.x, 94)];
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

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (void)reloadTheRow{
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

@end
