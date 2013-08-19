//
//  FluxNatigationViewController.m
//  Flux
//
//  Created by Jacky So on 2013-08-16.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxNatigationViewController.h"

@interface FluxNatigationViewController ()

@end

@implementation FluxNatigationViewController

# pragma mark - orientation and rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

# pragma mark - view lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"%s",__func__);
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"%s",__func__);
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"%s",__func__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
