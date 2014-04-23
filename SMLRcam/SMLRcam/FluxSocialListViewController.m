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
    
    self.screenName = @"Social List View";
    
    //clears hairline under the navBar, but also hides the status bar color. NEeds more thinking.
//    UINavigationBar *navigationBar = self.navigationController.navigationBar;
//    [navigationBar setBackgroundImage:[UIImage new]
//                       forBarPosition:UIBarPositionAny
//                           barMetrics:UIBarMetricsDefault];
//    [navigationBar setBackgroundColor:[UIColor colorWithRed:234/255.0 green:63/255.0 blue:63/255.0 alpha:1.0]];
//    
//    [navigationBar setShadowImage:[UIImage new]];
    
    
//    [self.view setAlpha:0.0];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    listMode = amFollowingMode;
    socialTableViews = [[NSMutableArray alloc]initWithObjects:followingTableView, followersTableView, nil];
    followersTableView.hidden = YES;
    
    
    socialListArray = [[NSMutableArray alloc]init];
    socialListImagesArray = [[NSMutableArray alloc]initWithObjects:[[NSMutableArray alloc]init],[[NSMutableArray alloc]init], nil];
    socialListsRefreshControls = [[NSMutableArray alloc]init];
    for (int i = 0; i<2; i++) {
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
    shouldReloadArray = [[NSMutableArray alloc]initWithObjects:[NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO],nil];
    selectedIndexPath = nil;
    
    //fix decenders in title label
    UILabel*label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 140, 18)];
    [label setText:@"My Network"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:17.0]];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(self.navigationController.navigationBar.center.x, self.navigationController.navigationBar.center.y)];
    [self.navigationItem setTitleView:label];
