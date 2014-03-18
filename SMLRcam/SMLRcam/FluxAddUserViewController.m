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
#import "FluxSocialImportViewController.h"



@interface FluxAddUserViewController ()

@end

@implementation FluxAddUserViewController

@synthesize delegate;

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
    self.screenName = @"Add Users View";
    didImport = NO;
    [topBarColored setFrame:CGRectMake(topBarColored.frame.origin.x, topBarColored.frame.origin.y, topBarColored.frame.size.width, 64)];
    
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont fontWithName:@"Akkurat" size:14.0]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor blackColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor blackColor]];
    
    resultsArray = [[NSMutableArray alloc]init];
    resultsImageArray = [[NSMutableArray alloc]init];
    
//    socialImportArray = [[NSArray alloc]initWithObjects:@"Twitter", @"Facebook", @"Contacts", nil];
    socialImportArray = [[NSArray alloc]initWithObjects:@"Twitter", @"Facebook", nil];
    
    searchState = searched;
    
    //to set the clear button's selected state image
    //[userSearchBar setImage:@"" forSearchBarIcon:UISearchBarIconClear state:UIControlStateHighlighted];
    
    
    // your searchbar
    userSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 260, 44)];
    [userSearchBar setPlaceholder:@"Find in Flux"];
    [userSearchBar setBackgroundColor:[UIColor clearColor]];
    [userSearchBar setBarTintColor: [UIColor clearColor]];
    [userSearchBar setTintColor: [UIColor clearColor]];
    [userSearchBar setBackgroundImage:[UIImage imageNamed:@"nothing"]];
    [userSearchBar setSearchFieldBackgroundPositionAdjustment:UIOffsetMake(0, 1)];
    [userSearchBar setSearchTextPositionAdjustment:UIOffsetMake(0, 2)];
    [userSearchBar setSearchBarStyle:UISearchBarStyleProminent];
    [userSearchBar setDelegate:self];
    
    //create a customview and make its frame equal to your searchbar
    UIView *searchBarView = [[UIView alloc] initWithFrame:userSearchBar.frame];
    
    // add your searchbar to the custom view
    [searchBarView addSubview:userSearchBar];
    
    //finally add it to your bar item of the toolbar
    UIBarButtonItem *searchBarItem =
    [[UIBarButtonItem alloc] initWithCustomView:searchBarView];
    
    [searchBarItem setTintColor:[UIColor clearColor]];
    [searchBarItem setStyle:UIBarButtonItemStylePlain];
    
    NSMutableArray *newItems = [topToolbar.items mutableCopy];
    [newItems insertObject:searchBarItem atIndex:0];
 
    UIBarButtonItem *negativeSeperator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSeperator.width = -16;
    [newItems insertObject:negativeSeperator atIndex:0];
    [topToolbar setItems:newItems];
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
    if (userSearchBar.text.length == 0 && !didImport) {
        [userSearchBar becomeFirstResponder];
    }
    didImport = NO;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if ([segue.identifier isEqualToString:@"socialImportPush"]) {
        [(FluxSocialImportViewController*)segue.destinationViewController setServiceType:sender];
        [(FluxSocialImportViewController*)segue.destinationViewController setFluxDataManager:self.fluxDataManager];
        [(FluxSocialImportViewController*)segue.destinationViewController setTWAccount:TWAccount];
        didImport = YES;
    }
}

