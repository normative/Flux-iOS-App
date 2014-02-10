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
#import "UIImageView+AFNetworking.h"
#import "UIActionSheet+Blocks.h"
#import "FluxAddUserViewController.h"
#import "FluxPublicProfileViewController.h"

@interface FluxSocialListViewController ()

@end

@implementation FluxSocialListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    if ([appDelegate respondsToSelector:@selector(window)])
		self.window = [appDelegate performSelector:@selector(window)];
	else self.window = [[UIApplication sharedApplication] keyWindow];
    
    
    
    [self.view setAlpha:0.0];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    listMode = friendMode;
    socialTableViews = [[NSMutableArray alloc]initWithObjects:friendsTableView, followingTableView, followersTableView, nil];
    followingTableView.hidden = followersTableView.hidden = YES;
    
    
    socialListArray = [[NSMutableArray alloc]init];
    socialListImagesArray = [[NSMutableArray alloc]initWithObjects:[[NSMutableArray alloc]init],[[NSMutableArray alloc]init],[[NSMutableArray alloc]init], nil];
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
    
    UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                           bundle:[NSBundle mainBundle]];

    // first get an instance from storyboard
    self.searchUserVC = [myStoryboard instantiateViewControllerWithIdentifier:@"searchUserVC"];
    
    self.childNavC = [[UINavigationController alloc]initWithRootViewController:self.searchUserVC];
    self.childNavC.interactivePopGestureRecognizer.enabled = NO;
    // then add the imageCaptureView as the subview of the parent view
    [self.window addSubview:self.childNavC.view];
    // add the glkViewController as the child of self
    [self addChildViewController:self.childNavC];
    [self.childNavC didMoveToParentViewController:self];
    [self.searchUserVC setFluxDataManager:self.fluxDataManager];
    self.childNavC.view.frame = self.view.bounds;
    [self setSearchVCHidden:YES animated:NO];
    
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.childNavC.view.frame];
    [bgView setImage:[(UIImageView*)[self.navigationController.view.subviews firstObject] image]];
    [bgView setBackgroundColor:[UIColor darkGrayColor]];
    [self.childNavC.view insertSubview:bgView atIndex:0];
    
    
    [self updateListForActiveMode];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

    [UIView animateWithDuration:0.2 animations:^{
        [self.view setAlpha:0.0];
    }];
    
    [self.searchUserVC removeFromParentViewController];
    [self.searchUserVC.view removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setAlpha:1.0];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"pushProfileSegue"]) {
        [(FluxPublicProfileViewController*)segue.destinationViewController setFluxDataManager:self.fluxDataManager];
        [(FluxPublicProfileViewController*)segue.destinationViewController prepareViewWithUser:(FluxUserObject*)sender];
    }
    else{
        [(FluxAddUserViewController*)segue.destinationViewController setFluxDataManager:self.fluxDataManager];
        UIImage* snapshot = [(UIImageView*)[[[(UINavigationController*)self.parentViewController view] subviews] objectAtIndex:0] image];
        
        UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.frame];
        [bgView setImage:snapshot];
        [bgView setBackgroundColor:[UIColor darkGrayColor]];
        [[(FluxAddUserViewController*)segue.destinationViewController view] insertSubview:bgView atIndex:0];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setSearchVCHidden:(BOOL)hidden animated:(BOOL)animated{
    if (animated) {
        if (hidden) {
            [UIView animateWithDuration:0.3 animations:^{
                [self.childNavC.view setAlpha:0.0];
                
            } completion:^(BOOL finished){
                [self.childNavC.view setHidden:YES];
            }];
        }
        
        else{
            [self.childNavC.view setHidden:NO];
            [UIView animateWithDuration:0.3 animations:^{
                [self.childNavC.view setAlpha:1.0];
            }];
        }
    }
    else{
        if (hidden) {
            [self.childNavC.view setAlpha:0.0];
            [self.childNavC.view setHidden:YES];
        }
        else{
            [self.childNavC.view setAlpha:1.0];
            [self.childNavC.view setHidden:NO];
        }
    }

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
    return 80.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"standardSocialCell";
    FluxFriendFollowerCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxFriendFollowerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell setDelegate:self];
    [cell initCell];
    [cell setUserObject:(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:listMode] objectAtIndex:indexPath.row]];
    if ([[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) {
        [cell.profileImageView setImage:[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] objectAtIndex:indexPath.row]];
    }
    else{
        __weak FluxFriendFollowerCell *weakCell = cell;
        NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
        
        NSString*urlString = [NSString stringWithFormat:@"%@users/%i/avatar?size=%@&auth_token=%@",FluxTestServerURL,cell.userObject.userID,@"thumb", token];
        int currentMode = listMode;
        [cell.profileImageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]]
                                     placeholderImage:[UIImage imageNamed:@"emptyProfileImage_small"]
                                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                                  [[(NSMutableArray*)socialListImagesArray objectAtIndex:currentMode] replaceObjectAtIndex:indexPath.row withObject:image];
                                                  [weakCell.profileImageView setImage:image];
                                                  weakCell.userObject.hasProfilePic = YES;
                                                  //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                                  //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                                  [weakCell setNeedsLayout];
                                                  //}
                                              }
                                              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                                  NSLog(@"profile image done broke :(");
                                              }];
    }
    
    [cell setDelegate:self];
    
    return cell;
}

