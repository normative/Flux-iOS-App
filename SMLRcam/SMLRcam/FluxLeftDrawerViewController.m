//
//  FluxLeftDrawerViewController.m
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 Normative. All rights reserved.
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

    [self.drawerController setMaximumLeftDrawerWidth:256.0 animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [self.tableView setContentSize:CGSizeMake(self.tableView.contentSize.width, self.tableView.contentSize.height+75)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    CGRect frame = CGRectMake(0,161, 256, 100);
//    UIView *copyRightView = [[UIView alloc]initWithFrame:frame];
//    [copyRightView setBackgroundColor:[UIColor redColor]];
//    [self.view addSubview:copyRightView];
//    [self.view sendSubviewToBack:copyRightView];

    
    // Set Profile Image on Imageview
    [self.profileImageView setImage:[UIImage imageNamed:@"profileImage"]];
    
    // Set Username on label
    NSString *username = @"@Dan_Fielding";
    [self.profileUsernameLbl setText:username];
    
    // Set Number of Post on label
    [self.profileNumberOfPostLbl setFont:[UIFont fontWithName:@"Akkurat" size:12]];
    [self.profileNumberOfPostLbl setText:[NSString stringWithFormat:@"%i Posts", 150]];
    
    // Set Member since date on label
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yy"];
    NSString *dateInString = [dateFormatter stringFromDate:[NSDate date]];
    [self.profileJoinedDateLbl setFont:[UIFont fontWithName:@"Akkurat" size:12]];
    [self.profileJoinedDateLbl setText:[NSString stringWithFormat:@"Member since %@", dateInString]];
    
    NSString *versionString = [NSString stringWithFormat:@"Version %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [self.versionLbl setText:versionString];
    
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:31.0/255.0 green:33/255.0 blue:36.0/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
    [self setTitle:@"Flux"];
    
    [self.view needsUpdateConstraints];
}
//
//- (CGSize)preferredContentSize
//{
//    [self.tableView setFrame:CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height +150)];
//    // Force the table view to calculate its height
//    [self.tableView layoutIfNeeded];
//    return self.tableView.contentSize;
//}

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
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (indexPath.row)
    {
        case 0:
            break;
        case 1:
            break;
        case 2:
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
            [self performSegueWithIdentifier:@"pushPhotosSegue" sender:nil];
            break;
        case 1:
            break;
        case 2:
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
    //    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    //    mailViewController.mailComposeDelegate = self;
    //    [mailViewController setSubject:@"Feedback"];
    //    [mailViewController setMessageBody:@"Your message goes here." isHTML:NO];
    //    [mailViewController setToRecipients:[NSArray arrayWithObject:@"dfe73560a31f1d628cc10f1e614bbe5e_ijkustcefu3dmnzqgq2da@n.testflightapp.com"]];
    //
    //    [mailViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    //    [self presentViewController:mailViewController animated:YES completion:nil];
    [TestFlight openFeedbackView];
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

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
