//
//  FluxAddUserViewController.m
//  Flux
//
//  Created by Kei Turner on 2/5/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxAddUserViewController.h"
#import "ProgressHUD.h"
#import "UICKeyChainStore.h"
#import "UIImageView+AFNetworking.h"
#import "FluxUserObject.h"
#import "UIActionSheet+Blocks.h"
#import "FluxSocialListViewController.h"
#import "FluxPublicProfileViewController.h"


@interface FluxAddUserViewController ()

@end

@implementation FluxAddUserViewController

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
    [topBarColored setFrame:CGRectMake(topBarColored.frame.origin.x, topBarColored.frame.origin.y, topBarColored.frame.size.width, 64)];
    
    UIBarButtonItem *negativeSeperator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSeperator.width = -16;
    NSMutableArray*arr = [topToolbar.items mutableCopy];
    [arr insertObject:negativeSeperator atIndex:0];
    [topToolbar setItems:arr];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont fontWithName:@"Akkurat" size:14.0]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor blackColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    
    resultsArray = [[NSMutableArray alloc]init];
    resultsImageArray = [[NSMutableArray alloc]init];
    
    searchState = searched;
    
    //to set the clear button's selected state image
    //[userSearchBar setImage:@"" forSearchBarIcon:UISearchBarIconClear state:UIControlStateHighlighted];
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
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return resultsArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollower] || [(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollowing] || ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] friendState] == 3)) {
        return 70.0;
    }
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier;
    if ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollower] || [(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollowing] || ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] friendState] == 3)) {
        cellIdentifier = @"statusSocialCell";
    }
    else{
        cellIdentifier = @"standardSocialCell";
    }

    FluxFriendFollowerCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxFriendFollowerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell setDelegate:self];
    [cell initCell];
    [cell setUserObject:[resultsArray objectAtIndex:indexPath.row]];
    if ([[resultsImageArray objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) {
        [cell.profileImageView setImage:[resultsImageArray objectAtIndex:indexPath.row]];
    }
    else{
        __weak FluxFriendFollowerCell *weakCell = cell;
        NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
        
        NSString*urlString = [NSString stringWithFormat:@"%@users/%i/avatar?size=%@&auth_token=%@",FluxTestServerURL,cell.userObject.userID,@"thumb", token];
        
        [cell.profileImageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]]
                              placeholderImage:[UIImage imageNamed:@"emptyProfileImage_small"]
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                           if (resultsImageArray.count > indexPath.row) {
                                               [resultsImageArray replaceObjectAtIndex:indexPath.row withObject:image];
                                               [weakCell.profileImageView setImage:image];
                                               //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                               //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                               [weakCell setNeedsLayout];
                                           }

                                           //}
                                       }
                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                           NSLog(@"profile image done broke :(");
                                       }];
    }
    
    if ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollower] || [(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollowing] || ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] friendState] == 3)) {
        if (([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] friendState] == 3)) {
            [cell setSocialMode:1];
        }
        else if ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollowing]){
            [cell setSocialMode:2];
        }
        else{
            [cell setSocialMode:3];
        }
    }
    
    [cell setDelegate:self];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    FluxFriendFollowerCell*cell = (FluxFriendFollowerCell*)[addUsersTableView cellForRowAtIndexPath:indexPath];
    self.title = @"Search";
    UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                           bundle:[NSBundle mainBundle]];
    
    // first get an instance from storyboard
    FluxPublicProfileViewController *publicProfileVC = [myStoryboard instantiateViewControllerWithIdentifier:@"publicProfileViewController"];
    [publicProfileVC setFluxDataManager:self.fluxDataManager];
    [publicProfileVC prepareViewWithUser:cell.userObject];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:publicProfileVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [userSearchBar resignFirstResponder];
}

