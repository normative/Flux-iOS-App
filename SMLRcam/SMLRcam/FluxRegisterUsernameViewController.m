//
//  FluxRegisterUsernameViewController.m
//  Flux
//
//  Created by Kei Turner on 1/6/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxRegisterUsernameViewController.h"
#import "FluxTextFieldCell.h"

@interface FluxRegisterUsernameViewController ()

@end

@implementation FluxRegisterUsernameViewController

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
        if ([delegate respondsToSelector:@selector(RegisterUsernameView:didAcceptAddUsernameToUserInfo:)]) {
            [delegate RegisterUsernameView:self didAcceptAddUsernameToUserInfo:nil];
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
    [cell setupForPosition:FluxTextFieldPositionTopBottom andPlaceholder:@"username"];
    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [cell.textField setKeyboardType:UIKeyboardTypeDefault];
    [cell.textField setSecureTextEntry:NO];
    [cell.textField setReturnKeyType:UIReturnKeyJoin];
    
    
    [cell.textField setDelegate:self];
    cell.textField.textAlignment = NSTextAlignmentCenter;
    [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.textLabel.font.pointSize]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    
    if (showUernamePrompt) {
        if (!cell.warningLabel) {
            cell.warningLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 40, cell.frame.size.width, 25)];
            [cell.warningLabel setFont:[UIFont fontWithName:@"Akkurat" size:14.0]];
            [cell.warningLabel setTextColor:[UIColor colorWithRed:107/255.0 green:29/255.0 blue:29/255.0 alpha:1.0]];
            [cell.warningLabel setTextAlignment:NSTextAlignmentCenter];
            [cell.warningLabel setText:@"this username has already been taken"];
        }
        
        [cell addSubview:cell.warningLabel];
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
    username = text;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    [self checkUsernameUniqueness];
    return YES;
}

- (void)checkUsernameUniqueness{
    FluxTextFieldCell*cell = (FluxTextFieldCell*)[usernameTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [cell setLoading:YES];
    
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setUsernameUniquenessComplete:^(BOOL unique, NSString*suggestion, FluxDataRequest*completedRequest){
        [cell setLoading:NO];
        if (unique) {
            if (showUernamePrompt) {
                showUernamePrompt = NO;
                
                [usernameTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                
            }
            [self performSelector:@selector(setUsernameCellChecked) withObject:nil afterDelay:0.0];
        }
        
        else{
            showUernamePrompt = YES;
            [usernameTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
    [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        [cell setLoading:NO];
        NSLog(@"Unique lookup failed with error %d", (int)[e code]);
    }];
    [self.fluxDataManager checkUsernameUniqueness:username withDataRequest:dataRequest];
}

- (IBAction)createAccountButtonAction:(id)sender {
    [self.userInfo setObject:username forKey:@"username"];
    if ([delegate respondsToSelector:@selector(RegisterUsernameView:didAcceptAddUsernameToUserInfo:)]) {
        [delegate RegisterUsernameView:self didAcceptAddUsernameToUserInfo:self.userInfo];
    }
    sent = YES;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    FluxTextFieldCell*cell = (FluxTextFieldCell*)[usernameTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [cell.textField resignFirstResponder];
}

@end
