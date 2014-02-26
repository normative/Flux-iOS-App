//
//  FluxPublicProfileViewController.m
//  Flux
//
//  Created by Kei Turner on 11/27/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxPublicProfileViewController.h"
#import "UIImageView+AFNetworking.h"
#import "FluxCountTableViewCell.h"
#import "UICKeyChainStore.h"
#import "ProgressHUD.h"

#define isiPhone5  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE

@interface FluxPublicProfileViewController ()

@end

@implementation FluxPublicProfileViewController

@synthesize delegate;

#pragma mark - View Init

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //[self.navigationController.navigationBar setTitleVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.screenName = @"Public Profile View";
}

- (void)viewDidLoad
{
    [self setTitle:@"Info"];
    [super viewDidLoad];
}

- (void)prepareViewWithUser:(FluxUserObject*)user{
    theUser = user;
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    [request setUserReady:^(FluxUserObject*userObject, FluxDataRequest*completedRequest){
        theUser = userObject;
        if (user.profilePic) {
            theUser.profilePic = user.profilePic;
        }
        [profileTableView reloadData];
    }];
    [self.fluxDataManager requestUserProfileForID:user.userID withDataRequest:request];
//    self.title = [NSString stringWithFormat:@"@%@",user.username];
}

#pragma mark - TableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 600.0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier;
    if (isiPhone5)
    {
        cellIdentifier = @"publicProfileCell";
    }
    else
    {
        cellIdentifier = @"publicProfileCellSmall";
    }
    
    FluxPublicProfileCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxPublicProfileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell setDelegate:self];
    [cell initCell];

    //disable the profile button for now
    [cell.profielImageButton setUserInteractionEnabled:NO];
    [cell setUserObject:theUser];
    
    if (theUser.hasProfilePic) {
        if (theUser.profilePic) {
            [cell.profielImageButton setBackgroundImage:theUser.profilePic forState:UIControlStateNormal];
        }
        else{
            __weak FluxPublicProfileCell *weakCell = cell;
            NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
            NSString*urlString = [NSString stringWithFormat:@"%@users/%i/avatar?size=%@&auth_token=%@",FluxServerURL,theUser.userID,@"thumb", token];
            [cell.profielImageButton.imageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]]
                                                     placeholderImage:[UIImage imageNamed:@"emptyProfileImage_big"]
                                                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                                                  if (image) {
                                                                      //[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] replaceObjectAtIndex:indexPath.row withObject:image];
                                                                      [weakCell.profielImageButton setBackgroundImage:image forState:UIControlStateNormal];
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
    }
    
    return cell;
}

- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldSendFriendRequestToUser:(FluxUserObject*)userObject{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setSendFriendRequestReady:^(int userID, FluxDataRequest*completedRequest){
        //do something with the UserID
        NSLog(@"friend request sent");
        theUser.friendState = 2;
        [profileTableView reloadData];
        
        
        if ([delegate respondsToSelector:@selector(PublicProfile:didSendFriendRequest:)]) {
            [delegate PublicProfile:self didSendFriendRequest:theUser];
        }
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Friend request failed with error %d", (int)[e code]];
        [ProgressHUD showError:str];
        
    }];
    [self.fluxDataManager sendFriendRequestToUserWithID:userObject.userID withDataRequest:request];
}
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldAcceptFriendRequestToUser:(FluxUserObject*)userObject{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setAcceptFriendRequestReady:^(int newFriendUserID, FluxDataRequest*completedRequest){
        //do something with the UserID
        NSLog(@"friended");
        theUser.friendState = 3;
        [profileTableView reloadData];
        
        if ([delegate respondsToSelector:@selector(PublicProfile:didAddFriend:)]) {
            [delegate PublicProfile:self didAddFriend:theUser];
        }
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Accepting the friend request failed with error %d", (int)[e code]];
        [ProgressHUD showError:str];
        
    }];
    [self.fluxDataManager acceptFriendRequestFromUserWithID:userObject.userID withDataRequest:request];
}
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldUnfriendUser:(FluxUserObject*)userObject{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setUnfriendUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
        //do something with the UserID
        NSLog(@"unfriended");
        theUser.friendState = 0;
        [profileTableView reloadData];
        
        if ([delegate respondsToSelector:@selector(PublicProfile:didRemoveFriend:)]) {
            [delegate PublicProfile:self didRemoveFriend:theUser];
        }
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Unfriending %@ failed with error %d",userObject.username, (int)[e code]];
        [ProgressHUD showError:str];
        
    }];
    [self.fluxDataManager unfriendWithUserID:userObject.userID withDataRequest:request];
}
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldFollowUser:(FluxUserObject*)userObject{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setFollowUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
        //do something with the UserID
        NSLog(@"Followed");
        theUser.isFollowing = YES;
        [profileTableView reloadData];
        
        if ([delegate respondsToSelector:@selector(PublicProfile:didAddFollower:)]) {
            [delegate PublicProfile:self didAddFollower:theUser];
        }
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Following %@ failed with error %d", userObject.username, (int)[e code]];
        [ProgressHUD showError:str];
        
    }];
    [self.fluxDataManager addFollowerWithUserID:userObject.userID withDataRequest:request];
}
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldUnfollowUser:(FluxUserObject*)userObject{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setUnfollowUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
        //do something with the UserID
        NSLog(@"unfollowed");
        theUser.isFollowing = NO;
        [profileTableView reloadData];
        
        if ([delegate respondsToSelector:@selector(PublicProfile:didremoveFollower:)]) {
            [delegate PublicProfile:self didremoveFollower:theUser];
        }
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Unfollowing %@ failed with error %d",userObject.username, (int)[e code]];
        [ProgressHUD showError:str];
        
    }];
    [self.fluxDataManager unfollowUserWIthID:userObject.userID withDataRequest:request];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IB Actions

@end