//    [self.navigationController.navigationBar addSubview:label];
    
    [self updateListForActiveMode];
    [self.navigationController.navigationBar setTranslucent:NO];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

    [self setTitle:@"My Network"];
    [self.searchUserVC removeFromParentViewController];
    [self.searchUserVC.view removeFromSuperview];
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:0.0 forBarMetrics:UIBarMetricsDefault];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [(UITableView*)[socialTableViews objectAtIndex:listMode]  setAlpha:1.0];
    [segmentedControlContainerView  setAlpha:1.0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [UIView animateWithDuration:0.25 animations:^{
//        [self.view setAlpha:1.0];
//        //[self.navigationController.navigationBar setTitleVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
//    }];
    [self setTitle:@""];
    
#warning THIS DOESNT WORK.
    if (self.badgeCount > 0) {
        self.badgeCount = 0;
        [segmentedControl setSelectedSegmentIndex:isFollowerMode];
        [self segmentedControllerDidChange:nil];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [UIView animateWithDuration:0.2 animations:^{
        [(UITableView*)[socialTableViews objectAtIndex:listMode]  setAlpha:0.0];
        [segmentedControlContainerView  setAlpha:0.0];
    }];

    if ([[segue identifier] isEqualToString:@"pushProfileSegue"]) {
        [(FluxPublicProfileViewController*)segue.destinationViewController setFluxDataManager:self.fluxDataManager];
        [(FluxPublicProfileViewController*)segue.destinationViewController prepareViewWithUser:(FluxUserObject*)sender];
        [(FluxPublicProfileViewController*)segue.destinationViewController setDelegate:self];
    }
    else{

    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)searchButtonAction:(id)sender {
    
    UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                           bundle:[NSBundle mainBundle]];
    
    // first get an instance from storyboard
    self.searchUserVC = [myStoryboard instantiateViewControllerWithIdentifier:@"searchUserVC"];
    
    self.childNavC = [[UINavigationController alloc]initWithRootViewController:self.searchUserVC];
    self.childNavC.interactivePopGestureRecognizer.enabled = NO;
    [self.childNavC.navigationBar setTranslucent:NO];
    
    [self.window addSubview:self.childNavC.view];
    
    // add the glkViewController as the child of self
    [self addChildViewController:self.childNavC];
    [self.childNavC didMoveToParentViewController:self];
    [self.searchUserVC setFluxDataManager:self.fluxDataManager];
    [self.searchUserVC setDelegate:self];
    self.childNavC.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height+64);
    [self setSearchVCHidden:YES animated:NO];
    
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.childNavC.view.frame];
    [bgView setImage:[(UIImageView*)[self.navigationController.view.subviews firstObject] image]];
    [bgView setBackgroundColor:[UIColor darkGrayColor]];
    [self.childNavC.view insertSubview:bgView atIndex:0];
    
    [self setSearchVCHidden:NO animated:YES];
    selectedIndexPath = nil;
}

- (void)setSearchVCHidden:(BOOL)hidden animated:(BOOL)animated{
    if (animated) {
        if (hidden) {
            [UIView animateWithDuration:0.3 animations:^{
                [self.childNavC.view setAlpha:0.0];
                
            } completion:^(BOOL finished){
                [self.childNavC removeFromParentViewController];
                [self.childNavC.view removeFromSuperview];
                
                self.childNavC = nil;
                self.searchUserVC = nil;
            }];
        }
        
        else{
            [self.childNavC.view setHidden:NO];
            [UIView animateWithDuration:0.3 animations:^{
                [self.childNavC.view setAlpha:1.0];
            }completion:^(BOOL finished){
                
            }];
        }
    }
    else{
        if (hidden) {
            //[self.childNavC.view removeFromSuperview];
            [self.childNavC.view setAlpha:0.0];
            [self.childNavC.view setHidden:YES];
        }
        else{
//            [self.window addSubview:self.childNavC.view];
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
//    if (([(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:listMode]  objectAtIndex:indexPath.row] isFollowingFlag] == 2) && (listMode == amFollowingMode)) {
//        return 70.0;
//    }
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString*cellIdentifier;
    if (tableView == followersTableView && [(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:listMode] objectAtIndex:indexPath.row] isFollowingFlag] == 1) {
        if ([(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:listMode] objectAtIndex:indexPath.row] bio]) {
            cellIdentifier = @"standardSocialCellRequest";
        }
        else{
            cellIdentifier = @"standardSocialCellRequestNoBio";
        }
    }
    else{
        if ([(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:listMode] objectAtIndex:indexPath.row] bio]) {
            cellIdentifier = @"standardSocialCell";
        }
        else{
            cellIdentifier = @"standardSocialCellNoBio";
        }
    }
    FluxFollowerCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxFollowerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell setDelegate:self];
    [cell initCell];
    [cell setUserObject:(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:listMode] objectAtIndex:indexPath.row]];
    if ([[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) {
        [cell.profileImageView setImage:[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] objectAtIndex:indexPath.row]];
    }
    else{
        __weak FluxFollowerCell *weakCell = cell;
        NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
        
        NSString*urlString = [NSString stringWithFormat:@"%@users/%i/avatar?size=%@&auth_token=%@",FluxServerURL,cell.userObject.userID,@"thumb", token];
        int currentMode = listMode;
        [cell.profileImageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]]
                                     placeholderImage:[UIImage imageNamed:@"emptyProfileImage_big"]
                                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                                  if (image) {
                                                      [[(NSMutableArray*)socialListImagesArray objectAtIndex:currentMode] replaceObjectAtIndex:indexPath.row withObject:image];
                                                      [weakCell.profileImageView setImage:image];
                                                      weakCell.userObject.hasProfilePic = YES;
                                                      //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                                      //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                                      [weakCell setNeedsLayout];
                                                      //}
                                                  }

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
    FluxFollowerCell*cell = (FluxFollowerCell*)[(UITableView*)[socialTableViews objectAtIndex:listMode] cellForRowAtIndexPath:indexPath];
    if ([[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) {
        [cell.userObject setProfilePic:(UIImage*)[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] objectAtIndex:indexPath.row]];
    }
    [self performSegueWithIdentifier:@"pushProfileSegue" sender:cell.userObject];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    selectedIndexPath = indexPath;
}

#pragma mark TableViewCell Delegate

//- (void)FriendFollowerCellButtonWasTapped:(FluxFriendFollowerCell *)friendFollowerCell{
//    if (listMode == friendMode) {
//        [UIActionSheet showInView:self.view
//                        withTitle:nil
//                cancelButtonTitle:@"Cancel"
//           destructiveButtonTitle:@"Unfriend"
//                otherButtonTitles:nil
//                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
//                             if (buttonIndex != actionSheet.cancelButtonIndex) {
//                                 //link facebook
//                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
//                                 
//                                 [request setUnfriendUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
//                                     //do something with the UserID
//                                     if (listMode == friendMode) {
//                                         if ([(NSMutableArray*)[socialListArray objectAtIndex:friendMode] count] > [(UITableView*)[socialTableViews objectAtIndex:friendMode] indexPathForCell:friendFollowerCell].row) {
//                                             [(NSMutableArray*)[socialListArray objectAtIndex:friendMode] removeObjectAtIndex:[(UITableView*)[socialTableViews objectAtIndex:friendMode] indexPathForCell:friendFollowerCell].row];
//                                             [(UITableView*)[socialTableViews objectAtIndex:friendMode] deleteRowsAtIndexPaths:[NSArray arrayWithObject:[(UITableView*)[socialTableViews objectAtIndex:friendMode] indexPathForCell:friendFollowerCell]] withRowAnimation:UITableViewRowAnimationFade];
//                                         }
//                                     }
//                                     NSLog(@"unfollowed");
//                                     
//                                     
//                                     //[addUsersTableView reloadData];
//                                 }];
//                                 
//                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
//                                     
//                                     NSString*str = [NSString stringWithFormat:@"Unfollowing %@ failed with error %d",friendFollowerCell.userObject.username, (int)[e code]];
//                                     [ProgressHUD showError:str];
//                                     
//                                 }];
//                                 [self.fluxDataManager unfriendWithUserID:friendFollowerCell.userObject.userID withDataRequest:request];
//                             }
//                         }];
//    }
//    else if (listMode == followingMode){
//        [UIActionSheet showInView:self.view
//                        withTitle:nil
//                cancelButtonTitle:@"Cancel"
//           destructiveButtonTitle:@"Unfollow"
//                otherButtonTitles:nil
//                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
//                             if (buttonIndex != actionSheet.cancelButtonIndex) {
//                                 //link facebook
//                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
//                                 
//                                 [request setUnfollowUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
//                                     //do something with the UserID
//                                     NSLog(@"unfollowed");
//                                     if (listMode == followingMode) {
//                                         if ([(NSMutableArray*)[socialListArray objectAtIndex:followingMode] count] > [(UITableView*)[socialTableViews objectAtIndex:followingMode] indexPathForCell:friendFollowerCell].row){
//                                             [(NSMutableArray*)[socialListArray objectAtIndex:followingMode] removeObjectAtIndex:[(UITableView*)[socialTableViews objectAtIndex:followingMode] indexPathForCell:friendFollowerCell].row];
//                                             [(UITableView*)[socialTableViews objectAtIndex:followingMode] deleteRowsAtIndexPaths:[NSArray arrayWithObject:[(UITableView*)[socialTableViews objectAtIndex:followingMode] indexPathForCell:friendFollowerCell]] withRowAnimation:UITableViewRowAnimationFade];
//                                         }
//                                     }
//                                     
//                                     //[addUsersTableView reloadData];
//                                 }];
//                                 
//                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
//                                     
//                                     NSString*str = [NSString stringWithFormat:@"Unfollowing %@ failed with error %d",friendFollowerCell.userObject.username, (int)[e code]];
//                                     [ProgressHUD showError:str];
//                                     
//                                 }];
//                                 [self.fluxDataManager unfollowUserWIthID:friendFollowerCell.userObject.userID withDataRequest:request];
//                             }
//                         }];
//    }
//    else{
//        
//    }
//}

- (void)FriendFollowerCellShouldAcceptFollowingRequest:(FluxFollowerCell *)friendFollowerCell{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    [friendFollowerCell setUserInteractionEnabled:NO];
    [request setAcceptFollowerRequestReady:^(int newFriendUserID, FluxDataRequest*completedRequest){
        //do something with the UserID
        NSLog(@"friended");
        if (listMode == isFollowerMode) {
            [(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:isFollowerMode] objectAtIndex:[(UITableView*)[socialTableViews objectAtIndex:isFollowerMode] indexPathForCell:friendFollowerCell].row] setIsFollowingFlag:2];
            [(UITableView*)[socialTableViews objectAtIndex:isFollowerMode] reloadRowsAtIndexPaths:[NSArray arrayWithObject:[(UITableView*)[socialTableViews objectAtIndex:isFollowerMode] indexPathForCell:friendFollowerCell]] withRowAnimation:UITableViewRowAnimationFade];
        }
        [friendFollowerCell setUserInteractionEnabled:YES];
        //[addUsersTableView reloadData];
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Accepting request from %@ failed",friendFollowerCell.userObject.username];
        [ProgressHUD showError:str];
        [friendFollowerCell setUserInteractionEnabled:YES];
        
    }];
    [self.fluxDataManager acceptFollowerRequestFromUserWithID:friendFollowerCell.userObject.userID withDataRequest:request];
}

