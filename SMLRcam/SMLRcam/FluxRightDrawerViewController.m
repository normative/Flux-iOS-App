//
//  FluxRightDrawerViewController.m
//  Flux
//
//  Created by Kei Turner on 2013-08-01.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxRightDrawerViewController.h"
#import "UIViewController+MMDrawerController.h"

#import "FluxFilterDrawerObject.h"

@interface FluxRightDrawerViewController ()

@end

@implementation FluxRightDrawerViewController

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
    FluxFilterDrawerObject *MyNetworkFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"My Network" andtitleImage:[UIImage imageNamed:@"filter_MyNetwork.png"] andActive:YES];
    FluxFilterDrawerObject *PlacesFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"Places" andtitleImage:[UIImage imageNamed:@"filter_Places.png"] andActive:NO];
    FluxFilterDrawerObject *PeopleFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"People" andtitleImage:[UIImage imageNamed:@"filter_People.png"] andActive:NO];
    FluxFilterDrawerObject *ThingsFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"Things" andtitleImage:[UIImage imageNamed:@"filter_Things.png"] andActive:NO];
    FluxFilterDrawerObject *EventsFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"Events" andtitleImage:[UIImage imageNamed:@"filter_Events.png"] andActive:NO];

    rightDrawerTableViewArray = [[NSArray alloc]initWithObjects:MyNetworkFilterObject, PlacesFilterObject, PeopleFilterObject, ThingsFilterObject, EventsFilterObject, nil];
    
    
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
    if (tableView == self.tableView) {
            return 2;
    }
    else
        return 1;

}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (tableView == self.tableView) {
        if (section == 0) {
            return @"Tags Nearby:";
        }
        else{
            return @"Show Only:";
        }
    }
    else
        return @"Search Results";

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (section == 0) {
            return 1;
        }
        // Return the number of rows in the section.
        return [rightDrawerTableViewArray count];
    }
    //its the search tableView
    else
        return 0;

}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            return 94.0;
        }
        else
            return 44.0;
    }
    else
        return 44.0;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //if it's the hash section
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"hashcell";
        FluxHashtagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[FluxHashtagTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        return cell;
    }
    static NSString *CellIdentifier = @"checkCell";
    
    //FluxDrawerCheckboxFilterTableViewCell * cell = [[FluxDrawerCheckboxFilterTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier andWithState:NO];
    
    FluxDrawerCheckboxFilterTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[FluxDrawerCheckboxFilterTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell.checkbox setDelegate:cell];
    [cell setDelegate:self];
    
    
    
    //set the cell properties to the array elements declared above
    cell.descriptorLabel.text = [[rightDrawerTableViewArray objectAtIndex:indexPath.row]title];
    [cell.descriptorIconImageView setImage:[[rightDrawerTableViewArray objectAtIndex:indexPath.row]titleImage]];
    
    [cell setIsActive:[[rightDrawerTableViewArray objectAtIndex:indexPath.row]isChecked]];
    
    return cell;
    

}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

//if the checkbox is selected, the callback comes here. In the method below we check which cell it is and mark the corresponding object as active.
- (void)CheckboxCell:(FluxDrawerCheckboxFilterTableViewCell *)checkCell boxWasChecked:(BOOL)checked{
    for (FluxDrawerCheckboxFilterTableViewCell* cell in [self.tableView visibleCells]) {
        if (cell == checkCell) {
            int index = [self.tableView indexPathForCell:cell].row;
            [[rightDrawerTableViewArray objectAtIndex:index] setIsActive:checked];
        }
    }
}


#pragma mark - UISearchDisplayController Delegate Methods
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    [self.mm_drawerController
     setMaximumRightDrawerWidth:[UIScreen mainScreen].bounds.size.width
     animated:YES
     completion:^(BOOL finished) {
     }];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    [self.mm_drawerController
     setMaximumRightDrawerWidth:250.0
     animated:YES
     completion:^(BOOL finished) {
     }];
    return YES;
}


-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {

    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {

    // Return YES to cause the search result table view to be reloaded.
    return YES;
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