#pragma mark - Social Cell Delegate
- (void)FriendFollowerCellButtonWasTapped:(FluxFriendFollowerCell *)friendFollowerCell{
    int index = [addUsersTableView indexPathForCell:friendFollowerCell].row;
    NSMutableArray*options = [[NSMutableArray alloc]init];
    
    NSString*sendFriendRequest = @"Send Friend Request";
    NSString*addFollower = @"Follow";
    NSString*acceptFriendRequest = @"Accept Friend Request";
    if (!friendFollowerCell.userObject.isFollowing) {
        [options addObject:addFollower];
    }
    if (!friendFollowerCell.userObject.friendState) {
        [options addObject:sendFriendRequest];
    }
    else{
        if (friendFollowerCell.userObject.friendState == 2) {
            [options addObject:acceptFriendRequest];
        }
    }
    
    [UIActionSheet showInView:self.view
                    withTitle:nil
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:nil
            otherButtonTitles:options
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             //link facebook
                             if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:addFollower]) {
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 
                                 [request setFollowUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"Followed");
                                     if (resultsArray.count > index) {
                                         //...and it's still the same cell
                                         if ([[(FluxUserObject*)[resultsArray objectAtIndex:index] username] isEqualToString:[friendFollowerCell.titleLabel.text substringFromIndex:1]]) {
                                             //update it
                                             [(FluxUserObject*)[resultsArray objectAtIndex:index] setIsFollowing:YES];
                                             [addUsersTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                         }
                                     }
                                 }];
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Adding a follower failed with error %d", (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager addFollowerWithUserID:[(FluxUserObject*)[resultsArray objectAtIndex:index]userID] withDataRequest:request];
                             }
                             if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:sendFriendRequest]) {
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 
                                 [request setSendFriendRequestReady:^(int userID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"friended");
                                     //if it hasn;t been cleared
                                     if (resultsArray.count > index) {
                                         //...and it's still the same cell
                                         if ([[(FluxUserObject*)[resultsArray objectAtIndex:index] username] isEqualToString:[friendFollowerCell.titleLabel.text substringFromIndex:1]]) {
                                             //update it
                                             [(FluxUserObject*)[resultsArray objectAtIndex:index] setFriendState:1];
                                             [addUsersTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                         }
                                     }
                                 }];
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Adding a follower failed with error %d", (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager sendFriendRequestToUserWithID:[(FluxUserObject*)[resultsArray objectAtIndex:index]userID] withDataRequest:request];
                             }
                             if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:acceptFriendRequest]) {
                                 
                             }
                         }
                     }];
}

#pragma mark SearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    if (searchQuery.length > searchText.length) {
        [resultsArray removeAllObjects];
        [resultsImageArray removeAllObjects];
        [addUsersTableView reloadData];
    }
    
    searchState = notSearching;
    searchQuery = searchText;
    [searchTimer invalidate];
    searchTimer = nil;
    
    if (searchText.length > 0) {
        searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(searchUsersFromQuery) userInfo:nil repeats:NO];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [searchTimer invalidate];
    searchTimer = nil;
    
    if (searchQuery.length > 0) {
        [self searchUsersFromQuery];
    }
    [searchBar becomeFirstResponder];
}


- (void)searchUsersFromQuery{
    if (searchState == notSearching) {
        searchState = searching;
        FluxDataRequest*request = [[FluxDataRequest alloc]init];
        
        [request setUserSearchReady:^(NSArray *userList, FluxDataRequest*completedRequest){
            //do something with array
            resultsArray = [userList mutableCopy];
            [resultsImageArray removeAllObjects];
            for (int i = 0; i<resultsArray.count; i++) {
                [resultsImageArray addObject:[NSNumber numberWithBool:NO]];
            }
            searchState = searched;
            [addUsersTableView reloadData];
        }];
        
        [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            searchState = notSearching;
            NSString*str = [NSString stringWithFormat:@"Search failed to load with error %d", (int)[e code]];
            [ProgressHUD showError:str];
            
        }];
        [self.fluxDataManager requestUsersListQuery:searchQuery withDataRequest:request];
    }
}

-(void)willAppear{
    [userSearchBar becomeFirstResponder];
    [self.navigationController setNavigationBarHidden:YES];
}

- (IBAction)doneButtonAction:(id)sender {
    [userSearchBar resignFirstResponder];
    [userSearchBar setText:@""];
    [resultsArray removeAllObjects];
    [resultsImageArray removeAllObjects];
    searchState = searched;
    [addUsersTableView reloadData];
    [(FluxSocialListViewController*)self.navigationController.parentViewController setSearchVCHidden:YES animated:YES];
}
@end
