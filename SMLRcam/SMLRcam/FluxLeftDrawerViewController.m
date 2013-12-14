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
#import "ProgressHUD.h"

#import "FluxSettingsViewController.h"
#import "FluxProfilePhotosViewController.h"

@interface FluxLeftDrawerViewController ()

@end

@implementation FluxLeftDrawerViewController

#pragma mark - View Init


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
    tableViewArray = [self tableViewArrayForUser:nil];
    
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    [self.versionLbl setText:[NSString stringWithFormat:@"Flux v.%@ (%@)",version,build]];
    [self.versionLbl setFont:[UIFont fontWithName:@"Akkurat" size:self.versionLbl.font.pointSize]];
    [self.feedbackButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.feedbackButton.titleLabel.font.pointSize]];
    
    NSString *userID = [UICKeyChainStore stringForKey:@"userID" service:@"com.flux"];
    //**should** always pass
    if (userID) {
        FluxDataRequest*request = [[FluxDataRequest alloc]init];
        [request setUserReady:^(FluxUserObject*userObject, FluxDataRequest*completedRequest){
            tableViewArray = [self tableViewArrayForUser:userObject];
            [self.tableView reloadData];
            if (userObject.hasProfilePic) {
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
                if (![defaults objectForKey:@"profilePic"]) {
                    FluxDataRequest*picRequest = [[FluxDataRequest alloc]init];
                    [picRequest setUserPicReady:^(UIImage*img, int userID, FluxDataRequest*completedRequest){
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:img forKey:@"profilePic"];
                        [defaults synchronize];
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }];
                    [picRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
                        NSString*str = [NSString stringWithFormat:@"Profile picture failed with error %d", (int)[e code]];
                        [ProgressHUD showError:str];
                    }];
                    [self.fluxDataManager requestUserProfilePicForID:userID.integerValue andSize:@"" withDataRequest:picRequest];
                }
            }
        }];
        [request setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
            NSString*str = [NSString stringWithFormat:@"Profile load failed with error %d", (int)[e code]];
            [ProgressHUD showError:str];
        }];
        
        [self.fluxDataManager requestUserProfileForID:userID.integerValue withDataRequest:request];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tableView Init
- (NSMutableArray*)tableViewArrayForUser:(FluxUserObject*)user{
    NSMutableArray*newTableArray;
    if (user) {
        NSMutableDictionary*tmp1 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:user.imageCount], @"Photos" , nil];
        NSMutableDictionary*tmp2 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:user.followingCount], @"Following" , nil];
        NSMutableDictionary*tmp3 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:user.followerCount], @"Followers" , nil];
        NSMutableDictionary*tmp4 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:user.friendCount], @"Friends" , nil];
        NSMutableDictionary*tmp5 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Settings" , nil];
        newTableArray = [[NSMutableArray alloc]initWithObjects:tmp1, tmp2, tmp3, tmp4, tmp5, nil];
    }
    else{
        NSMutableDictionary*tmp1 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Photos" , nil];
        NSMutableDictionary*tmp2 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Following" , nil];
        NSMutableDictionary*tmp3 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Followers" , nil];
        NSMutableDictionary*tmp4 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Friends" , nil];
        NSMutableDictionary*tmp5 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Settings" , nil];
        newTableArray = [[NSMutableArray alloc]initWithObjects:tmp1, tmp2, tmp3, tmp4, tmp5, nil];
    }
    return newTableArray;
}

- (BOOL)userMatchesLocal:(FluxUserObject*)user{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    if (defaults objectForKey:<#(NSString *)#>) {
//        <#statements#>
//    }
    return NO;
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
        NSString *cellIdentifier = @"profileCell";
        FluxProfileCell * profileCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!profileCell) {
            profileCell = [[FluxProfileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        
        NSString *username = [UICKeyChainStore stringForKey:@"username" service:@"com.flux"];
        if (username) {
            [profileCell.usernameLabel setText:@"username"];
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"bio"]) {
            [profileCell.bioLabel setText:[defaults objectForKey:@"bio"]];
        }
        
        if ([defaults objectForKey:@"profilePic"]) {
            [profileCell.profileImageView setImage:[defaults objectForKey:@"profilePic"]];
        }
        else{
            [profileCell.profileImageView setImage:[UIImage imageNamed:@"emptyProfileImage"]];
        }
        profileCell.profileImageView.layer.cornerRadius = profileCell.profileImageView.frame.size.height/2;
        profileCell.profileImageView.clipsToBounds = YES;
        
        
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

#pragma mark - IBActions

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
        [(FluxProfilePhotosViewController*)segue.destinationViewController prepareViewWithImagesUserID:[UICKeyChainStore stringForKey:@"userID" service:@"com.flux"].integerValue];
    }
}

@end
