//
//  FluxLeftDrawerSettingsViewController.m
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxSettingsViewController.h"
#import "FluxRegisterViewController.h"
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (indexPath.row)
    {
        case 0:
            self.saveLocallySwitch.on = [[defaults objectForKey:@"Save Pictures"] boolValue];
            break;
        case 1:
            break;
        case 2:
            break;
        case 3:
            self.connectServerSegmentedControl.selectedSegmentIndex = [[defaults objectForKey:@"Server Location"] intValue];
            break;
        default:
            break;
            
    }
    return cell;
}


- (IBAction)changeSaveLocallySwitch:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:self.saveLocallySwitch.on]
                 forKey:@"Save Pictures"];
    [defaults synchronize];
}

- (IBAction)changeConnectServerSegment:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:self.connectServerSegmentedControl.selectedSegmentIndex] forKey:@"Server Location"];
    [defaults synchronize];
}

- (IBAction)maskSliderChanged:(id)sender {
    int discreteValue = roundl([self.maskSlider value]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:discreteValue] forKey:@"Mask"];
    [defaults synchronize];
    [self.maskLabel setText:[NSString stringWithFormat:@"%i",discreteValue]];
    [self.maskSlider setValue:(float)discreteValue];
}

- (IBAction)logoutButtonAction:(id)sender {
    [UICKeyChainStore removeAllItemsForService:FluxService];
    [UICKeyChainStore removeAllItemsForService:FacebookService];
    [UICKeyChainStore removeAllItemsForService:TwitterService];
    
    if (FBSession.activeSession.isOpen) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [(FluxRegisterViewController*)[[(UINavigationController*)window.rootViewController viewControllers]objectAtIndex:0]userDidLogOut];
    [self.parentViewController.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
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

@end
