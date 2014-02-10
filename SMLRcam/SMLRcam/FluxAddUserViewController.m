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
    [userSearchBar becomeFirstResponder];
    
    searchState = searched;
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
    return 60.0;
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
    
    
    
    [cell setDelegate:self];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"tapped cell with userID %@",[(FluxUserObject*)[resultsArray objectAtIndex:indexPath.row] username]);
}

#pragma mark - ScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [userSearchBar resignFirstResponder];
}

#pragma mark - Social Cell Delegate
- (void)FriendFollowerCellButtonWasTapped:(FluxFriendFollowerCell *)friendFollowerCell{
    int index = [addUsersTableView indexPathForCell:friendFollowerCell].row;
    
    [UIActionSheet showInView:self.view
                    withTitle:nil
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:nil
            otherButtonTitles:@[@"Send Friend Request", @"Follow"]
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             //link facebook
                             if (buttonIndex == 0) {
                                 NSLog(@"Friend");
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 
                                 [request setSendFriendRequestReady:^(int userID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"friended");
                                     //[addUsersTableView reloadData];
                                 }];
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Adding a follower failed with error %d", (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager sendFriendRequestToUserWithID:[(FluxUserObject*)[resultsArray objectAtIndex:index]userID] withDataRequest:request];
                             }
                             else{
                                 NSLog(@"follow");
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 
                                 [request setFollowUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"Followed");
                                     //[addUsersTableView reloadData];
                                 }];
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Adding a follower failed with error %d", (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager addFollowerWithUserID:[(FluxUserObject*)[resultsArray objectAtIndex:index]userID] withDataRequest:request];
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
            
            NSString*str = [NSString stringWithFormat:@"Followers failed to load with error %d", (int)[e code]];
            [ProgressHUD showError:str];
            
        }];
        [self.fluxDataManager requestUsersListQuery:searchQuery withDataRequest:request];
    }
}



- (IBAction)doneButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
