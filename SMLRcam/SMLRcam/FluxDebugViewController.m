//
//  FluxDebugViewController.m
//  Flux
//
//  Created by Kei Turner on 1/30/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxDebugViewController.h"
#import "FluxScanViewController.h"

@interface FluxDebugViewController ()

@end

@implementation FluxDebugViewController

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)slider1DidSlide:(id)sender {
}

- (IBAction)slider2DidSlide:(id)sender {
}

- (IBAction)slider3DidSlide:(id)sender {
}
- (IBAction)segmentedControl1DidChange:(id)sender {
}



- (IBAction)switch1DidChange:(id)sender {
}

- (IBAction)switch2DidChange:(id)sender {
}

- (IBAction)switch3DidChange:(id)sender {
}

- (IBAction)stepper1DidStep:(id)sender {
}

- (IBAction)hideMenuAction:(id)sender {
    [(FluxScanViewController*)self.parentViewController hideDebugMenu];
}
@end
