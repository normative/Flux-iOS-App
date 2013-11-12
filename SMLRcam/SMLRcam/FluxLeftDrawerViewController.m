//
//  FluxLeftDrawerViewController.m
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxLeftDrawerViewController.h"
#import "TestFlight.h"
#import "TestFlight+OpenFeedback.h"
#import "UIViewController+MMDrawerController.h"
#import "FluxLeftMenuCell.h"
#import "UICKeyChainStore.h"

#import "FluxSettingsViewController.h"

@interface FluxLeftDrawerViewController ()

@end

@implementation FluxLeftDrawerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.drawerController setMaximumLeftDrawerWidth:256.0 animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableDictionary*tmp1 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Photos" , nil];
    NSMutableDictionary*tmp2 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Following" , nil];
    NSMutableDictionary*tmp3 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Followers" , nil];
    NSMutableDictionary*tmp4 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Friends" , nil];
    NSMutableDictionary*tmp5 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Settings" , nil];
    tableViewArray = [[NSMutableArray alloc]initWithObjects:tmp1, tmp2, tmp3, tmp4, tmp5, nil];
    
    NSString *versionString = [NSString stringWithFormat:@"Version %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [self.versionLbl setText:versionString];
    
    [self.navigationController setNeedsStatusBarAppearanceUpdate];
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
    return tableViewArray.count+1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row>0) {
        return 44.0;
    }
    return 94.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"standardLeftCell";
    FluxLeftMenuCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxLeftMenuCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell initCell];
    if (indexPath.row == 0) {
        NSString *username = [UICKeyChainStore stringForKey:@"username" service:@"com.flux"];
        
        NSString *cellIdentifier = @"profileCell";
        UITableViewCell * profileCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!profileCell) {
            profileCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        return profileCell;
    }
    else if (indexPath.row == tableViewArray.count){
        cell.titleLabel.text = (NSString*)[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject];
        cell.countLabel.text = @"";
    }
    else{
        cell.titleLabel.text = (NSString*)[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject];
        cell.countLabel.text = [NSString stringWithFormat:@"%i",[(NSNumber*)[[tableViewArray objectAtIndex:indexPath.row-1]objectForKey:[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject]]intValue]];
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0:
            //[self performSegueWithIdentifier:@"pushPhotosSegue" sender:nil];
            break;
        case 1:
            [self performSegueWithIdentifier:@"pushPhotosSegue" sender:nil];
            break;
        case 2:
            //[self performSegueWithIdentifier:@"pushSettingsSegue" sender:nil];
            break;
        case 3:
            //[self performSegueWithIdentifier:@"pushSettingsSegue" sender:nil];
            break;
        case 4:
            //[self performSegueWithIdentifier:@"pushSettingsSegue" sender:nil];
            break;
        case 5:
            [self performSegueWithIdentifier:@"pushSettingsSegue" sender:nil];
            break;
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.mm_drawerController setMaximumLeftDrawerWidth:320 animated:YES completion:nil];
}

#pragma IBActions

- (IBAction)onSendFeedBackBtn:(id)sender
{
    [TestFlight openFeedbackViewFromView:self];
}

#pragma mark - delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pushSettingsSegue"])
    {
        FluxSettingsViewController* leftDrawerSettingsViewController = (FluxSettingsViewController*)segue.destinationViewController;
        leftDrawerSettingsViewController.fluxDataManager = self.fluxDataManager;
    }
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    NSLog(@"%f", scrollView.contentOffset.y);
//}
//
//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
//{
//    CGSize tableViewScrollSize = self.tableView.contentSize;
//    
//    if ((scrollView.contentOffset.y >= 100) && (tableViewScrollSize.height == self.view.bounds.size.height))
//    {
//        self.tableView.contentSize = CGSizeMake(tableViewScrollSize.width, 150 + tableViewScrollSize.height);
//    }
//    else if ((scrollView.contentOffset.y < 100) && (tableViewScrollSize.height > self.view.bounds.size.height))
//    {
//        self.tableView.contentSize = CGSizeMake(tableViewScrollSize.width, self.view.bounds.size.height);
//    }
//}

@end