- (void)FriendFollowerCellShouldIgnoreFollowingRequest:(FluxFollowerCell *)friendFollowerCell{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    [friendFollowerCell setUserInteractionEnabled:NO];
    [request setIgnoreFollowerRequestReady:^(int ignoredUserID, FluxDataRequest*completedRequest){
        //do something with the UserID
        NSLog(@"friend request ignored");
        if (listMode == isFollowerMode) {
            if ([(NSMutableArray*)[socialListArray objectAtIndex:isFollowerMode] count] > [(UITableView*)[socialTableViews objectAtIndex:isFollowerMode] indexPathForCell:friendFollowerCell].row){
                [(NSMutableArray*)[socialListArray objectAtIndex:isFollowerMode] removeObjectAtIndex:[(UITableView*)[socialTableViews objectAtIndex:isFollowerMode] indexPathForCell:friendFollowerCell].row];
                [(UITableView*)[socialTableViews objectAtIndex:isFollowerMode] deleteRowsAtIndexPaths:[NSArray arrayWithObject:[(UITableView*)[socialTableViews objectAtIndex:isFollowerMode] indexPathForCell:friendFollowerCell]] withRowAnimation:UITableViewRowAnimationFade];
            }

        }
        [friendFollowerCell setUserInteractionEnabled:YES];
        
        //[addUsersTableView reloadData];
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Ignoring request from %@ failed",friendFollowerCell.userObject.username];
        [ProgressHUD showError:str];
        [friendFollowerCell setUserInteractionEnabled:YES];
        
    }];
    [self.fluxDataManager ignoreFollowerRequestFromUserWithID:friendFollowerCell.userObject.userID withDataRequest:request];
}

