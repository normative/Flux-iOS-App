//
//  FluxSnapshotCaptureViewController.h
//  Flux
//
//  Created by Kei Turner on 1/21/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxCameraRollButton.h"

#import "FluxImageAnnotationViewController.h"

@interface FluxSnapshotCaptureViewController : UIViewController<ImageAnnotationDelegate>{
    UIView *blackView;
    UIImageView*newSnapshotView;
    UIImage*newSnapshot;
    IBOutlet UIButton *shareButton;
}
@property (strong, nonatomic) IBOutlet FluxCameraRollButton *snapshotRollButton;
- (IBAction)closeButtonAction:(id)sender;
- (IBAction)snapshotRollButtonAction:(id)sender;
- (void)addsnapshot:(NSNotification*)notification;
- (IBAction)shareButtonAction:(id)sender;

@end
