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
#import "UIAlertView+Blocks.h"

NSString* const FluxDebugDidChangeMatchDebugImageOutput = @"FluxDebugDidChangeMatchDebugImageOutput";
NSString* const FluxDebugMatchDebugImageOutputKey = @"FluxDebugMatchDebugImageOutputKey";
NSString* const FluxDebugDidChangeTeleportLocationIndex = @"FluxDebugDidChangeTeleportLocationIndex";
NSString* const FluxDebugTeleportLocationIndexKey = @"FluxDebugTeleportLocationIndexKey";
NSString* const FluxDebugDidChangePedometerCountDisplay = @"FluxDebugDidChangePedometerCountDisplay";
NSString* const FluxDebugPedometerCountDisplayKey = @"FluxDebugPedometerCountDisplayKey";
NSString* const FluxDebugDidChangeHistoricalPhotoPicker = @"FluxDebugDidChangeHistoricalPhotoPicker";
NSString* const FluxDebugHistoricalPhotoPickerKey = @"FluxDebugHistoricalPhotoPickerKey";
NSString* const FluxDebugDidChangeHeadingCorrectedMotion = @"FluxDebugDidChangeHeadingCorrectedMotion";
NSString* const FluxDebugHeadingCorrectedMotionKey = @"FluxDebugHeadingCorrectedMotionKey";
NSString* const FluxDebugDidChangeDetailLoggerEnabled = @"FluxDebugDidChangeDetailLoggerEnabled";
NSString* const FluxDebugDetailLoggerEnabledKey = @"FluxDebugDetailLoggerEnabledKey";

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
    [segmentedControl3 setSelectedSegmentIndex:[(NSString*)[defaults objectForKey:FluxDebugHistoricalPhotoPickerKey] intValue] - 1];
    
    [switch1 setOn:[[defaults objectForKey:FluxDebugMatchDebugImageOutputKey] boolValue]];
    [switch2 setOn:[[defaults objectForKey:FluxDebugPedometerCountDisplayKey] boolValue]];
    [switch4 setOn:[[defaults objectForKey:FluxDebugHeadingCorrectedMotionKey] boolValue]];
    
    bool detailedLoggerEnabled = [[defaults objectForKey:FluxDebugDetailLoggerEnabledKey] boolValue];
    if (detailedLoggerEnabled)
    {
        [detailLoggerButtonLabel setTitle:@"Email Log" forState:UIControlStateNormal];
    }
    
    // Add long-press gesture recognizer to disable logging (add it whether or not enabled - doesn't hurt to call it if already disabled)
    UILongPressGestureRecognizer *longPress_gr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(disableDetailLoggerButton:)];
    [longPress_gr setMinimumPressDuration:2]; // triggers the action after 2 seconds of press
    [detailLoggerButtonLabel addGestureRecognizer:longPress_gr];
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)slider1DidSlide:(id)sender {
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

- (IBAction)segmentedControl3DidChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:@([(UISegmentedControl*)sender selectedSegmentIndex]+1) forKey:FluxDebugHistoricalPhotoPickerKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDebugDidChangeHistoricalPhotoPicker
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
    
}

- (IBAction)switch4DidChange:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:@([(UISwitch*)sender isOn]) forKey:FluxDebugHeadingCorrectedMotionKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxDebugDidChangeHeadingCorrectedMotion
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
                             
                             AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:FluxSecureServerURL]];
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

- (IBAction)detailLoggerButtonAction:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([[defaults objectForKey:FluxDebugDetailLoggerEnabledKey] boolValue])
    {
        // Logging enabled already. Send email.
        
        // Prompt user to notify them that location will be tracked and request permission
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"May We?"
                                                            message:@"Device logs, including information which details the exact location of the device, will be uploaded for analysis."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Sure", nil];
        
        [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex)
            {
                if ([MFMailComposeViewController canSendMail])
                {
                    FluxLoggerService *fluxLoggerService = [FluxLoggerService sharedLoggerService];
                    
                    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
                    mailViewController.mailComposeDelegate = self;
                    NSMutableData *errorLogData = [NSMutableData data];
                    for (NSData *errorLogFileData in [fluxLoggerService errorLogData])
                    {
                        [errorLogData appendData:errorLogFileData];
                    }
                    [mailViewController addAttachmentData:errorLogData mimeType:@"text/plain" fileName:@"errorLog.txt"];
                    [mailViewController setSubject:NSLocalizedString(@"Flux Detailed Log File", @"")];
                    [mailViewController setToRecipients:[NSArray arrayWithObject:@"support@smlr.is"]];
                    
                    [self presentViewController:mailViewController animated:YES completion:nil];
                }
                else
                {
                    NSString *message = NSLocalizedString(@"Sorry, your issue can't be reported right now. This is most likely because no mail accounts are set up on your mobile device.", @"");
                    [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil] show];
                }
            }
        }];
    }
    else
    {
        // Logging not yet enabled. Start it and update UI for email.
        
        // Prompt user to notify them that location will be tracked and request permission
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"May We?"
                                                            message:@"In order to enable detailed device logging, we need to store your detailed location on the device. This information will only be sent to us on your request. To disable in the future, tap and hold this button."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Sure", nil];
        
        [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex)
            {
                [detailLoggerButtonLabel setTitle:@"Email Log" forState:UIControlStateNormal];
                
                [defaults setObject:@(YES) forKey:FluxDebugDetailLoggerEnabledKey];
                [defaults synchronize];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:FluxDebugDidChangeDetailLoggerEnabled
                                                                    object:self userInfo:nil];
            }
        }];
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)disableDetailLoggerButton:(UILongPressGestureRecognizer *)recognizer
{
    // Long press of button. Disable logging.
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [detailLoggerButtonLabel setTitle:@"Detail Log" forState:UIControlStateNormal];
        
        [defaults setObject:@(NO) forKey:FluxDebugDetailLoggerEnabledKey];
        [defaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxDebugDidChangeDetailLoggerEnabled
                                                            object:self userInfo:nil];
    }
}

- (IBAction)hideMenuAction:(id)sender {
    [(FluxScanViewController*)self.parentViewController hideDebugMenu];
}
@end
