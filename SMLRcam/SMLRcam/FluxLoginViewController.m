//
//  FluxLoginViewController.m
//  Flux
//
//  Created by Kei Turner on 10/28/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxLoginViewController.h"


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
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [self performSelector:@selector(fadeOutLogin) withObject:self afterDelay:0.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)fadeOutLogin{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                             bundle: nil];
    
    
    leftSideDrawerViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"FluxLeftDrawerViewController"];
    UINavigationController *leftDrawerNavigationController = [[UINavigationController alloc] initWithRootViewController:leftSideDrawerViewController];
    if ([leftDrawerNavigationController.navigationBar respondsToSelector:@selector(setBackgroundColor:)])
    {
        [leftDrawerNavigationController.navigationBar setBarTintColor:[UIColor blackColor]];
        leftDrawerNavigationController.navigationBar.translucent = NO;
    }
    
    scanViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"FluxScanViewController"];
    
    drawerController = [[MMDrawerController alloc] initWithCenterViewController:scanViewController  leftDrawerViewController:leftDrawerNavigationController];
    
    [drawerController setMaximumLeftDrawerWidth:256.0];
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    [drawerController setCloseDrawerGestureModeMask: (MMCloseDrawerGestureModeBezelPanningCenterView | MMCloseDrawerGestureModeTapCenterView | MMCloseDrawerGestureModeBezelPanningCenterView)];
    
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
