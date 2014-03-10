//
//  FluxLeftDrawerSettingsViewController.m
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxSettingsViewController.h"
#import "FluxRegisterViewController.h"
#import "FluxSocialManagementCell.h"
#import "UICKeyChainStore.h"
#import <FacebookSDK/FacebookSDK.h>
#import "ProgressHUD.h"
#import "UIActionSheet+Blocks.h"

#define ERROR_TITLE_MSG @"Uh oh..."
#define ERROR_NO_ACCOUNTS @"You must add a Twitter account in the Settings app to sign in with Twitter"
#define ERROR_PERM_ACCESS @"We weren't granted access your twitter accounts"
#define ERROR_OK @"OK"



@interface FluxSettingsViewController ()

@end

@implementation FluxSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
//    label.backgroundColor = [UIColor clearColor];
//    [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:17.0]];
//    label.textAlignment = UITextAlignmentCenter;
//    label.textColor = [UIColor whiteColor];
//    label.adjustsFontSizeToFitWidth = YES;
//    label.text = self.title;
//    self.navigationItem.titleView = label;
    [self setTitle:@""];
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self setTitle:@"Settings"];
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:0.0 forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"Settings"];
    
    UILabel*label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 140, 18)];
    [label setText:@"Settings"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:17.0]];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(self.navigationController.navigationBar.center.x, self.navigationController.navigationBar.center.y)];
    [self.navigationItem setTitleView:label];
    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    initialMask = [[defaults objectForKey:@"Mask"] integerValue];
    
    [self.logoutButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.logoutButton.titleLabel.font.pointSize]];
    UILabel*logoutLabel = [[UILabel alloc]initWithFrame:self.logoutButton.bounds];
    [logoutLabel setTextAlignment:NSTextAlignmentCenter];
    [logoutLabel setFont:self.logoutButton.titleLabel.font];
    [logoutLabel setText:self.logoutButton.titleLabel.text];
    [logoutLabel setTextColor:self.logoutButton.titleLabel.textColor];
    [self.logoutButton setTitle:@"" forState:UIControlStateNormal];
    [self.logoutButton setShowsTouchWhenHighlighted:YES];
    [self.logoutButton addSubview:logoutLabel];
    
    self.accountStore = [[ACAccountStore alloc] init];
    self.apiManager = [[TWAPIManager alloc] init];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIView*view = fakeSeparator.superview;
    [fakeSeparator removeFromSuperview];
    [fakeSeparator setTranslatesAutoresizingMaskIntoConstraints:YES];
    [view addSubview:fakeSeparator];
    //fixes what looks to be an Xcode bug where if you put a frame height as less than 1 it makes it 1 (2 pixels)
    [fakeSeparator setFrame:CGRectMake(fakeSeparator.frame.origin.x, fakeSeparator.frame.origin.y, fakeSeparator.frame.size.width, 1/[[UIScreen mainScreen] scale])];
}