- (void)handleReresh{
    [self updateListForActiveMode];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    FluxFriendFollowerCell*cell = (FluxFriendFollowerCell*)[(UITableView*)[socialTableViews objectAtIndex:listMode] cellForRowAtIndexPath:indexPath];
    if ([[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) {
        [cell.userObject setProfilePic:(UIImage*)[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] objectAtIndex:indexPath.row]];
    }
    [self performSegueWithIdentifier:@"pushProfileSegue" sender:cell.userObject];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)FriendFollowerCellButtonWasTapped:(FluxFriendFollowerCell *)friendFollowerCell{
    if (listMode == friendMode) {
        [UIActionSheet showInView:self.view
                        withTitle:nil
                cancelButtonTitle:@"Cancel"
           destructiveButtonTitle:@"Unfriend"
                otherButtonTitles:nil
                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                             if (buttonIndex != actionSheet.cancelButtonIndex) {
                                 //link facebook
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 
                                 [request setUnfriendUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     if (listMode == friendMode) {
                                         [(NSMutableArray*)[socialListArray objectAtIndex:friendMode] removeObjectAtIndex:[(UITableView*)[socialTableViews objectAtIndex:friendMode] indexPathForCell:friendFollowerCell].row];
                                         [(UITableView*)[socialTableViews objectAtIndex:friendMode] deleteRowsAtIndexPaths:[NSArray arrayWithObject:[(UITableView*)[socialTableViews objectAtIndex:friendMode] indexPathForCell:friendFollowerCell]] withRowAnimation:UITableViewRowAnimationFade];
                                     }
                                     NSLog(@"unfollowed");
                                     
                                     
                                     //[addUsersTableView reloadData];
                                 }];
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Unfollowing %@ failed with error %d",friendFollowerCell.userObject.username, (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager unfriendWithUserID:friendFollowerCell.userObject.userID withDataRequest:request];
                             }
                         }];
    }
    else if (listMode == followingMode){
        [UIActionSheet showInView:self.view
                        withTitle:nil
                cancelButtonTitle:@"Cancel"
           destructiveButtonTitle:@"Unfollow"
                otherButtonTitles:nil
                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                             if (buttonIndex != actionSheet.cancelButtonIndex) {
                                 //link facebook
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 
                                 [request setUnfollowUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"unfollowed");
                                     if (listMode == followingMode) {
                                         [(NSMutableArray*)[socialListArray objectAtIndex:followingMode] removeObjectAtIndex:[(UITableView*)[socialTableViews objectAtIndex:followingMode] indexPathForCell:friendFollowerCell].row];
                                         [(UITableView*)[socialTableViews objectAtIndex:followingMode] deleteRowsAtIndexPaths:[NSArray arrayWithObject:[(UITableView*)[socialTableViews objectAtIndex:followingMode] indexPathForCell:friendFollowerCell]] withRowAnimation:UITableViewRowAnimationFade];
                                     }
                                     
                                     //[addUsersTableView reloadData];
                                 }];
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Unfollowing %@ failed with error %d",friendFollowerCell.userObject.username, (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager unfollowUserWIthID:friendFollowerCell.userObject.userID withDataRequest:request];
                             }
                         }];
    }
    else{
        
    }
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
        [socialListArray replaceObjectAtIndex:friendMode withObject:[friendsList mutableCopy]];
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:friendMode] endRefreshing];
        [self addEmptyImagesToArrayForListMore:friendMode];
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
        [socialListArray replaceObjectAtIndex:followingMode withObject:[friendsList mutableCopy]];
        [self addEmptyImagesToArrayForListMore:followingMode];
        if (listMode == followingMode) {
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
        [socialListArray replaceObjectAtIndex:followerMode withObject:[friendsList mutableCopy]];
        [self addEmptyImagesToArrayForListMore:followerMode];
        if (listMode == followerMode) {
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

-(void)addEmptyImagesToArrayForListMore:(SocialListMode)theListMode{
    [[(NSMutableArray*)socialListImagesArray objectAtIndex:theListMode] removeAllObjects];
    for (int i = 0; i<[(NSArray*)[socialListArray objectAtIndex:theListMode] count]; i++) {
        [[(NSMutableArray*)socialListImagesArray objectAtIndex:theListMode] addObject:[NSNumber numberWithBool:NO]];
    }
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

- (IBAction)searchButtonAction:(id)sender {
    if ([self.childNavC.view isHidden]) {
        [self.searchUserVC willAppear];
        [self setSearchVCHidden:NO animated:YES];
    }
    else{
        [self setSearchVCHidden:YES animated:YES];
    }
}
@end
