//
//  FluxSnapshotCaptureViewController.m
//  Flux
//
//  Created by Kei Turner on 1/21/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSnapshotCaptureViewController.h"
#import "UIAlertView+Blocks.h"
#import "AssetsLibrary/AssetsLibrary.h"

@interface FluxSnapshotCaptureViewController ()

@end

@implementation FluxSnapshotCaptureViewController


#pragma mark - Liew Lifecycle

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
    
    self.snapshotRollButton.layer.cornerRadius = 1.5;
    self.snapshotRollButton.layer.masksToBounds = YES;
    
    blackView = [[UIView alloc]initWithFrame:self.view.bounds];
    [blackView setBackgroundColor:[UIColor blackColor]];
    [blackView setAlpha:0.0];
    [blackView setHidden:YES];
    [self.view addSubview:blackView];

	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
}

#pragma mark - Other
- (void)addsnapshot:(NSNotification*)notification{
    [self showFlash:[UIColor blackColor]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"didCaptureBackgroundSnapshot" object:nil];
    [self addImageToSnapshotRoll:(UIImage*)[[notification userInfo]objectForKey:@"snapshot"]];
}

- (void)addImageToSnapshotRoll:(UIImage*)image{    
    if (![ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"May We?"
                                                            message:@"In order to save your snapshots to your device, we need access to your photos"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Sure", nil];
        
        [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self saveImageLocally:image];
            }
        }];
    }
    else{
        [self saveImageLocally:image];
    }
    
    
}

- (void)saveImageLocally: (UIImage*)image{
    [self.snapshotRollButton addImage:image];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    // Request to save the image to camera roll
    [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
        if (error) {
            NSLog(@"error saving snapshot");
        } else {
            NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
            NSMutableArray * picturesArray = [NSMutableArray arrayWithArray:[defaults objectForKey:@"snapshotImages"]];
            if (picturesArray) {
                [picturesArray addObject:[assetURL absoluteString]];
                [defaults setObject:picturesArray forKey:@"snapshotImages"];
            }
            else{
                NSMutableArray*pics = [NSMutableArray arrayWithObject:assetURL];
                [defaults setObject:pics forKey:@"snapshotImages"];
            }
            [defaults synchronize];
            
            
            NSLog(@"saved Image url %@", assetURL);
        }
    }];
}


- (void)showFlash:(UIColor*)color {
    [blackView setHidden:NO];
    [blackView setBackgroundColor:color];
    [UIView animateWithDuration:0.09 animations:^{
        [blackView setAlpha:0.9];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.09 animations:^{
                [blackView setAlpha:0.0];
            } completion:^(BOOL finished) {
                [blackView setHidden:YES];
            }];
    }];
}


#pragma mark - IBActions
- (IBAction)closeButtonAction:(id)sender {
    [self.view setHidden:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FluxImageCaptureDidPop"
                                                        object:self userInfo:nil];
}

- (IBAction)snapshotRollButtonAction:(id)sender {
}
@end