#pragma mark - TableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return nil;
    }
    else{
        float height = [self tableView:tableView heightForHeaderInSection:section];
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, tableView.frame.size.width, height)];
        [view setBackgroundColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:0.7]];
        
        // Create label with section title
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(20, 10, 150, height);
        label.textColor = [UIColor whiteColor];
        [label setFont:[UIFont fontWithName:@"Akkurat" size:12]];
        label.text = @"Or find from...";
        label.backgroundColor = [UIColor clearColor];
        [label setCenter:CGPointMake(label.center.x, view.center.y+1)];
        [view addSubview:label];
        
        return view;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0.0;
    }
    else{
        return 20.0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return resultsArray.count;
    }
    else{
        return socialImportArray.count;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        if ([[resultsArray objectAtIndex:indexPath.row] isKindOfClass:[NSNumber class]]) {
            return 75.0;
        }
        if ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] amFollowerFlag] > 0 || [(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollowingFlag] > 0) {
            return 70.0;
        }
        return 60.0;
    }
    else
        return 50.0;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        NSString *cellIdentifier;
        if ([(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] amFollowerFlag] > 0 || [(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] isFollowingFlag] > 0) {
            cellIdentifier = @"statusSocialCell";
        }
        else{
            cellIdentifier = @"standardSocialCell";
        }
        
        FluxFollowerCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[FluxFollowerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        [cell setDelegate:self];
        [cell initCell];
        [cell setUserObject:[resultsArray objectAtIndex:indexPath.row]];
        if ([[resultsImageArray objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) {
            [cell.profileImageView setImage:[resultsImageArray objectAtIndex:indexPath.row]];
        }
        else{
            __weak FluxFollowerCell *weakCell = cell;
            NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
            
            NSString*urlString = [NSString stringWithFormat:@"%@users/%i/avatar?size=%@&auth_token=%@",FluxServerURL,cell.userObject.userID,@"thumb", token];
            
            [cell.profileImageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]]
                                         placeholderImage:[UIImage imageNamed:@"emptyProfileImage_big"]
                                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                                      if (resultsImageArray.count > indexPath.row) {
                                                          if (image) {
                                                              [resultsImageArray replaceObjectAtIndex:indexPath.row withObject:image];
                                                              [weakCell.profileImageView setImage:image];
                                                              //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                                              //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                                              [weakCell setNeedsLayout];
                                                          }
                                                      }
                                                  }
                                                  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                                      NSLog(@"profile image done broke :(");
                                                  }];
        }
        
        [cell setDelegate:self];
        
        return cell;
    }
    else{
        NSString *cellIdentifier = @"importSocialCell";
        FluxSocialImportCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[FluxSocialImportCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        [cell initCell];
        [cell setTheTitle:(NSString*)[socialImportArray objectAtIndex:indexPath.row]];
        return cell;
    }

}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        selectedIndexPath = indexPath;
        FluxFollowerCell*cell = (FluxFollowerCell*)[addUsersTableView cellForRowAtIndexPath:indexPath];
        self.title = @"Search";
        UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                               bundle:[NSBundle mainBundle]];
        
        // first get an instance from storyboard
        FluxPublicProfileViewController *publicProfileVC = [myStoryboard instantiateViewControllerWithIdentifier:@"publicProfileViewController"];
        [publicProfileVC setFluxDataManager:self.fluxDataManager];
        [publicProfileVC prepareViewWithUser:cell.userObject];
        [publicProfileVC setDelegate:self];
        
        [self.navigationController pushViewController:publicProfileVC animated:YES];
    }
    else{
        if ([(NSString*)[socialImportArray objectAtIndex:indexPath.row]isEqualToString:@"Twitter"]) {
            FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
            [socialManager setDelegate:self];
            [socialManager linkTwitter];
        }
        else if ([(NSString*)[socialImportArray objectAtIndex:indexPath.row]isEqualToString:@"Facebook"]){
            FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
            [socialManager setDelegate:self];
            [socialManager linkFacebook];
        }
        else if ([(NSString*)[socialImportArray objectAtIndex:indexPath.row]isEqualToString:@"Contacts"]){
            //get contacts
            
            //then push new view
            [self performSegueWithIdentifier:@"socialImportPush" sender:@"Contacts"];
        }
        else{
            
        }
    }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [userSearchBar resignFirstResponder];
}

#pragma mark - Social Cell Delegate
- (void)FriendFollowerCellButtonWasTapped:(FluxFollowerCell *)friendFollowerCell{
    int index = (int)[addUsersTableView indexPathForCell:friendFollowerCell].row;
    NSMutableArray*options = [[NSMutableArray alloc]init];
    
    NSString*sendFollowerRequest = @"Send Follow Request";
    NSString*acceptFollowerRequest = @"Accept Follow Request";
    NSString*cancelFollowerRequest;

    if (friendFollowerCell.userObject.amFollowerFlag == 0) {
        [options addObject:sendFollowerRequest];
    }
    else{
        if (friendFollowerCell.userObject.amFollowerFlag == 1) {
            cancelFollowerRequest = @"Cancel Follow Request";
        }
    }
    if (options.count > 0 || cancelFollowerRequest) {
        [UIActionSheet showInView:self.view
                        withTitle:nil
                cancelButtonTitle:@"Cancel"
           destructiveButtonTitle:(cancelFollowerRequest? cancelFollowerRequest : nil)
                otherButtonTitles:options
                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                             if (buttonIndex != actionSheet.cancelButtonIndex) {
                                                              }
                                 if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:sendFollowerRequest]) {
                                     FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                     
                                     [request setSendFollowerRequestReady:^(int userID, FluxDataRequest*completedRequest){
                                         //do something with the UserID
                                         NSLog(@"Follower request sent");
                                         //if it hasn;t been cleared
                                         if (resultsArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxUserObject*)[resultsArray objectAtIndex:index] username] isEqualToString:[friendFollowerCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxUserObject*)[resultsArray objectAtIndex:index] setAmFollowerFlag:1];
                                                 [addUsersTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                     }];
                                     
                                     [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                         
                                         NSString*str = [NSString stringWithFormat:@"Adding a follower failed with error %d", (int)[e code]];
                                         [ProgressHUD showError:str];
                                         
                                     }];
                                     [self.fluxDataManager sendFollowerRequestToUserWithID:[(FluxUserObject*)[resultsArray objectAtIndex:index]userID] withDataRequest:request];
                                 }
