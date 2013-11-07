//
//  FluxLoginViewController.h
//  Flux
//
//  Created by Kei Turner on 11/4/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxDataManager.h"

#import "MMDrawerController.h"
#import "FluxLeftDrawerViewController.h"
#import "FluxScanViewController.h"

@interface FluxLoginViewController : UIViewController{

    __strong FluxLeftDrawerViewController * leftSideDrawerViewController;
    __strong FluxScanViewController * scanViewController;
    __strong MMDrawerController * drawerController;
}

@property (nonatomic, strong) FluxDataManager *fluxDataManager;
@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)loginButtonActoin:(id)sender;

@end
