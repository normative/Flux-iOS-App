//
//  FluxLoginViewController.m
//  Flux
//
//  Created by Kei Turner on 11/4/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxLoginViewController.h"
#import "ProgressHUD.h"

@interface FluxLoginViewController ()

@end

@implementation FluxLoginViewController

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
    self.fluxDataManager = [[FluxDataManager alloc]init];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 50)];
    label.backgroundColor = [UIColor clearColor];
    [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:17.0]];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.adjustsFontSizeToFitWidth = YES;
    label.text = self.title;
    self.navigationItem.titleView = label;
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)loginButtonActoin:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isremote = [[defaults objectForKey:@"Server Location"]intValue];
    if (isremote) {
        [self fadeOutLogin];
        return;
    }
    
    [self.navigationItem.leftBarButtonItem setEnabled:NO];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    FluxUserObject *newUser = [[FluxUserObject alloc]init];
    [newUser setUsername:self.usernameTextField.text];
    [newUser setPassword:self.passwordField.text];
    
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

- (void)hideKeyboard{
    [self.usernameTextField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

- (void)fadeOutLogin
{

}
@end
