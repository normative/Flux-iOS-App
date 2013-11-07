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
        NSString*str = [NSString stringWithFormat:@"Image Upload Failed with error %d", (int)[e code]];
        [ProgressHUD showError:str];
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
@end
