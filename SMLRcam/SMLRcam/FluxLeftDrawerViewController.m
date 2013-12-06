//
//  FluxLeftDrawerViewController.m
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxLeftDrawerViewController.h"
#import "TestFlight.h"
#import "TestFlight+OpenFeedback.h"
#import "FluxCountTableViewCell.h"
#import "FluxProfileCell.h"
#import "UICKeyChainStore.h"

#import "FluxSettingsViewController.h"
#import "FluxProfilePhotosViewController.h"

@interface FluxLeftDrawerViewController ()

@end

@implementation FluxLeftDrawerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableDictionary*tmp1 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Photos" , nil];
    NSMutableDictionary*tmp2 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Following" , nil];
    NSMutableDictionary*tmp3 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Followers" , nil];
    NSMutableDictionary*tmp4 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Friends" , nil];
    NSMutableDictionary*tmp5 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Settings" , nil];
    tableViewArray = [[NSMutableArray alloc]initWithObjects:tmp1, tmp2, tmp3, tmp4, tmp5, nil];
    
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    [self.versionLbl setText:[NSString stringWithFormat:@"Flux v.%@ (%@)",version,build]];
    [self.versionLbl setFont:[UIFont fontWithName:@"Akkurat" size:self.versionLbl.font.pointSize]];
    [self.feedbackButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.feedbackButton.titleLabel.font.pointSize]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableViewArray.count+1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row>0) {
        return 44.0;
    }
    return 120.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"standardLeftCell";
    FluxCountTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxCountTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell initCell];
    if (indexPath.row == 0) {
        NSString *username = [UICKeyChainStore stringForKey:@"username" service:@"com.flux"];
        
        NSString *cellIdentifier = @"profileCell";
        FluxProfileCell * profileCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!profileCell) {
            profileCell = [[FluxProfileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        [profileCell.bioLabel setText:@"CmdrTaco basically runs the internet. This is a short bio about how awesome he is."];
        [profileCell.usernameLabel setText:@"CmdrTaco"];
        [profileCell.profileImageView setImage:[UIImage imageNamed:@"profileImage"]];
        [profileCell initCell];
        [profileCell hideCamStats];
        return profileCell;
    }
    else if (indexPath.row == tableViewArray.count){
        cell.titleLabel.text = (NSString*)[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject];
        cell.countLabel.text = @"";
    }
    else if(indexPath.row == 2 || indexPath.row == 3 || indexPath.row == 4){
        cell.titleLabel.text = (NSString*)[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject];
        cell.countLabel.text = [NSString stringWithFormat:@"%i",[(NSNumber*)[[tableViewArray objectAtIndex:indexPath.row-1]objectForKey:[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject]]intValue]];
        [cell.titleLabel setEnabled:NO];
        [cell.countLabel setEnabled:NO];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    else{
        cell.titleLabel.text = (NSString*)[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject];
        cell.countLabel.text = [NSString stringWithFormat:@"%i",[(NSNumber*)[[tableViewArray objectAtIndex:indexPath.row-1]objectForKey:[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject]]intValue]];
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0:
            //[self performSegueWithIdentifier:@"pushPhotosSegue" sender:nil];
            break;
        case 1:
            [self performSegueWithIdentifier:@"pushPhotosSegue" sender:nil];
            break;
        case 2:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
            break;
        case 3:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
            break;
        case 4:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
            break;
        case 5:
            [self performSegueWithIdentifier:@"pushSettingsSegue" sender:nil];
            break;
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma IBActions

- (IBAction)onSendFeedBackBtn:(id)sender
{
    [TestFlight openFeedbackViewFromView:self];
}

- (IBAction)doneButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pushSettingsSegue"])
    {
        FluxSettingsViewController* leftDrawerSettingsViewController = (FluxSettingsViewController*)segue.destinationViewController;
        leftDrawerSettingsViewController.fluxDataManager = self.fluxDataManager;
    }
    if ([[segue identifier] isEqualToString:@"pushPhotosSegue"]){
        [(FluxProfilePhotosViewController*)segue.destinationViewController setFluxDataManager:self.fluxDataManager];
        [(FluxProfilePhotosViewController*)segue.destinationViewController prepareViewWithImagesUserID:[UICKeyChainStore stringForKey:@"userID" service:@"com.flux"].intValue];
    }
}

@end
