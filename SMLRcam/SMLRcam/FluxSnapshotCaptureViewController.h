//
//  FluxSnapshotCaptureViewController.h
//  Flux
//
//  Created by Kei Turner on 1/21/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxCameraRollButton.h"

@interface FluxSnapshotCaptureViewController : UIViewController{
    UIView *blackView;
}
@property (strong, nonatomic) IBOutlet FluxCameraRollButton *snapshotRollButton;
- (IBAction)closeButtonAction:(id)sender;
- (IBAction)snapshotRollButtonAction:(id)sender;
- (void)addsnapshot:(NSNotification*)notification;

@end
