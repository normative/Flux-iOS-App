//
//  FluxLeftDrawerViewController.m
//  Flux
//
//  Created by Kei Turner on 2013-08-01.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxLeftDrawerViewController.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    leftDrawerTableViewArray = [[NSArray alloc]initWithObjects:@"Save Pictures", nil];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return leftDrawerTableViewArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"buttonCell";
    FluxDrawerSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
    
    if (cell == nil) {
        cell = [[FluxDrawerSwitchTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setDelegate:self];
    // Configure the cell...
    cell.theLabel.text = [leftDrawerTableViewArray objectAtIndex:indexPath.row];
    cell.theSwitch.on = [[self GetSettingForString:[leftDrawerTableViewArray objectAtIndex:indexPath.row]] boolValue];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//callback made when the switch on the cell is hit
-(void)SwitchCell:(FluxDrawerSwitchTableViewCell *)switchCell switchWasTapped:(UISwitch *)theSwitch{
    //gets a reference to the cell hit
    [self SettingActionForString:[NSString stringWithFormat:@"%@",[leftDrawerTableViewArray objectAtIndex:[self.tableView indexPathForCell:switchCell].row]] andSetting:theSwitch.on];
}

//temporary, ugly, not really extensible code.
//sets settings based on string
- (void)SettingActionForString:(NSString *)string andSetting:(BOOL)setting{
    if ([string isEqualToString:@"Save Pictures"]) {
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