#pragma mark - Public Profile Delegate
- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didAddFollower:(FluxUserObject *)userObject{
    [self addUser:userObject toListMode:amFollowingMode];
}

- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didremoveAmFollower:(FluxUserObject *)userObject{
    [self removeSelectedUserFromListMode:amFollowingMode];
}

- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didremoveIsFollower:(FluxUserObject *)userObject{
    [self removeSelectedUserFromListMode:isFollowerMode];
}

#pragma mark - Add User VC Delegate
- (void)AddUserViewController:(FluxAddUserViewController *)AddUserVC didFollowUser:(FluxUserObject*)userObject{
    [self addUser:userObject toListMode:amFollowingMode];
}
- (void)AddUserViewController:(FluxAddUserViewController *)AddUserVC didUnfollowUser:(FluxUserObject*)userObject{
    [self removeUser:userObject fromListMode:amFollowingMode];
}

#pragma mark shared delegate insert / delete methods

- (void)addUser:(FluxUserObject*)userObject toListMode:(SocialListMode)theListMode{
    //go through the array and find where to insert the new guy
    if (theListMode == amFollowingMode) {
        
        
        if (listMode == amFollowingMode) {
            NSArray*list = (NSMutableArray*)[socialListArray objectAtIndex:theListMode];
            BOOL found = NO;
            for (int i = 0; i< list.count ; i++) {
                if ([(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:theListMode] objectAtIndex:i] userID] == userObject.userID) {
                    [(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:theListMode] objectAtIndex:i] setAmFollowerFlag:2];
                    found= YES;
                    break;
                }
            }
            if (found) {
                [(UITableView*)[socialTableViews objectAtIndex:listMode] reloadData];
            }
            else{
                NSUInteger insPoint = [(NSMutableArray*)[socialListArray objectAtIndex:theListMode]
                                       indexOfObject:userObject
                                       inSortedRange:NSMakeRange(0, [(NSMutableArray*)[socialListArray objectAtIndex:theListMode] count])
                                       options:NSBinarySearchingInsertionIndex
                                       usingComparator:^(id lhs, id rhs) {
                                           NSString *first = [(FluxUserObject*)lhs username];
                                           NSString *second = [(FluxUserObject*)rhs username];
                                           return [first compare:second];
                                       }
                                       ];
                [(NSMutableArray*)[socialListArray objectAtIndex:theListMode] insertObject:userObject atIndex:insPoint];
                [[(NSMutableArray*)socialListImagesArray objectAtIndex:theListMode] insertObject:[NSNumber numberWithBool:NO] atIndex:insPoint];
                [(UITableView*)[socialTableViews objectAtIndex:listMode] reloadData];
            }
        }
        else{
            [shouldReloadArray replaceObjectAtIndex:amFollowingMode withObject:[NSNumber numberWithBool:YES]];
        }
        return;
    }
}

