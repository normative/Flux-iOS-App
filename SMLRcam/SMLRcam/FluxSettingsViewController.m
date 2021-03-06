//
//  FluxLeftDrawerSettingsViewController.m
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxSettingsViewController.h"
#import "FluxRegisterViewController.h"
#import "FluxScanViewController.h"
#import "UICKeyChainStore.h"
#import <FacebookSDK/FacebookSDK.h>
#import "ProgressHUD.h"
#import "UIActionSheet+Blocks.h"

#define ERROR_TITLE_MSG @"Uh oh..."
#define ERROR_NO_ACCOUNTS @"You must add a Twitter account in the Settings app to sign in with Twitter"
#define ERROR_PERM_ACCESS @"We weren't granted access your twitter accounts"
#define ERROR_OK @"OK"


#define SHOW_APPSTORE_FEEDBACK NO


@interface FluxSettingsViewController ()

@end

@implementation FluxSettingsViewController

typedef enum
FluxSettingsSection: NSUInteger {
    socialAccounts_section,
    walkthroughReset_section,
    logout_section,
    sections_count,
} FluxSettingsSection;

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

    
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    
    [versionLabel setText:[NSString stringWithFormat:@"Version %@",version]];
    [versionLabel setFont:[UIFont fontWithName:@"Akkurat" size:versionLabel.font.pointSize]];
    [torontoLabel setFont:[UIFont fontWithName:@"Akkurat" size:torontoLabel.font.pointSize]];
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
    return sections_count;
}

//- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    switch (section) {
//        case socialAccounts_section:
//            return @"Social Accounts";
//            break;
//        case walkthroughReset_section:
//            return @"Other";
//            break;
//            //should never happen
//        default:
//            return @"";
//            break;
//    }
//}
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30.0;
}
//
//- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    // Create header view and add label as a subview
//    float height = [self tableView:tableView heightForHeaderInSection:section];
//    UIView*view;
//    if (height>0) {
//        view = [[UIView alloc] initWithFrame:CGRectMake(0,0, tableView.frame.size.width, height)];
//        [view setBackgroundColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:0.9]];
//        
//        // Create label with section title
//        UILabel *label = [[UILabel alloc] init];
//        label.frame = CGRectMake(10, 10, 150, height);
//        label.textColor = [UIColor whiteColor];
//        [label setFont:[UIFont fontWithName:@"Akkurat" size:15]];
//        label.text = [self tableView:tableView titleForHeaderInSection:section];
//        label.backgroundColor = [UIColor clearColor];
//        [label setCenter:CGPointMake(label.center.x, view.center.y)];
//        [view addSubview:label];
//    }
//    else
//    {
//        view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
//    }
//    return view;
//}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if (section == 0) {
//        return 0;
//    }
//    else
    switch (section) {
        case socialAccounts_section:
            return 2;
            break;
        case walkthroughReset_section:
            return 2;
            break;
        case logout_section:
            return (SHOW_APPSTORE_FEEDBACK ? 3: 2);
            break;
            //should never happen
        default:
            return 1;
            break;
    }
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
    switch (indexPath.section) {
        case socialAccounts_section:
        {
            static NSString *socialCellIdentifier;
            FluxSocialManagementCell * socialMgmtcell;
            switch (indexPath.row)
            {
                case 0:
                {
                    if (![UICKeyChainStore stringForKey:FluxNameKey service:FacebookService]) {
                        socialCellIdentifier = @"socialManagementCellConnect";
                        socialMgmtcell = [self socialMgmtCellForTableView:tableView withIdentifier:socialCellIdentifier];
                        [socialMgmtcell.socialPartnerLabel setText:@"Facebook"];
                        [socialMgmtcell.socialIconImageView setImage:[self imageDesaturated:[UIImage imageNamed:@"import_facebook"]]];
                    }
                    else{
                        socialCellIdentifier = @"socialManagementCellClear";
                        socialMgmtcell = [self socialMgmtCellForTableView:tableView withIdentifier:socialCellIdentifier];
                        [socialMgmtcell setIsActivated:YES];
                        [socialMgmtcell.socialPartnerLabel setText:@"Facebook"];
                        [socialMgmtcell.socialIconImageView setImage:[UIImage imageNamed:@"import_facebook"]];
                        [socialMgmtcell.socialDescriptionLabel setText:[UICKeyChainStore stringForKey:FluxNameKey service:FacebookService]];
                        
                        //if the user registered with this service, un-linking doesn't make sense.
                        if ([UICKeyChainStore stringForKey:FluxDidRegisterKey service:FacebookService]) {
                            [socialMgmtcell.cellButton setHidden:YES];
                        }
                    }
                }
                    break;
                case 1:
                {
                    if (![UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService]) {
                        socialCellIdentifier = @"socialManagementCellConnect";
                        socialMgmtcell = [self socialMgmtCellForTableView:tableView withIdentifier:socialCellIdentifier];
                        [socialMgmtcell.socialPartnerLabel setText:@"Twitter"];
                        [socialMgmtcell.socialIconImageView setImage:[self imageDesaturated:[UIImage imageNamed:@"import_twitter"]]];
                        [socialMgmtcell.socialDescriptionLabel setText:@""];
                        [socialMgmtcell setIsActivated:NO];
                    }
                    else{
                        socialCellIdentifier = @"socialManagementCellClear";
                        socialMgmtcell = [self socialMgmtCellForTableView:tableView withIdentifier:socialCellIdentifier];
                        [socialMgmtcell.socialPartnerLabel setText:@"Twitter"];
                        [socialMgmtcell setIsActivated:YES];
                        [socialMgmtcell.socialIconImageView setImage:[UIImage imageNamed:@"import_twitter"]];
                        [socialMgmtcell.socialDescriptionLabel setText:[UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService]];
                        
                        //if the user registered with this service, un-linking doesn't make sense.
                        if ([UICKeyChainStore stringForKey:FluxDidRegisterKey service:TwitterService]) {
                            [socialMgmtcell.cellButton setHidden:YES];
                        }
                    }
                }
                    break;
                default:
                    break;
            }
            
            return socialMgmtcell;
        }
        break;
        case walkthroughReset_section:
        {
            static NSString *simpleTableIdentifier = @"simpleCell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
            }
            [cell setBackgroundColor:[UIColor clearColor]];
            if (indexPath.row == 0) {
                [cell.textLabel setText:@"Show Opening Tutorial"];
            }
            else{
                [cell.textLabel setText:@"Share Some Hugs"];
            }
            
            [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:16.0]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
            [cell setSelectedBackgroundView:bgColorView];
            return cell;
        }
            break;
        case logout_section:
        {
            static NSString *simpleTableIdentifier = @"simpleCell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
            
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
            }
            [cell setBackgroundColor:[UIColor clearColor]];
            if (SHOW_APPSTORE_FEEDBACK) {
                switch (indexPath.row) {
                    case 0:
                        [cell.textLabel setText:@"Feedback"];
                        break;
                    case 1:
                        [cell.textLabel setText:@"Privacy Policy"];
                        break;
                    case 2:
                        [cell.textLabel setText:@"Logout"];
                        break;
                        
                    default:
                        break;
                }
            }
            else{
                [cell.textLabel setText: (indexPath.row == 0 ? @"Privacy Policy" : @"Logout")];
            }
            [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:16.0]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
            [cell setSelectedBackgroundView:bgColorView];
            return cell;
        }
            break;
        default:
            //shouldn't happen
            return nil;
            break;
    }
}


