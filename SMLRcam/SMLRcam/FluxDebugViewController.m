//
//  FluxDebugViewController.m
//  Flux
//
//  Created by Kei Turner on 1/30/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxDebugViewController.h"
#import "FluxScanViewController.h"
#import "FluxDisplayManager.h"
#import "FluxDataManager.h"

#import "UICKeyChainStore.h"
#import "UIActionSheet+Blocks.h"

NSString* const FluxDebugDidChangeMatchDebugImageOutput = @"FluxDebugDidChangeMatchDebugImageOutput";
NSString* const FluxDebugMatchDebugImageOutputKey = @"FluxDebugMatchDebugImageOutputKey";
NSString* const FluxDebugDidChangeTeleportLocationIndex = @"FluxDebugDidChangeTeleportLocationIndex";
NSString* const FluxDebugTeleportLocationIndexKey = @"FluxDebugTeleportLocationIndexKey";
NSString* const FluxDebugDidChangePedometerCountDisplay = @"FluxDebugDidChangePedometerCountDisplay";
NSString* const FluxDebugPedometerCountDisplayKey = @"FluxDebugPedometerCountDisplayKey";
NSString* const FluxDebugDidChangeHistoricalPhotoPicker = @"FluxDebugDidChangeHistoricalPhotoPicker";
NSString* const FluxDebugHistoricalPhotoPickerKey = @"FluxDebugHistoricalPhotoPickerKey";

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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [segmentedControl1 setSelectedSegmentIndex:[(NSString*)[defaults objectForKey:@"Border"]intValue]-1];
    [segmentedControl2 setSelectedSegmentIndex:[(NSString*)[defaults objectForKey:FluxDebugTeleportLocationIndexKey] intValue] - 1];
    
    [switch1 setOn:[[defaults objectForKey:FluxDebugMatchDebugImageOutputKey] boolValue]];
    [switch2 setOn:[[defaults objectForKey:FluxDebugPedometerCountDisplayKey] boolValue]];
    [switch3 setOn:[[defaults objectForKey:FluxDebugHistoricalPhotoPickerKey] boolValue]];
    
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

- (IBAction)segmentedControl1DidChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSString stringWithFormat:@"%i",[(UISegmentedControl*)sender selectedSegmentIndex]+1] forKey:@"Border"];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BorderChange"
                                                        object:self userInfo:nil];
}

- (IBAction)segmentedControl2DidChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSString stringWithFormat:@"%i",[(UISegmentedControl*)sender selectedSegmentIndex]+1] forKey:FluxDebugTeleportLocationIndexKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDebugDidChangeTeleportLocationIndex
                                                        object:self userInfo:nil];
}

- (IBAction)switch1DidChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:@([(UISwitch*)sender isOn]) forKey:FluxDebugMatchDebugImageOutputKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDebugDidChangeMatchDebugImageOutput
                                                        object:self userInfo:nil];
}

- (IBAction)switch2DidChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:@([(UISwitch*)sender isOn]) forKey:FluxDebugPedometerCountDisplayKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDebugDidChangePedometerCountDisplay
                                                        object:self userInfo:nil];
}

- (IBAction)switch3DidChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:@([(UISwitch*)sender isOn]) forKey:FluxDebugHistoricalPhotoPickerKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDebugDidChangeHistoricalPhotoPicker
                                                        object:self userInfo:nil];
}

- (IBAction)deleteAccountButtonAction:(id)sender {
    [UIActionSheet showInView:self.view
                    withTitle:@"Are you sure? This action cannot be undone."
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:@"Delete Account"
            otherButtonTitles:nil
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
                             NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
                             
                             AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://54.221.222.71/"]];
                             NSMutableURLRequest *request = [httpClient requestWithMethod:@"DELETE"
                                                                                     path:[NSString stringWithFormat:@"%@users/%@.json?auth_token=%@",httpClient.baseURL,userID, token]
                                                                               parameters:nil];
                             AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                             [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
                             [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                                 // No success for DELETE
                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                 if ([operation.response statusCode] == 401) {
                                     //done.
                                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Good News!", nil) message:@"This account was successfully deleted." delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
                                     [alert show];
                                 }
                                 else{
                                     //things done broke :(
                                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Things done broke :(", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
                                     [alert show];
                                 }
                             }];
                             [operation start];
                         }
                     }];
}

- (IBAction)hideMenuAction:(id)sender {
    [(FluxScanViewController*)self.parentViewController hideDebugMenu];
}
@end
