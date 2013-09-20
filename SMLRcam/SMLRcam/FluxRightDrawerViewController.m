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

@synthesize delegate;

#pragma mark - init methods

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    //make network Call
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    [request setTagsReady:^(NSArray *tagList, FluxDataRequest*completedRequest){
        //do something with array
        topTagsArray = tagList;
        if ([rightDrawerTableViewArray count] == 1) {
            [rightDrawerTableViewArray insertObject:topTagsArray atIndex:0];
        }
        else{
            [rightDrawerTableViewArray replaceObjectAtIndex:0 withObject:topTagsArray];
        }
        [self.tableView reloadData];
    }];
    [self.fluxDataManager requestTagListAtLocation:locationManager.location.coordinate withRadius:20
                                       andMaxCount:20 withDataRequest:request];
    
    
}

- (void)viewWillDisappear:(BOOL)animated{
    //if the user has changed anything related to the filer, send the delegate method to update the view
    if (![dataFilter isEqualToFilter:previousDataFilter]) {
        if ([delegate respondsToSelector:@selector(RightDrawer:didChangeFilter:)]) {
            [delegate RightDrawer:self didChangeFilter:dataFilter];
        }
        previousDataFilter = dataFilter;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    FluxFilterDrawerObject *MyNetworkFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"My Network" andDBTitle:@"1" andtitleImage:[UIImage imageNamed:@"filter_MyNetwork.png"] andActive:YES];
    FluxFilterDrawerObject *PlacesFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"Places" andDBTitle:@"place" andtitleImage:[UIImage imageNamed:@"filter_Places.png"] andActive:YES];
    FluxFilterDrawerObject *PeopleFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"People" andDBTitle:@"person" andtitleImage:[UIImage imageNamed:@"filter_People.png"] andActive:YES];
    FluxFilterDrawerObject *ThingsFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"Things" andDBTitle:@"thing" andtitleImage:[UIImage imageNamed:@"filter_Things.png"] andActive:YES];
    FluxFilterDrawerObject *EventsFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"Events" andDBTitle:@"event" andtitleImage:[UIImage imageNamed:@"filter_Events.png"] andActive:YES];

    contextFiltersArray = [[NSArray alloc]initWithObjects:MyNetworkFilterObject, PeopleFilterObject, PlacesFilterObject, ThingsFilterObject, EventsFilterObject, nil];
    topTagsArray = [[NSMutableArray alloc]init];
    rightDrawerTableViewArray = [[NSMutableArray alloc]initWithObjects:contextFiltersArray, nil];
    
    [self setupLocationManager];
    
    dataFilter = [[FluxDataFilter alloc] init];
    previousDataFilter = [[FluxDataFilter alloc] initWithFilter:dataFilter];
}

- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - network methods



- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnTagList:(NSArray *)tagList{
    topTagsArray = tagList;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        return rightDrawerTableViewArray.count;
    }
    else
        return 1;

}


- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40.0f;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (tableView == self.tableView) {
        if (section == 0) {
            //if there are no "top tags"
            if (rightDrawerTableViewArray.count == 1) {
                return @"Show Only:";
            }
            
            return @"Tags Nearby:";
        }
        else{
            return @"Show Only:";
        }
    }
    else
        return @"Search Results";
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    // Create label with section title
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 20, 100, 23);
    label.textColor = [UIColor lightGrayColor];
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
    if (tableView == self.tableView) {
        if (rightDrawerTableViewArray.count == 1 || section == 1) {
            return [[rightDrawerTableViewArray objectAtIndex:section]count];
        }
        return 1;
        
    }
    //its the search tableView
    else
        return 0;

}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            //if "top tags" is empty
            if (rightDrawerTableViewArray.count == 1) {
                return 44.0;
            }
            FluxHashtagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hashCell"];
            [cell.tagList setTags:[rightDrawerTableViewArray objectAtIndex:indexPath.section]];
            [cell.tagList display];
            return [cell.tagList fittedSize].height+cell.tagList.frame.origin.x-10;
        }
        else
            return 44.0;
    }
    else
        return 44.0;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        //if it's the hash section
        if (rightDrawerTableViewArray.count == 1) {
            static NSString *CellIdentifier = @"checkCell";
            FluxDrawerCheckboxFilterTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                        if (cell == nil) {
                cell = [[FluxDrawerCheckboxFilterTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            [cell.checkbox setDelegate:cell];
            [cell setDelegate:self];
            
            //set the cell properties to the array elements declared above
            [cell setDbTitle:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]dbTitle]];
            cell.descriptorLabel.text = [[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]title];
            [cell.descriptorIconImageView setImage:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]titleImage]];
            [cell setIsActive:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]isChecked]];
            
            return cell;
        }
        else{
            if (indexPath.section == 0) {
                static NSString *CellIdentifier = @"hashCell";
                FluxHashtagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                if (cell == nil) {
                    cell = [[FluxHashtagTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                }
                //        [cell.tagList setTags:[NSArray arrayWithObjects:@"Hello", @"this", @"is", @"a", @"test", @"of", @"theWaythetextfieldlooks", @"with", @"the", @"worst", @"case", @"being", @"this", @"long", nil]];
                [cell.tagList setTags:[rightDrawerTableViewArray objectAtIndex:indexPath.section]];
                [cell.tagList setTagDelegate:self];
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
            [cell setDbTitle:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]dbTitle]];
            cell.descriptorLabel.text = [[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]title];
            [cell.descriptorIconImageView setImage:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]titleImage]];
            [cell setIsActive:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]isChecked]];
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark Cell Subview Delegates

//if the checkbox is selected, the callback comes here. In the method below we check which cell it is and mark the corresponding object as active.
- (void)CheckboxCell:(FluxDrawerCheckboxFilterTableViewCell *)checkCell boxWasChecked:(BOOL)checked{
    if (checked) {
        [dataFilter addCategoryToFilter:checkCell.dbTitle];
    }
    else{
        [dataFilter removeCategoryFromFilter:checkCell.dbTitle];
    }
    //update the cell
    for (FluxDrawerCheckboxFilterTableViewCell* cell in [self.tableView visibleCells]) {
        if (cell == checkCell) {
            NSIndexPath *path = [self.tableView indexPathForCell:cell];
            [[[rightDrawerTableViewArray objectAtIndex:path.section]objectAtIndex:path.row] setIsActive:checked];
        }
    }
}

- (void)tagList:(DWTagList *)list selectedTagWithTitle:(NSString *)title andActive:(BOOL)active{
    
    if (active) {
        [dataFilter addHashTagToFilter:title];
    }
    else{
        [dataFilter removeHashTagFromFilter:title];
    }
}


#pragma mark - UISearchDisplayController Delegate Methods
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    [self.mm_drawerController
     setMaximumRightDrawerWidth:[UIScreen mainScreen].bounds.size.width
     animated:YES
     completion:^(BOOL finished) {
     }];
    //[self.tableView reloadData];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    [self.mm_drawerController
     setMaximumRightDrawerWidth:256.0
     animated:YES
     completion:^(BOOL finished) {
     }];
    //[self.tableView reloadData];
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

@end
