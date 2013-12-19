//
//  FluxPublicProfileViewController.m
//  Flux
//
//  Created by Kei Turner on 11/27/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxPublicProfileViewController.h"

#import "FluxCountTableViewCell.h"
#import "FluxProfileCell.h"

@interface FluxPublicProfileViewController ()

@end

@implementation FluxPublicProfileViewController

#pragma mark - View Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES];

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
        [profileTableView reloadData];
        if (theUser.hasProfilePic) {
            FluxDataRequest*picRequest = [[FluxDataRequest alloc]init];
            [picRequest setUserPicReady:^(UIImage*img, int userID, FluxDataRequest*completedRequest){
                [profileTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }];
            [self.fluxDataManager requestUserProfilePicForID:user.userID andSize:@"" withDataRequest:picRequest];
        }
    }];
    
    [self.fluxDataManager requestUserProfileForID:user.userID withDataRequest:request];
}

#pragma mark - TableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return 120.0;
    }
    else{
        return 44.0;
    }
}

- (float)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 150.0;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView*footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self tableView:tableView heightForFooterInSection:section])];
    socialStatusLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 20, 250.0, 15.0)];
    [socialStatusLabel setCenter:CGPointMake(footerView.center.x, socialStatusLabel.center.y)];
    [socialStatusLabel setFont:[UIFont fontWithName:@"Akkurat" size:13.0]];
    [socialStatusLabel setTextColor:[UIColor colorWithRed:44/255.0 green:53/255.0 blue:59/255.0 alpha:1.0]];
    [socialStatusLabel setBackgroundColor:[UIColor clearColor]];
    [socialStatusLabel setText:(theUser.isFollower) ? [NSString stringWithFormat:@"%@ is following you",theUser.username] : [NSString stringWithFormat:@"%@ is not following you",theUser.username]];
    [socialStatusLabel setTextAlignment:NSTextAlignmentCenter];
    [footerView addSubview:socialStatusLabel];
    
    followButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 57, 30)];
    [followButton setTitle:(theUser.isFollowing) ? @"Unfollow" : @"Follow" forState:UIControlStateNormal];
    [followButton setCenter:CGPointMake(socialStatusLabel.center.x, socialStatusLabel.center.y+(socialStatusLabel.frame.size.height/2)+15+15)];
    addFriendButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
    [addFriendButton setTitle:(theUser.isFriends) ? @"Friends" : @"Add Friend" forState:UIControlStateNormal];
    [addFriendButton setCenter:CGPointMake(socialStatusLabel.center.x, followButton.center.y+(followButton.frame.size.height/2)+15+15)];
    followButton.titleLabel.font = addFriendButton.titleLabel.font = [UIFont fontWithName:@"Akkurat-Bold" size:addFriendButton.titleLabel.font.pointSize];
    [addFriendButton addTarget:self action:@selector(addFriendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [followButton addTarget:self action:@selector(followButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    [footerView addSubview:followButton];
    [footerView addSubview:addFriendButton];
    
    UIView*separator = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0.5)];
    [separator setBackgroundColor:[UIColor colorWithRed:101/255.0 green:108/255.0 blue:112/255.0 alpha:0.7]];
    [footerView addSubview:separator];

    
    return footerView;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        static NSString *cellIdentifier = @"profileDetailsCell";
        FluxProfileCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[FluxProfileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        //HACK
        [cell.bioLabel setText:theUser.bio];
        [cell.usernameLabel setText:theUser.username];
        [cell.profileImageButton setBackgroundImage:(theUser.profilePic) ? theUser.profilePic : [UIImage imageNamed:@"profileImage"] forState:UIControlStateNormal];
        [cell.imageCountLabel setText:[NSString stringWithFormat:@"%i",theUser.imageCount]];
        [cell initCellisEditing:NO];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    }
    else if (indexPath.row == 1){
        static NSString *cellIdentifier = @"publicProfileNumberCell";
        FluxCountTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[FluxCountTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        [cell initCell];
        [cell.titleLabel setText:@"Following"];
        [cell.countLabel setText:[NSString stringWithFormat:@"%i",theUser.followingCount]];
        
        [cell.titleLabel setEnabled:NO];
        [cell.countLabel setEnabled:NO];
        return cell;
    }
    else{
        static NSString *cellIdentifier = @"publicProfileNumberCell";
        FluxCountTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[FluxCountTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        [cell initCell];
        [cell.titleLabel setText:@"Followers"];
        [cell.countLabel setText:[NSString stringWithFormat:@"%i",theUser.followerCount]];
        
        [cell.titleLabel setEnabled:NO];
        [cell.countLabel setEnabled:NO];
        return cell;
    }

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

- (void)followButtonAction {
}

- (void)addFriendButtonAction {
}
@end
