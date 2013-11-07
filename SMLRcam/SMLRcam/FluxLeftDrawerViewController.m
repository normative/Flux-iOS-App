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
    [self.navigationController setNavigationBarHidden:YES];
    [self.drawerController setMaximumLeftDrawerWidth:256.0 animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [self.tableView setContentSize:CGSizeMake(self.tableView.contentSize.width, self.tableView.contentSize.height+25)];
}

-(void)viewDidDisappear:(BOOL)animated{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *versionString = [NSString stringWithFormat:@"Version %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [self.versionLbl setText:versionString];
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
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row>0) {
        return 44.0;
    }
    return 94.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"standardCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell.textLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.textLabel.font.pointSize]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    
    //NSString *currentValue = [shareValues objectAtIndex:[indexPath row]];
    //[[cell textLabel]setText:currentValue];
    //return cell;

    switch (indexPath.row)
    {
        case 0:
            {
                NSString *cellIdentifier = @"profileCell";
                UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
                }
                return cell;
            }
            break;
        case 1:
            [cell.textLabel setText:@"Photos"];
            break;
        case 2:
            [cell.textLabel setText:@"Following"];
            break;
        case 3:
            [cell.textLabel setText:@"Followers"];
            break;
        case 4:
            [cell.textLabel setText:@"Settings"];
            break;
    }
    return cell;
}

- (void)        tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
            [self performSegueWithIdentifier:@"pushSettingsSegue" sender:nil];
            break;
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.mm_drawerController setMaximumLeftDrawerWidth:320 animated:YES completion:nil];
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

#pragma IBActions

- (IBAction)onSendFeedBackBtn:(id)sender
{
    [TestFlight openFeedbackViewFromView:self];
    [self.tableView setContentSize:CGSizeMake(self.tableView.contentSize.width, self.tableView.contentSize.height+25)];
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
