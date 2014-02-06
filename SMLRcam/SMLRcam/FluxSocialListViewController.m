//
//  FluxSocialListViewController.m
//  Flux
//
//  Created by Kei Turner on 1/17/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSocialListViewController.h"
#import "ProgressHUD.h"
#import "UICKeyChainStore.h"

#import "FluxAddUserViewController.h"

@interface FluxSocialListViewController ()

@end

@implementation FluxSocialListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setAlpha:0.0];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    listMode = friendMode;
    socialTableViews = [[NSMutableArray alloc]initWithObjects:friendsTableView, followingTableView, followersTableView, nil];
    followingTableView.hidden = followersTableView.hidden = YES;
    
    socialListArray = [[NSMutableArray alloc]init];
    socialListsRefreshControls = [[NSMutableArray alloc]init];
    for (int i = 0; i<3; i++) {
        NSMutableArray*mutArr = [[NSMutableArray alloc]init];
        [socialListArray addObject:mutArr];
        
        UITableViewController *tableViewController = [[UITableViewController alloc] init];
        tableViewController.tableView = (UITableView*)[socialTableViews objectAtIndex:i];
        
        UIRefreshControl*refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl setTintColor:[UIColor whiteColor]];
        [refreshControl addTarget:self action:@selector(handleReresh) forControlEvents:UIControlEventValueChanged];
        tableViewController.refreshControl = refreshControl;
        [socialListsRefreshControls addObject:refreshControl];
    }
    
    
    [self updateListForActiveMode];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

    [UIView animateWithDuration:0.2 animations:^{
        [self.view setAlpha:0.0];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setAlpha:1.0];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [(FluxAddUserViewController*)segue.destinationViewController setFluxDataManager:self.fluxDataManager];
    UIImage* snapshot = [(UIImageView*)[[[(UINavigationController*)self.parentViewController view] subviews] objectAtIndex:0] image];
    
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.frame];
    [bgView setImage:snapshot];
    [bgView setBackgroundColor:[UIColor darkGrayColor]];
    [[(FluxAddUserViewController*)segue.destinationViewController view] insertSubview:bgView atIndex:0];
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
    return [(NSMutableArray*)[socialListArray objectAtIndex:listMode] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"standardSocialCell";
    FluxFriendFollowerCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxFriendFollowerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell initCell];
    
    [cell setDelegate:self];
    
    return cell;
}

- (void)handleReresh{
    [self updateListForActiveMode];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"tapped cell with userID %@",(NSString*)[(NSArray*)[socialListArray objectAtIndex:listMode] objectAtIndex:indexPath.row]);
}

- (void)FriendFollowerCellButtonWasTapped:(FluxFriendFollowerCell *)friendFollowerCell{
    NSLog(@"tapped button on cell with userID %i",friendFollowerCell.userObject.userID);
}

#pragma mark - Data Model Stuff
- (void)updateListForActiveMode{
    if (![(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:listMode] isRefreshing]) {
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:listMode] beginRefreshing];
    }
    
    if (listMode == friendMode) {
        [self updateFriendsList];
    }
    else if (listMode == followingMode){
        [self updateFollowingList];
    }
    else{
        [self updateFollowerList];
    }
}

- (void)updateFriendsList{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setUserFriendsReady:^(NSArray *friendsList, FluxDataRequest*completedRequest){
        //do something with array
        [socialListArray replaceObjectAtIndex:friendMode withObject:friendsList];
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:friendMode] endRefreshing];
        if (listMode == friendMode) {
            [[socialTableViews objectAtIndex:friendMode] reloadData];
        }

    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:friendMode] endRefreshing];
        NSString*str = [NSString stringWithFormat:@"Friends failed to load with error %d", (int)[e code]];
        [ProgressHUD showError:str];
    }];
    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    [self.fluxDataManager requestFriendsListForID:[userID intValue] withDataRequest:request];
}

- (void)updateFollowingList{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setUserFollowingsReady:^(NSArray *friendsList, FluxDataRequest*completedRequest){
        //do something with array
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:followingMode] endRefreshing];
        [socialListArray replaceObjectAtIndex:friendMode withObject:friendsList];
        if (listMode == friendMode) {
            [[socialTableViews objectAtIndex:followingMode] reloadData];
        }
        
    }];
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Following failed to load with error %d", (int)[e code]];
        [ProgressHUD showError:str];
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:followingMode] endRefreshing];
    }];
    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    [self.fluxDataManager requestFollowingListForID:[userID intValue] withDataRequest:request];
}

- (void)updateFollowerList{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setUserFollowersReady:^(NSArray *friendsList, FluxDataRequest*completedRequest){
        //do something with array
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:followerMode] endRefreshing];
        [socialListArray replaceObjectAtIndex:friendMode withObject:friendsList];
        if (listMode == friendMode) {
            [[socialTableViews objectAtIndex:followerMode] reloadData];
        }
        
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Followers failed to load with error %d", (int)[e code]];
        [ProgressHUD showError:str];
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:followerMode] endRefreshing];
    }];
    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    [self.fluxDataManager requestFollowerListForID:[userID intValue] withDataRequest:request];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

//-(void)prepareViewforMode:(SocialListMode)mode andIDList:(NSArray *)idList{
//    listMode = mode;
//    friendFollowerArray = [[NSMutableArray alloc]init];
//    
//    for (NSString* userID in idList){
//        FluxUserObject*person = [[FluxUserObject alloc]init];
//        [person setUserID:[userID intValue]];
//        [friendFollowerArray addObject:person];
//    }
//    
//    if (listMode == followerMode) {
//        self.title = @"Followers";
//    }
//    else if (listMode == followingMode){
//        self.title = @"Following";
//    }
//    else{
//        self.title = @"Friends";
//    }
//}

- (IBAction)segmentedControllerDidChange:(id)sender {
    [(UITableView*)[socialTableViews objectAtIndex:listMode] setHidden:YES];
    listMode = [(UISegmentedControl*)sender selectedSegmentIndex];
    [(UITableView*)[socialTableViews objectAtIndex:listMode] setHidden:NO];
    
    if ([(NSMutableArray*)[socialListArray objectAtIndex:listMode] count] == 0) {
        [self updateListForActiveMode];
    }
}
@end
