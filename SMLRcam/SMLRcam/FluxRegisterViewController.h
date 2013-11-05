//
//  FluxRegisterViewController.h
//  Flux
//
//  Created by Kei Turner on 11/4/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMDrawerController.h"
#import "FluxLeftDrawerViewController.h"
#import "FluxScanViewController.h"

#import "KTPlaceholderTextView.h"
#import "FluxNetworkServices.h"


@interface FluxRegisterViewController : UIViewController <UITextFieldDelegate, KTPlaceholderTextViewDelegate, UIScrollViewDelegate, NetworkServicesDelegate>{
    __strong FluxLeftDrawerViewController * leftSideDrawerViewController;
    __strong FluxScanViewController * scanViewController;
    __strong MMDrawerController * drawerController;
    
    NSArray*textInputElements;

    IBOutlet UIScrollView *scrollView;
    
    UIImage * profilePic;
    IBOutlet UITextField *usernameField;
    IBOutlet UITextField *passwordField;
    IBOutlet UITextField *confirmPasswordField;
    IBOutlet UITextField *nameField;
    IBOutlet UITextField *emailField;
    IBOutlet KTPlaceholderTextView *bioTextView;
}
- (IBAction)nextButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;

@end
