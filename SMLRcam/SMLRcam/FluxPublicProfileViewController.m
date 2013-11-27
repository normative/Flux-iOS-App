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
}


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
    [socialStatusLabel setText:@"CmdrTaco is not following you"];
    [socialStatusLabel setTextAlignment:NSTextAlignmentCenter];
    [footerView addSubview:socialStatusLabel];
    
    followButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 57, 30)];
    [followButton setTitle:@"Follow" forState:UIControlStateNormal];
    [followButton setCenter:CGPointMake(socialStatusLabel.center.x, socialStatusLabel.center.y+(socialStatusLabel.frame.size.height/2)+15+15)];
    addFriendButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
    [addFriendButton setTitle:@"Add Friend" forState:UIControlStateNormal];
    [addFriendButton setCenter:CGPointMake(socialStatusLabel.center.x, followButton.center.y+(followButton.frame.size.height/2)+15+15)];
    followButton.titleLabel.font = addFriendButton.titleLabel.font = [UIFont fontWithName:@"Akkurat-Bold" size:addFriendButton.titleLabel.font.pointSize];
    [addFriendButton addTarget:self action:@selector(addFriendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [followButton addTarget:self action:@selector(followButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    [footerView addSubview:followButton];
    [footerView addSubview:addFriendButton];
    
    UIView*separator = [[UIView alloc]initWithFrame:CGRectMake(0, 1, self.view.frame.size.width, 0.5)];
    [separator setBackgroundColor:[UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7]];
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
        [cell.bioLabel setText:@"CmdrTaco basically runs the internet. This is a short bio about how awesome he is."];
        [cell.usernameLabel setText:@"CmdrTaco"];
        [cell.profileImageView setImage:[UIImage imageNamed:@"profileImage"]];
        [cell initCell];
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
        [cell.countLabel setText:@"117"];
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
        [cell.countLabel setText:@"23"];
        return cell;
    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)followButtonAction {
}

- (void)addFriendButtonAction {
}
@end
