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


@interface FluxRegisterViewController : UIViewController{
    __strong FluxLeftDrawerViewController * leftSideDrawerViewController;
    __strong FluxScanViewController * scanViewController;
    __strong MMDrawerController * drawerController;
    IBOutlet KTPlaceholderTextView *bioTextView;
}
- (IBAction)nextButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;

@end