-(void)viewDidDisappear:(BOOL)animated{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    int tmp = [[defaults objectForKey:@"Mask"] integerValue];
//
//    if (tmp!= initialMask) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"maskChange"
//                                                            object:self userInfo:nil];
//    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    if (section == 0) {
//        return @"General";
//    }
//    else
        return @"Linked Accounts";
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView*view = [[UIView alloc] initWithFrame:CGRectMake(0,0, tableView.frame.size.width, 30.0)];
    [view setBackgroundColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:0.9]];
    
    // Create label with section title
    UILabel*label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 0, 150, 30.0);
    label.textColor = [UIColor whiteColor];
    [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:15.0]];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.backgroundColor = [UIColor clearColor];
    //[label setCenter:CGPointMake(label.center.x, view.center.y)];
    [view addSubview:label];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if (section == 0) {
//        return 0;
//    }
//    else
        return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
//    if (indexPath.section == 0) {
//        static NSString *cellIdentifier = @"cell";
//        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
//        if (!cell) {
//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
//        }
//        
//        [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.textLabel.font.pointSize]];
//    }
    
    static NSString *socialCellIdentifier = @"socialManagementCell";
    FluxSocialManagementCell * socialMgmtcell = [tableView dequeueReusableCellWithIdentifier:socialCellIdentifier];
    if (!socialMgmtcell) {
        socialMgmtcell = [[FluxSocialManagementCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:socialCellIdentifier];
    }
    [socialMgmtcell.socialPartnerLabel setFont:[UIFont fontWithName:@"Akkurat" size:socialMgmtcell.socialPartnerLabel.font.pointSize]];
    [socialMgmtcell.socialDescriptionLabel setFont:[UIFont fontWithName:@"Akkurat" size:socialMgmtcell.socialDescriptionLabel.font.pointSize]];
    
    switch (indexPath.row)
    {
        case 0:
            [socialMgmtcell.socialPartnerLabel setText:@"Facebook"];
            
            if (![UICKeyChainStore stringForKey:FluxNameKey service:FacebookService]) {
                [socialMgmtcell.socialIconImageView setImage:[self imageDesaturated:[UIImage imageNamed:@"import_facebook"]]];
                [socialMgmtcell.socialDescriptionLabel setText:@""];
                [socialMgmtcell setIsActivated:NO];
            }
            else{
                [socialMgmtcell setIsActivated:YES];
                [socialMgmtcell.socialIconImageView setImage:[UIImage imageNamed:@"import_facebook"]];
                [socialMgmtcell.socialDescriptionLabel setText:[UICKeyChainStore stringForKey:FluxNameKey service:FacebookService]];
                [socialMgmtcell setUserInteractionEnabled:NO];
                [socialMgmtcell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            
            break;
        case 1:
            [socialMgmtcell.socialPartnerLabel setText:@"Twitter"];
            
            if (![UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService]) {
                [socialMgmtcell.socialIconImageView setImage:[self imageDesaturated:[UIImage imageNamed:@"import_twitter"]]];
                [socialMgmtcell.socialDescriptionLabel setText:@""];
                [socialMgmtcell setIsActivated:NO];
            }
            else{
                [socialMgmtcell setIsActivated:YES];
                [socialMgmtcell.socialIconImageView setImage:[UIImage imageNamed:@"import_twitter"]];
                [socialMgmtcell.socialDescriptionLabel setText:[UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService]];
                [socialMgmtcell setUserInteractionEnabled:NO];
                [socialMgmtcell setSelectionStyle:UITableViewCellSelectionStyleNone];
                socialMgmtcell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            break;
        default:
            break;
            
    }
    return socialMgmtcell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            if ([(FluxSocialManagementCell*)[tableView cellForRowAtIndexPath:indexPath] isActivated]) {
                
//                [UIActionSheet showInView:self.view
//                                withTitle:@"Facebook"
//                        cancelButtonTitle:@"Cancel"
//                   destructiveButtonTitle:@"Unlink"
//                        otherButtonTitles:nil
//                                 tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
//                                     if (buttonIndex != actionSheet.cancelButtonIndex) {
//                                         //unlink facebook
//                                         [UICKeyChainStore removeAllItemsForService:FacebookService];
//                                         //close facebook session
//                                         if (FBSession.activeSession.isOpen) {
//                                             [FBSession.activeSession closeAndClearTokenInformation];
//                                         }
//                                         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
//                                     }
//                                 }];
                
                
            }
            else{
                [UIActionSheet showInView:self.view
                                withTitle:@"Facebook"
                        cancelButtonTitle:@"Cancel"
                   destructiveButtonTitle:nil
                        otherButtonTitles:@[@"Link"]
                                 tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                     if (buttonIndex != actionSheet.cancelButtonIndex) {
                                         //link facebook
                                         [self linkFacebook];
                                     }
                                 }];
            }
            break;
        case 1:
            if ([(FluxSocialManagementCell*)[tableView cellForRowAtIndexPath:indexPath] isActivated]) {
                
//                [UIActionSheet showInView:self.view
//                                withTitle:@"Twitter"
//                        cancelButtonTitle:@"Cancel"
//                   destructiveButtonTitle:@"Unlink"
//                        otherButtonTitles:nil
//                                 tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
//                                     if (buttonIndex != actionSheet.cancelButtonIndex) {
//                                         //unlick twitter
//                                         [UICKeyChainStore removeAllItemsForService:TwitterService];
//                                         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
//                                     }
//                                 }];
                
            }
            else{
                [UIActionSheet showInView:self.view
                                withTitle:@"Twitter"
                        cancelButtonTitle:@"Cancel"
                   destructiveButtonTitle:nil
                        otherButtonTitles:@[@"Link"]
                                 tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                     if (buttonIndex != actionSheet.cancelButtonIndex) {
                                         //link twitter
                                         [self linkTwitterAccount];
                                     }
                                 }];
            }
            break;
            
        default:
            break;
    }
}


//- (IBAction)changeSaveLocallySwitch:(id)sender
//{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:[NSNumber numberWithBool:self.saveLocallySwitch.on]
//                 forKey:@"Save Pictures"];
//    [defaults synchronize];
//}
//
//- (IBAction)changeConnectServerSegment:(id)sender
//{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:[NSNumber numberWithInt:self.connectServerSegmentedControl.selectedSegmentIndex] forKey:@"Server Location"];
//    [defaults synchronize];
//}
//
//- (IBAction)maskSliderChanged:(id)sender {
//    int discreteValue = roundl([self.maskSlider value]);
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:[NSNumber numberWithInt:discreteValue] forKey:@"Mask"];
//    [defaults synchronize];
//    [self.maskLabel setText:[NSString stringWithFormat:@"%i",discreteValue]];
//    [self.maskSlider setValue:(float)discreteValue];
//}

