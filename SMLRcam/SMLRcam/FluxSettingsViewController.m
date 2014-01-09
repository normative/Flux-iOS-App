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
//    [super viewWillAppear:animated];
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
//    label.backgroundColor = [UIColor clearColor];
//    [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:17.0]];
//    label.textAlignment = UITextAlignmentCenter;
//    label.textColor = [UIColor whiteColor];
//    label.adjustsFontSizeToFitWidth = YES;
//    label.text = self.title;
//    self.navigationItem.titleView = label;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"Settings"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    initialMask = [[defaults objectForKey:@"Mask"] integerValue];
    
    [self.logoutButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.logoutButton.titleLabel.font.pointSize]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewDidDisappear:(BOOL)animated{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int tmp = [[defaults objectForKey:@"Mask"] integerValue];

    if (tmp!= initialMask) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"maskChange"
                                                            object:self userInfo:nil];
    }

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
    return 2;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"General";
    }
    else
        return @"Social Management";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 0;
    }
    else
        return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    

    
    if (indexPath.section == 0) {
        static NSString *cellIdentifier = @"cell";
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
        [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.textLabel.font.pointSize]];
    }
    
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
            [socialMgmtcell.socialIconImageView setImage:[UIImage imageNamed:@"facebookLogo"]];
            break;
        case 1:
            [socialMgmtcell.socialPartnerLabel setText:@"Twitter"];
            [socialMgmtcell.socialIconImageView setImage:[self imageDesaturated:[UIImage imageNamed:@"twitterLogo"]]];
            break;
        default:
            break;
            
    }
    return socialMgmtcell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
            //facebook row tapped
            break;
        case 1:
            //twitter row tapped
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
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self.logoutButton setEnabled:NO];
        //delay until the action sheet is removed from the stack
        [self performSelector:@selector(logout) withObject:Nil afterDelay:0.5];
    }
}

- (void)logout{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //if the action sheet was delayed, do nothing (**should** never happen)
    if (window.rootViewController) {
        [UICKeyChainStore removeAllItemsForService:FluxService];
        [UICKeyChainStore removeAllItemsForService:FacebookService];
        [UICKeyChainStore removeAllItemsForService:TwitterService];
        
        if (FBSession.activeSession.isOpen) {
            [FBSession.activeSession closeAndClearTokenInformation];
        }
        
        [(FluxRegisterViewController*)[[(UINavigationController*)window.rootViewController viewControllers]objectAtIndex:0]userDidLogOut];
        
        [self.parentViewController.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

#pragma mark - Logout

- (IBAction)logoutButtonAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Are you sure you'd like to logout?"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Logout"
                                  otherButtonTitles:nil];
    [actionSheet showInView:self.view];
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
