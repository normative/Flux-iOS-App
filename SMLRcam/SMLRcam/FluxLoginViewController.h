//
//  FluxLoginViewController.h
//  Flux
//
//  Created by Kei Turner on 10/28/2013.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMDrawerController.h"
#import "FluxLeftDrawerViewController.h"
#import "FluxScanViewController.h"

@interface FluxLoginViewController : UIViewController{
    __strong FluxLeftDrawerViewController * leftSideDrawerViewController;
    __strong FluxScanViewController * scanViewController;
    __strong MMDrawerController * drawerController;
}



@end