- (FluxSocialManagementCell*)socialMgmtCellForTableView :(UITableView*)tableView withIdentifier:(NSString*)identifier{
    FluxSocialManagementCell * socialMgmtcell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!socialMgmtcell) {
        socialMgmtcell = [[FluxSocialManagementCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    [socialMgmtcell initCell];
    [socialMgmtcell setDelegate:self];
    [socialMgmtcell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return socialMgmtcell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case socialAccounts_section:
        {
            return;
        }
            break;
        case walkthroughReset_section:
        {
            if (indexPath.row == 0) {
                [self resetWalkthrough];
            }
            else{
                [self fireAppReview];
            }
        }
            break;
        case logout_section:
        {
            if (SHOW_APPSTORE_FEEDBACK) {
                if (indexPath.row == 0){
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Feedback", nil) message:@"Send some app feedback" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
                    [alert show];
                }
                else if(indexPath.row == 1){
                    [self performSegueWithIdentifier:@"privacyPolicySegue" sender:nil];
                }
                else{
                    [self logoutButtonAction:nil];
                }
            }
            else{
                if (indexPath.row == 0){
                    [self performSegueWithIdentifier:@"privacyPolicySegue" sender:nil];
                }
                else{
                    [self logoutButtonAction:nil];
                }
            }
        }
            break;
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    [self SocialManagementCellButtonWasTapped:(FluxSocialManagementCell*)[tableView cellForRowAtIndexPath:indexPath]];
}

- (void)SocialManagementCellButtonWasTapped:(FluxSocialManagementCell *)socialManagementCell{
    if ([socialManagementCell.socialPartnerLabel.text isEqualToString:@"Facebook"]) {
        if (socialManagementCell.isActivated) {
                [UIActionSheet showInView:self.view
                                withTitle:@"Facebook"
                        cancelButtonTitle:@"Cancel"
                   destructiveButtonTitle:@"Disconnect"
                        otherButtonTitles:nil
                                 tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                     if (buttonIndex != actionSheet.cancelButtonIndex) {
                                         //unlink facebook
                                         [UICKeyChainStore removeAllItemsForService:FacebookService];
                                         //close facebook session
                                         if (FBSession.activeSession.isOpen) {
                                             [FBSession.activeSession closeAndClearTokenInformation];
                                         }
                                         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                                     }
                                 }];
        }
        else{
            [self linkFacebook];
        }
    }
    else{
        if (socialManagementCell.isActivated) {
                [UIActionSheet showInView:self.view
                                withTitle:@"Twitter"
                        cancelButtonTitle:@"Cancel"
                   destructiveButtonTitle:@"Disconnect"
                        otherButtonTitles:nil
                                 tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                     if (buttonIndex != actionSheet.cancelButtonIndex) {
                                         //unlick twitter
                                         [UICKeyChainStore removeAllItemsForService:TwitterService];
                                         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                                     }
                                 }];
        }
        else{
            [self linkTwitterAccount];
        }
    }
}


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

- (void)SocialManager:(FluxSocialManager *)socialManager didFailToLinkSocialAccount:(NSString *)accountType withMessage:(NSString *)message{
    if (message) {
        [ProgressHUD showError:message];
    }
    else{
        [ProgressHUD showError:[NSString stringWithFormat:@"Failed to link %@",accountType]];
    }
}


#pragma mark - Cell Actions

- (void)logout{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //if the action sheet was delayed, do nothing (**should** never happen)
    if (window.rootViewController) {
        
 
        
        [(FluxRegisterViewController*)[[(UINavigationController*)window.rootViewController viewControllers]objectAtIndex:0]userDidLogOut];
        


        [self.parentViewController.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

- (void)resetWalkthrough{
    [UIActionSheet showInView:self.view
                    withTitle:@"Are you sure you want to see the walkthrough again?"
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:nil
            otherButtonTitles:@[@"Yep"]
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             //oush to scan and show walkthrough
                             NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                             [defaults removeObjectForKey:@"showedTutorial"];
                             [(FluxScanViewController*)self.parentViewController.presentingViewController showTutorial];
                             [self.parentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                 
                             }];
                         }
                     }];
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

- (void)fireAppReview{
    NSString * appId = @"792748447";
    NSString * theUrl = [NSString  stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@",appId];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:theUrl]];
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

@end
