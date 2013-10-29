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
    [self performSelector:@selector(fadeOutLogin) withObject:self afterDelay:0.2];
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
    
    scanViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"FluxScanViewController"];
    
    drawerController = [[MMDrawerController alloc] initWithCenterViewController:scanViewController  leftDrawerViewController:leftSideDrawerViewController];
    
    [drawerController setMaximumLeftDrawerWidth:256.0];
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    [drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    
    [self performSegueWithIdentifier:@"presentScanView" sender:self];
}

@end