//                                 if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:acceptFollowerRequest]) {
//                                     
//                                     FluxDataRequest*request = [[FluxDataRequest alloc]init];
//                                     [friendFollowerCell setUserInteractionEnabled:NO];
//                                     [request setAcceptFollowerRequestReady:^(int newFriendUserID, FluxDataRequest*completedRequest){
//                                         //do something with the UserID
//                                         NSLog(@"follow accepted");
//                                         [(FluxUserObject*)[resultsArray objectAtIndex:index] setFollowingState:3];
//                                         [addUsersTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
//                                         //[addUsersTableView reloadData];
//                                     }];
//                                     
//                                     if ([delegate respondsToSelector:@selector(AddUserViewController:didAddFollower:)]) {
//                                         [delegate AddUserViewController:self didAddFollower:friendFollowerCell.userObject];
//                                     }
//                                     
//                                     [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
//                                         
//                                         NSString*str = [NSString stringWithFormat:@"Accepting follow request from %@ failed with error %d",friendFollowerCell.userObject.username, (int)[e code]];
//                                         [ProgressHUD showError:str];
//                                         
//                                     }];
//                                     [self.fluxDataManager acceptFollowerRequestFromUserWithID:friendFollowerCell.userObject.userID withDataRequest:request];
//                                 }
                             
                                 
                                 if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:cancelFollowerRequest]) {
                                     FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                     
                                     [request setUnfollowUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
                                         //do something with the UserID
                                         NSLog(@"follow request cancelled");
                                         if (resultsArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxUserObject*)[resultsArray objectAtIndex:index] username] isEqualToString:[friendFollowerCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxUserObject*)[resultsArray objectAtIndex:index] setAmFollowerFlag:0];
                                                 [addUsersTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                     }];
                                     
                                     
                                     [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                         
                                         NSString*str = [NSString stringWithFormat:@"Cancelling follow request failed with error %d", (int)[e code]];
                                         [ProgressHUD showError:str];
                                         
                                     }];
                                     [self.fluxDataManager unfollowUserWIthID:[(FluxUserObject*)[resultsArray objectAtIndex:index]userID] withDataRequest:request];
                                 }
                         }];
    }
}

#pragma mark - Social Manager Delegate
- (void)SocialManager:(FluxSocialManager *)socialManager didLinkTwitterAccount:(ACAccount *)theAccount{
    TWAccount = theAccount;
    [self performSegueWithIdentifier:@"socialImportPush" sender:TwitterService];
}

- (void)SocialManager:(FluxSocialManager *)socialManager didLinkFacebookAccountWithName:(NSString *)name{
    [self performSegueWithIdentifier:@"socialImportPush" sender:FacebookService];
}

- (void)SocialManager:(FluxSocialManager *)socialManager didFailToLinkSocialAccount:(NSString *)accountType{
    [ProgressHUD showError:[NSString stringWithFormat:@"Failed to link %@",accountType]];
}

#pragma mark - Public Profile Delegate
- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didAddFollower:(FluxUserObject *)userObject{
    [(FluxUserObject*)[resultsArray objectAtIndex:selectedIndexPath.row] setAmFollowerFlag:2];
    [addUsersTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if ([delegate respondsToSelector:@selector(AddUserViewController:didFollowUser:)]) {
        [delegate AddUserViewController:self didAddFollower:userObject];
    }
}

- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didremoveFollower:(FluxUserObject *)userObject{
    [(FluxUserObject*)[resultsArray objectAtIndex:selectedIndexPath.row] setAmFollowerFlag:0];
    [addUsersTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if ([delegate respondsToSelector:@selector(AddUserViewController:didUnfollowUser:)]) {
        [delegate AddUserViewController:self didUnfollowUser:userObject];
    }
}

- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didSendFollowerRequest:(FluxUserObject *)userObject{
    [(FluxUserObject*)[resultsArray objectAtIndex:selectedIndexPath.row] setAmFollowerFlag:1];
    [addUsersTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
