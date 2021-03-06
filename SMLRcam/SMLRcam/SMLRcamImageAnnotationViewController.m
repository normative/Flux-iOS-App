//
//  SMLRcamImageAnnotationViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-29.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import "SMLRcamImageAnnotationViewController.h"

@interface SMLRcamImageAnnotationViewController ()

@end

@implementation SMLRcamImageAnnotationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setCapturedImage:(UIImage*)theCapturedImage{
    capturedImage = theCapturedImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)PopViewController:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)ConfirmImage:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
