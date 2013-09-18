//
//  FluxLeftDrawerViewController.m
//  Flux
//
//  Created by Kei Turner on 2013-08-01.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxLeftDrawerViewController.h"
#import "TestFlight.h"
#import "TestFlight+OpenFeedback.h"

@interface FluxLeftDrawerViewController ()

@end

@implementation FluxLeftDrawerViewController

#pragma mark - delegate methods

//callback made when the switch on the cell is hit
-(void)SwitchCell:(FluxDrawerSwitchTableViewCell *)switchCell
  switchWasTapped:(UISwitch *)theSwitch
{
    //gets a reference to the cell hit
    [self SettingActionForString:[NSString stringWithFormat:@"%@",[leftDrawerTableViewArray objectAtIndex:[self.tableView indexPathForCell:switchCell].row]]
                      andSetting:theSwitch.on];
}

// callback made when the segmented control was tapped
- (void)    SegmentedCell:(FluxDrawerSegmentedTableViewCell *)segmentedCell
segmentedControlWasTapped:(UISegmentedControl *)segmented
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:segmented.selectedSegmentIndex] forKey:@"Server Location"];
    [defaults synchronize];
}

// callback made when the button was tapped
- (void)ButtonCell:(FluxDrawerButtonTableViewCell *)buttonCell
   buttonWasTapped:(UIButton *)theButton
{
}

#pragma mark - view lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    leftDrawerTableViewArray = [[NSArray alloc]initWithObjects:@"Save Pictures",@"Network Services",@"Local Network", @"Walk Mode", @"Area Reset", nil];
    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"leftDrawerHeaderView"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:image];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Settings";
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    // Create label with section title
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 0, 100, 23);
    label.textColor = [UIColor whiteColor];
    [label setFont:[UIFont fontWithName:@"Akkurat" size:14]];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.backgroundColor = [UIColor clearColor];
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    [view setBackgroundColor:[UIColor clearColor]];
    [view addSubview:label];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return leftDrawerTableViewArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.row <2) || (indexPath.row == 3))
    {
        static NSString *CellIdentifier = @"switchCell";
        FluxDrawerSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
        
        if (cell == nil)
        {
            cell = [[FluxDrawerSwitchTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        [cell setDelegate:self];
        // Configure the cell
        cell.theLabel.text = [leftDrawerTableViewArray objectAtIndex:indexPath.row];
        cell.theSwitch.on = [[self GetSettingForString:[leftDrawerTableViewArray objectAtIndex:indexPath.row]] boolValue];
        
        return cell;
    }
    else if (indexPath.row == 2)
    {
        static NSString *CellIdentifier = @"segmentedCell";
        FluxDrawerSegmentedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
        
        if (cell == nil) {
            cell = [[FluxDrawerSegmentedTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [cell setDelegate:self];
        // Configure the cell
        //switch is set to local by default
        cell.segmentedControl.selectedSegmentIndex = [[self GetSettingForString:@"Server Location"]intValue];
        
        return cell;
    }
    else
    {
        // nuke button
        static NSString *CellIdentifier = @"buttonCell";
        FluxDrawerButtonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
        
        if (cell == nil) {
            cell = [[FluxDrawerButtonTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [cell setDelegate:self];
        // Configure the cell
        cell.theLabel.text = [leftDrawerTableViewArray objectAtIndex:indexPath.row];

        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}



//temporary, ugly, not really extensible code.
//sets settings based on string
- (IBAction)submitFeedbackAction:(id)sender {
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

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)SettingActionForString:(NSString *)string andSetting:(BOOL)setting
{
    if ([string isEqualToString:@"Save Pictures"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithBool:setting] forKey:string];
        [defaults synchronize];
    }
    
    if ([string isEqualToString:@"Network Services"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithBool:setting] forKey:string];
        [defaults synchronize];
    }

    if ([string isEqualToString:@"Walk Mode"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithBool:setting] forKey:string];
        [defaults synchronize];
    }
}

//temporary, ugly, not really extensible code.
//sets the settings based on string
- (NSNumber*)GetSettingForString:(NSString*)string{
    if ([string isEqualToString:@"Save Pictures"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        return [defaults objectForKey:@"Save Pictures"];
    }
    else if ([string isEqualToString:@"Network Services"]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        return [defaults objectForKey:@"Network Services"];
    }
    else if ([string isEqualToString:@"Server Location"]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        return [defaults objectForKey:@"Server Location"];
    }
    else if ([string isEqualToString:@"Walk Mode"]){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        return [defaults objectForKey:@"Walk Mode"];
    }
    else{
        return nil;
    }
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

@end
