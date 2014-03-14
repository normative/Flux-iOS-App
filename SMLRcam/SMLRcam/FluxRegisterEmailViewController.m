//
//  FluxRegisterEmailViewController.m
//  Flux
//
//  Created by Kei Turner on 12/9/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxRegisterEmailViewController.h"
#import "FluxTextFieldCell.h"


@interface FluxRegisterEmailViewController ()

@end

@implementation FluxRegisterEmailViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];

	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.screenName = @"Register Email View";
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound && !sent) {
        if ([delegate respondsToSelector:@selector(RegisterEmailView:didAddToUserInfo:)]) {
            [delegate RegisterEmailView:self didAddToUserInfo:nil];
        }
    }
    [super viewWillDisappear:animated];
}

- (void)nextAction{
    [self performSegueWithIdentifier:@"pushUsernameSegue" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"pushUsernameSegue"]) {
        
        //if we changed the email, update it
        if (email) {
            [self.userInfo setObject:email forKey:@"email"];
        }
        FluxRegisterUsernameViewController*usernameVC = (FluxRegisterUsernameViewController*)segue.destinationViewController;
        [usernameVC setUserInfo:self.userInfo];
        [usernameVC setDelegate:self];
        [usernameVC setFluxDataManager:self.fluxDataManager];
    }
}

- (void)RegisterUsernameView:(FluxRegisterUsernameViewController *)usernameView didAcceptAddUsernameToUserInfo:(NSMutableDictionary *)userInfo{
    if (!userInfo) {
        if ([delegate respondsToSelector:@selector(RegisterEmailView:didAddToUserInfo:)]) {
            [delegate RegisterEmailView:self didAddToUserInfo:nil];
        }
        [self backAction];
        
    }
    else{
        if ([delegate respondsToSelector:@selector(RegisterEmailView:didAddToUserInfo:)]) {
            [delegate RegisterEmailView:self didAddToUserInfo:self.userInfo];
        }
        sent = YES;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)backAction{
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"textFieldCell";
    FluxTextFieldCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxTextFieldCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell setupForPosition:FluxTextFieldPositionTopBottom andPlaceholder:@"email"];
    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
    [cell.textField setReturnKeyType:UIReturnKeyDefault];

    
    [cell.textField setDelegate:self];
    cell.textField.textAlignment = NSTextAlignmentCenter;
    [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.textLabel.font.pointSize]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    
    if (![cell.textField isFirstResponder]) {
        [cell.textField becomeFirstResponder];
        
    }
    
    if ([self.userInfo objectForKey:@"email"]) {
        [cell.textField setText:[self.userInfo objectForKey:@"email"]];
        [cell setChecked:YES];
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextAction)]];
    }
    
    return cell;
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
    email = text;
    FluxTextFieldCell*cell = (FluxTextFieldCell*)[emailTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    if ([self NSStringIsValidEmail:email]) {
        [cell setChecked:YES];
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextAction)]];
    }
    else{
        [self.navigationItem setRightBarButtonItem:nil];
        [cell setChecked:NO];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if ([self NSStringIsValidEmail:textField.text]) {
        [self createAccountButtonAction:nil];
    }
    return YES;
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

- (IBAction)createAccountButtonAction:(id)sender {
    [self.userInfo setObject:email forKey:@"email"];
    if ([delegate respondsToSelector:@selector(RegisterEmailView:didAddToUserInfo:)]) {
        [delegate RegisterEmailView:self didAddToUserInfo:self.userInfo];
    }
    sent = YES;
    [self.navigationController popToRootViewControllerAnimated:YES];
}



@end