#pragma mark Twitter
- (void)linkTwitterAccount{
    FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
    [socialManager setDelegate:self];
    [socialManager linkTwitter];
}

#pragma mark Facebook

- (void)linkFacebook{
    FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
    [socialManager setDelegate:self];
    [socialManager linkFacebook];
}

#pragma mark - Social Manager Delegate


-(void)SocialManager:(FluxSocialManager *)socialManager didLinkTwitterAccountWithUsername:(NSString *)username{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)SocialManager:(FluxSocialManager *)socialManager didLinkFacebookAccountWithName:(NSString *)name{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)SocialManager:(FluxSocialManager *)socialManager didFailToLinkSocialAccount:(NSString *)accountType{
    [ProgressHUD showError:[NSString stringWithFormat:@"Failed to link %@ account",accountType]];
}


#pragma mark - Logout

- (void)logout{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //if the action sheet was delayed, do nothing (**should** never happen)
    if (window.rootViewController) {
        
 
        
        [(FluxRegisterViewController*)[[(UINavigationController*)window.rootViewController viewControllers]objectAtIndex:0]userDidLogOut];
        


        [self.parentViewController.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (IBAction)logoutButtonAction:(id)sender {
    [UIActionSheet showInView:self.view
                    withTitle:@"Are you sure you'd like to logout?"
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:@"Logout"
            otherButtonTitles:nil
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             [self.logoutButton setEnabled:NO];
                             //delay until the action sheet is removed from the stack
                             [self performSelector:@selector(logout) withObject:Nil afterDelay:0.5];
                         }
                     }];
}

- (IBAction)onAreaResetBtn:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"WARNING" message:@"This will permanentally delete all images for this location."  delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles: @"Make It Happen", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1)
    {
        [self.fluxDataManager deleteLocations];
    }
}

#pragma mark - Helper Methods

-(UIImage*) imageDesaturated:(UIImage*) image {
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *ciimage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:ciimage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:0.0f] forKey:@"inputSaturation"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    return [UIImage imageWithCGImage:cgImage];
}

@end