- (void)removeSelectedUserFromListMode:(SocialListMode)theListMode{
    if (selectedIndexPath) {
        if ([(NSMutableArray*)[socialListArray objectAtIndex:theListMode] count] > selectedIndexPath.row) {
            [(NSMutableArray*)[socialListArray objectAtIndex:theListMode] removeObjectAtIndex:selectedIndexPath.row];
            if (listMode == theListMode) {
                [(UITableView*)[socialTableViews objectAtIndex:theListMode] deleteRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            else{
                [shouldReloadArray replaceObjectAtIndex:theListMode withObject:[NSNumber numberWithBool:YES]];
            }
        }
    }
}

- (void)removeUser:(FluxUserObject*)theUserObject fromListMode:(SocialListMode)theListMode{
    
    //make temporary array so we don't delete while enumerating
    NSArray*list = (NSMutableArray*)[socialListArray objectAtIndex:theListMode];
    for (int i = 0; i< list.count ; i++) {
        if ([(FluxUserObject*)[(NSMutableArray*)[socialListArray objectAtIndex:theListMode] objectAtIndex:i] userID] == theUserObject.userID) {
            [(NSMutableArray*)[socialListArray objectAtIndex:theListMode] removeObjectAtIndex:i];
            if (listMode == theListMode) {
                [(UITableView*)[socialTableViews objectAtIndex:theListMode] deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
            else{
                [shouldReloadArray replaceObjectAtIndex:theListMode withObject:[NSNumber numberWithBool:YES]];
            }
            
            return;
        }
    }
}



#pragma mark - Data Model Stuff
- (void)updateListForActiveMode{
    if (![(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:listMode] isRefreshing]) {
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:listMode] beginRefreshing];
    }
    if (listMode == amFollowingMode){
        [self updateFollowingList];
    }
    else{
        [self updateFollowerList];
    }
    [shouldReloadArray replaceObjectAtIndex:listMode withObject:[NSNumber numberWithBool:NO]];
}

//- (void)updateFriendsList{
//    FluxDataRequest*request = [[FluxDataRequest alloc]init];
//    
//    [request setUserFriendsReady:^(NSArray *friendsList, FluxDataRequest*completedRequest){
//        //do something with array
//        [socialListArray replaceObjectAtIndex:friendMode withObject:[friendsList mutableCopy]];
//        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:friendMode] endRefreshing];
//        [self addEmptyImagesToArrayForListMore:friendMode];
//        if (listMode == friendMode) {
//            [[socialTableViews objectAtIndex:friendMode] reloadData];
//        }
//
//    }];
//    
//    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
//        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:friendMode] endRefreshing];
//        NSString*str = [NSString stringWithFormat:@"Friends failed to load with error %d", (int)[e code]];
//        [ProgressHUD showError:str];
//    }];
//    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
//    [self.fluxDataManager requestFriendsListForID:[userID intValue] withDataRequest:request];
//}

- (void)updateFollowingList{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setUserFollowingsReady:^(NSArray *followingList, FluxDataRequest*completedRequest){
        //do something with array
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:amFollowingMode] endRefreshing];
        [socialListArray replaceObjectAtIndex:amFollowingMode withObject:[followingList mutableCopy]];
        [self addEmptyImagesToArrayForListMore:amFollowingMode];
        if (listMode == amFollowingMode) {
            [[socialTableViews objectAtIndex:amFollowingMode] reloadData];
        }
        
    }];
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Updating your following list failed"];
        [ProgressHUD showError:str];
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:amFollowingMode] endRefreshing];
    }];
    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    [self.fluxDataManager requestFollowingListForID:[userID intValue] withDataRequest:request];
}

