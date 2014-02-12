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

@interface FluxPublicProfileViewController ()

@end

@implementation FluxPublicProfileViewController

#pragma mark - View Init

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

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
    self.title = [NSString stringWithFormat:@"@%@",user.username];
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

//- (float)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
//    return 150.0;
//}

//- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
//    UIView*footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tableView heightForFooterInSection:section])];
//    socialStatusLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 20, 250.0, 15.0)];
//    [socialStatusLabel setCenter:CGPointMake(footerView.center.x, socialStatusLabel.center.y)];
//    [socialStatusLabel setFont:[UIFont fontWithName:@"Akkurat" size:13.0]];
//    [socialStatusLabel setTextColor:[UIColor colorWithRed:44/255.0 green:53/255.0 blue:59/255.0 alpha:1.0]];
//    [socialStatusLabel setBackgroundColor:[UIColor clearColor]];
//    [socialStatusLabel setText:(theUser.isFollower) ? [NSString stringWithFormat:@"%@ is following you",theUser.username] : [NSString stringWithFormat:@"%@ is not following you",theUser.username]];
//    [socialStatusLabel setTextAlignment:NSTextAlignmentCenter];
//    [footerView addSubview:socialStatusLabel];
//    
//    followButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 57, 30)];
//    [followButton setTitle:(theUser.isFollowing) ? @"Unfollow" : @"Follow" forState:UIControlStateNormal];
//    [followButton setCenter:CGPointMake(socialStatusLabel.center.x, socialStatusLabel.center.y+(socialStatusLabel.frame.size.height/2)+15+15)];
//    addFriendButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
////    [addFriendButton setTitle:(theUser.isFriends) ? @"Friends" : @"Add Friend" forState:UIControlStateNormal];
//    [addFriendButton setCenter:CGPointMake(socialStatusLabel.center.x, followButton.center.y+(followButton.frame.size.height/2)+15+15)];
//    followButton.titleLabel.font = addFriendButton.titleLabel.font = [UIFont fontWithName:@"Akkurat-Bold" size:addFriendButton.titleLabel.font.pointSize];
//    [addFriendButton addTarget:self action:@selector(addFriendButtonAction) forControlEvents:UIControlEventTouchUpInside];
//    [followButton addTarget:self action:@selector(followButtonAction) forControlEvents:UIControlEventTouchUpInside];
//    
//    [footerView addSubview:followButton];
//    [footerView addSubview:addFriendButton];
//    
//    UIView*separator = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0.5)];
//    [separator setBackgroundColor:[UIColor colorWithRed:101/255.0 green:108/255.0 blue:112/255.0 alpha:0.7]];
//    [footerView addSubview:separator];
//
//    
//    return footerView;
//}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier;
    if (theUser.bio) {
        cellIdentifier = @"publicProfileCell";
    }
    else{
        cellIdentifier = @"publicProfileCellNoBio";
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
            NSString*urlString = [NSString stringWithFormat:@"%@users/%i/avatar?size=%@&auth_token=%@",FluxTestServerURL,theUser.userID,@"thumb", token];
            [cell.profielImageButton.imageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]]
                                                     placeholderImage:[UIImage imageNamed:@"emptyProfileImage_big"]
                                                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                                                  //[[(NSMutableArray*)socialListImagesArray objectAtIndex:listMode] replaceObjectAtIndex:indexPath.row withObject:image];
                                                                  [weakCell.profielImageButton setBackgroundImage:image forState:UIControlStateNormal];
                                                                  //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                                                  //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                                                  [weakCell setNeedsLayout];
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
    
}
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldAcceptFriendRequestToUser:(FluxUserObject*)userObject{
    
}
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldUnfriendUser:(FluxUserObject*)userObject{
    
}
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldFollowUser:(FluxUserObject*)userObject{
    
}
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldUnfollowUser:(FluxUserObject*)userObject{
    
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
