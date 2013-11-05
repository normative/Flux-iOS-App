//
//  FluxRegisterViewController.m
//  Flux
//
//  Created by Kei Turner on 11/4/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxRegisterViewController.h"

#import "FluxUserObject.h"


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
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 50)];
    label.backgroundColor = [UIColor clearColor];
    [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:17.0]];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.adjustsFontSizeToFitWidth = YES;
    label.text = self.title;
    self.navigationItem.titleView = label;
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidAppear:(BOOL)animated{
    [scrollView setContentSize:CGSizeMake(scrollView.bounds.size.width, scrollView.bounds.size.height-self.navigationController.navigationBar.frame.size.height-19)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [bioTextView setPlaceholderText:@"Tell people about yourself"];
    [bioTextView setPlaceholderColor:[UIColor darkGrayColor]];
    [bioTextView setTheDelegate:self];
    
    textInputElements = [[NSArray alloc]initWithObjects:usernameField, passwordField, confirmPasswordField, nameField, emailField, bioTextView, nil];
    scrollView.delegate=self;
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
    int index = [textInputElements indexOfObject:textField];
    if (index+1 < textInputElements.count) {
        [[textInputElements objectAtIndex:index+1]becomeFirstResponder];
        if ([[textInputElements objectAtIndex:index+1] isKindOfClass:[KTPlaceholderTextView class]]) {
            [scrollView setContentOffset:CGPointMake(0,textField.center.y-150) animated:YES];
        }
        
    }
    else{
        [scrollView setContentOffset:CGPointMake(0,0) animated:YES];
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)PlaceholderTextViewDidBeginEditing:(KTPlaceholderTextView *)placeholderTextView{
    [scrollView setContentOffset:CGPointMake(0,placeholderTextView.center.y-250) animated:YES];
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

- (IBAction)nextButtonAction:(id)sender {
//    FluxUserObject *newUser = [[FluxUserObject alloc]initWithName:nameField.text andUsername:usernameField.text andPassword:passwordField.text andEmail:emailField.text andProfilePic:    profilePic];
//    
//    FluxNetworkServices * networkServices = [[FluxNetworkServices alloc]init];
//    [networkServices createUser:newUser];
    
    [self fadeOutLogin];

}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didCreateUser:(FluxUserObject *)userObject{
    [self fadeOutLogin];
}

- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
