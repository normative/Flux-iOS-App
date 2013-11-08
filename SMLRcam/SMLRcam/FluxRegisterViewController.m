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
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Welcome"
                                                      message:@"In order to bypass the signup flow, just tap on the create account button, or the sign in button."
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
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
    
    textInputElements = [[NSMutableArray alloc]initWithObjects:@"username", @"password", @"email", nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Text Delegate Methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    if ([textField.placeholder isEqualToString:[textInputElements objectAtIndex:textInputElements.count-1]]) {
        //sign in
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

- (void)hideKeyboard{
    for (int i = 0; i<textInputElements.count; i++) {
        FluxTextFieldCell*cell = (FluxTextFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [cell.textField resignFirstResponder];
    }
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
                    [cell.textField setReturnKeyType:UIReturnKeyDone];
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self hideKeyboard];
}


- (void)fadeOutLogin
{
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                             bundle: nil];
    
    
    leftSideDrawerViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"FluxLeftDrawerViewController"];
    UINavigationController *leftDrawerNavigationController = [[UINavigationController alloc] initWithRootViewController:leftSideDrawerViewController];
    
    scanViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"FluxScanViewController"];
    
    drawerController = [[MMDrawerController alloc] initWithCenterViewController:scanViewController  leftDrawerViewController:leftDrawerNavigationController];
    leftSideDrawerViewController.drawerController = drawerController;
    
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    [drawerController setCloseDrawerGestureModeMask: (MMCloseDrawerGestureModeTapCenterView | MMCloseDrawerGestureModePanningCenterView)];
    
    [drawerController setGestureCompletionBlock:^(MMDrawerController *theDrawerController, UIGestureRecognizer *gesture) {
        
        if (([theDrawerController.leftDrawerViewController class] == NSClassFromString(@"UINavigationController"))&&
            (theDrawerController.openSide != MMDrawerSideLeft))
        {
            UINavigationController *navController = (UINavigationController *)theDrawerController.leftDrawerViewController;
            [navController popToRootViewControllerAnimated:YES];
        }
    }];
    [drawerController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [self presentViewController:drawerController animated:YES completion:nil];
}

- (IBAction)createAccountButtonAction:(id)sender {
    [self fadeOutLogin];
    return;
    
    if (isInSignUp) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL isremote = [[defaults objectForKey:@"Server Location"]intValue];
        if (!isremote) {
            [self fadeOutLogin];
            return;
        }
        
        FluxUserObject *newUser = [[FluxUserObject alloc]init];
        [newUser setUsername:usernameField.text];
        [newUser setPassword:passwordField.text];
        [newUser setEmail:emailField.text];
        
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setUploadUserComplete:^(FluxUserObject*uploadedUserObject, FluxDataRequest *completedDataRequest){
            [ProgressHUD showSuccess:@"Account Created!"];
            [self performSelector:@selector(fadeOutLogin) withObject:nil afterDelay:0.3];
        }];
        [dataRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            NSString*str = [NSString stringWithFormat:@"Image Upload Failed with error %d", (int)[e code]];
            [ProgressHUD showError:str];
        }];
        [self hideKeyboard];
        [ProgressHUD show:@"Creating Your Account"];
        [self.fluxDataManager uploadNewUser:newUser withImage:nil withDataRequest:dataRequest];
    }
    else{
        FluxUserObject *newUser = [[FluxUserObject alloc]init];
        [newUser setUsername:usernameField.text];
        [newUser setPassword:passwordField.text];
        
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setLoginUserComplete:^(NSString*token, FluxDataRequest * completedDataRequest){
            [ProgressHUD showSuccess:@"Login Successful"];
            [self performSelector:@selector(fadeOutLogin) withObject:nil afterDelay:0.3];
        }];
        [dataRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
            [self.navigationItem.leftBarButtonItem setEnabled:YES];
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            if ([e.userInfo objectForKey:@"NSLocalizedRecoverySuggestion"]) {
                [ProgressHUD showError:(NSString*)[e.userInfo objectForKey:@"NSLocalizedRecoverySuggestion"]];
            }
            else{
                NSString*str = [NSString stringWithFormat:@"Image Upload Failed with error %d", (int)[e code]];
                [ProgressHUD showError:str];
            }
        }];
        [self hideKeyboard];
        [ProgressHUD show:nil];
        [self.fluxDataManager loginUser:newUser withDataRequest:dataRequest];
    }
}

- (IBAction)loginSignupToggleAction:(id)sender {
    if (isInSignUp) {
        isInSignUp = NO;
        [textInputElements removeObjectAtIndex:2];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
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
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
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

- (void)reloadTheRow{
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