- (void)updateFollowerList{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setUserFollowersReady:^(NSArray *followerList, FluxDataRequest*completedRequest){
        //do something with array
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:isFollowerMode] endRefreshing];
        [socialListArray replaceObjectAtIndex:isFollowerMode withObject:[followerList mutableCopy]];
        [self addEmptyImagesToArrayForListMore:isFollowerMode];
        if (listMode == isFollowerMode) {
            [[socialTableViews objectAtIndex:isFollowerMode] reloadData];
        }
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Updating your followers list failed"];
        [ProgressHUD showError:str];
        [(UIRefreshControl*)[socialListsRefreshControls objectAtIndex:isFollowerMode] endRefreshing];
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
    [segmentedControl setUserInteractionEnabled:NO];
    if (listMode == [segmentedControl selectedSegmentIndex]) {
        if ([(UITableView*) [socialTableViews objectAtIndex:listMode] numberOfRowsInSection:0] > 0) {
            [(UITableView*) [socialTableViews objectAtIndex:listMode] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            
            //disable user interaction to avoid crashes during animation
            [segmentedControl setUserInteractionEnabled:NO];
        }
    }
    else{
        [(UITableView*)[socialTableViews objectAtIndex:listMode] setHidden:YES];
        listMode = [segmentedControl selectedSegmentIndex];
        [(UITableView*)[socialTableViews objectAtIndex:listMode] setHidden:NO];
        
        if ([(NSMutableArray*)[socialListArray objectAtIndex:listMode] count] == 0  || [(NSNumber*)[shouldReloadArray objectAtIndex:listMode]boolValue]){
            [self updateListForActiveMode];
        }
        if ([(NSMutableArray*)[socialListArray objectAtIndex:listMode] count] > 0 && [[[socialTableViews objectAtIndex:listMode]visibleCells] count] == 0) {
            [(UITableView*)[socialTableViews objectAtIndex:listMode] reloadData];
        }
        
    }
    [segmentedControl setUserInteractionEnabled:YES];
}

//re-enable interaction after animation
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [segmentedControl setUserInteractionEnabled:YES];
}


@end
