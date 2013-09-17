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
        NSLog(@"Returned %i tags to the right Drawer",tagList.count);
    }];
    [self.fluxDataManager requestTagListAtLocation:locationManager.location.coordinate withRadius:20 withFilter:nil andMaxCount:20 withDataRequest:request];
    [self.tableView reloadData];
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
    
    [self setupLocationManager];
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
            return 2;
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
            return 156.0;
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
        static NSString *CellIdentifier = @"hashCell";
        FluxHashtagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[FluxHashtagTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        //use this to put a loading activity view in place of the tag list
//        if (topTagsArray == nil) {
//            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(cell.contentView.frame.size.width/2-25, cell.contentView.frame.size.height/2-25, 50, 50)];
//            [activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
//            [activityView setCenter:cell.contentView.center];
//            [activityView startAnimating];
//            [cell.contentView addSubview:activityView];
//            return cell;
//        }
        [cell.tagList setTags:[NSArray arrayWithObjects:@"Hello", @"this", @"is", @"a", @"test", @"of", @"theWaythetextfieldlooks", @"with", @"the", @"worst", @"case", @"being", @"this", @"long", nil]];
        //[tagList setTags:topTagsArray];
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
    cell.descriptorLabel.text = [[rightDrawerTableViewArray objectAtIndex:indexPath.row]title];
    [cell.descriptorIconImageView setImage:[[rightDrawerTableViewArray objectAtIndex:indexPath.row]titleImage]];
    
    [cell setIsActive:[[rightDrawerTableViewArray objectAtIndex:indexPath.row]isChecked]];
    
    return cell;
    

}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark Cell Subview Delegates

//if the checkbox is selected, the callback comes here. In the method below we check which cell it is and mark the corresponding object as active.
- (void)CheckboxCell:(FluxDrawerCheckboxFilterTableViewCell *)checkCell boxWasChecked:(BOOL)checked{
    for (FluxDrawerCheckboxFilterTableViewCell* cell in [self.tableView visibleCells]) {
        if (cell == checkCell) {
            int index = [self.tableView indexPathForCell:cell].row;
            [[rightDrawerTableViewArray objectAtIndex:index] setIsActive:checked];
        }
    }
}

- (void)tagList:(DWTagList *)list selectedTagWithTitle:(NSString *)title{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
                                                    message:[NSString stringWithFormat:@"You tapped tag %@", title]
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
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
