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
    [createAccountButton setEnabled:NO];
    [createAccountButton setAlpha:0.6];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil];
    [createAccountButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:createAccountButton.titleLabel.font.pointSize]];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES];    
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound && !sent) {
        if ([delegate respondsToSelector:@selector(RegisterEmailView:didAcceptAddEmailToUserInfo:)]) {
            [delegate RegisterEmailView:self didAcceptAddEmailToUserInfo:nil];
        }
    }
    [super viewWillDisappear:animated];
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
    [cell setupForPosition:FluxTextFieldPositionTopBottom andPlaceholder:@"email"];
    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [cell.textField setKeyboardType:UIKeyboardTypeEmailAddress];
    [cell.textField setReturnKeyType:UIReturnKeyJoin];

    
    [cell.textField setDelegate:self];
    cell.textField.textAlignment = NSTextAlignmentCenter;
    [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.textLabel.font.pointSize]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    
    if (![cell.textField isFirstResponder]) {
        [cell.textField becomeFirstResponder];
        
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
        [createAccountButton setAlpha:1.0];
        [createAccountButton setEnabled:YES];
    }
    else{
        [createAccountButton setEnabled:NO];
        [createAccountButton setAlpha:0.6];
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
    if ([delegate respondsToSelector:@selector(RegisterEmailView:didAcceptAddEmailToUserInfo:)]) {
        [delegate RegisterEmailView:self didAcceptAddEmailToUserInfo:self.userInfo];
    }
    sent = YES;
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}
@end
