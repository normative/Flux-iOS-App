//
//  FluxFiltersTableViewController.m
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxFiltersViewController.h"
#import "FluxFilterDrawerObject.h"

#import "FluxImageTools.h"
#import "ProgressHUD.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@interface FluxFiltersViewController ()

@end

@implementation FluxFiltersViewController

@synthesize delegate, imageCount;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLocationManager];
    
    if (dataFilter == nil) {
        dataFilter = [[FluxDataFilter alloc] init];
    }
    FluxImageTools*imageTools = [[FluxImageTools alloc]init];
    
    [self.backgroundImageView setImage:[imageTools blurImage:bgImage withBlurLevel:0.6]];
    UIView*darkenedView = [[UIView alloc]initWithFrame:self.backgroundImageView.bounds];
    [darkenedView setBackgroundColor:[UIColor colorWithRed:47/255.0 green:47/255.0 blue:47/255.0 alpha:0.8]];
    [self.backgroundImageView addSubview:darkenedView];

    

    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    
    //[self.filterTableView addGestureRecognizer:tapGesture];
    self.screenName = @"Filters View";
}



- (void)viewWillAppear:(BOOL)animated{
    //google analytics
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Filters View"];
    // manual screen tracking
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    [self sendTagRequest];
}

//must be called from presenting VC
- (void)prepareViewWithFilter:(FluxDataFilter*)theDataFilter andInitialCount:(int)count{
    FluxFilterDrawerObject *myPicsFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"My Photos" andDBTitle:@"myPhotos" andtitleImage:[UIImage imageNamed:@"filter_MyNetwork.png"] andActive:[theDataFilter containsCategory:@"myPhotos"]];
    FluxFilterDrawerObject *followingFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"Following" andDBTitle:@"following" andtitleImage:[UIImage imageNamed:@"filter_People.png"] andActive:[theDataFilter containsCategory:@"following"]];
    FluxFilterDrawerObject *favouritesFilterObject = [[FluxFilterDrawerObject alloc]initWithTitle:@"Friends" andDBTitle:@"favorites" andtitleImage:[UIImage imageNamed:@"filter_Places.png"] andActive:[theDataFilter containsCategory:@"favorites"]];
    
    if ([theDataFilter isEqualToFilter:[[FluxDataFilter alloc]init]]) {
        startImageCount = count;
    }
    imageCount = [NSNumber numberWithInt:count];
    self.radius = 15;
    
    socialFiltersArray = [[NSArray alloc]initWithObjects:myPicsFilterObject, followingFilterObject, favouritesFilterObject, nil];
    topTagsArray = [[NSMutableArray alloc]init];
    if ([theDataFilter.hashTags isEqualToString:@""]) {
        selectedTags = [[NSMutableArray alloc]init];
    }
    else{
        selectedTags = [[theDataFilter.hashTags componentsSeparatedByString:@"%20"]mutableCopy];
    }

    rightDrawerTableViewArray = [[NSMutableArray alloc]initWithObjects:socialFiltersArray,topTagsArray, nil];
    
    dataFilter = [theDataFilter copy];
    [self.filterTableView reloadData];
}

- (void)setBackgroundView:(UIImage*)image{
    bgImage = image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
}

#pragma mark - network methods
- (void)sendTagRequest{
    // viewController is visible
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    FluxDataFilter*tmp = [[FluxDataFilter alloc] initWithFilter:dataFilter];
    [tmp setHashTags:@""];
    [request setSearchFilter:tmp];
    [request setTagsReady:^(NSArray *tagList, FluxDataRequest*completedRequest){
        //do something with array
        topTagsArray = tagList;
        [rightDrawerTableViewArray replaceObjectAtIndex:1 withObject:topTagsArray];
        if ([selectedTags count]>0) {
            NSMutableIndexSet * removalSet = [[NSMutableIndexSet alloc]init];
            for (int i = 0; i<selectedTags.count; i++) {
                NSString*str = [selectedTags objectAtIndex:i];
                FluxTagObject*tmp = [[FluxTagObject alloc]init];
                [tmp setTagText:str];
                if (![topTagsArray containsObject:tmp]) {
                    [removalSet addIndex:i];
                }
                // set it selected
                else{
                    int subArrayIndex = [[rightDrawerTableViewArray objectAtIndex:1] indexOfObject:tmp];
                    [[[rightDrawerTableViewArray objectAtIndex:1] objectAtIndex:subArrayIndex] setIsActive:YES];
                }
            }
            [selectedTags removeObjectsAtIndexes:removalSet];
            
        }
        [self.filterTableView reloadData];
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Tags failed to load with error %d", (int)[e code]];
        [ProgressHUD showError:str];
    }];
    
    
    [self.fluxDataManager requestTagListAtLocation:locationManager.location.coordinate withRadius:self.radius
                                       andMaxCount:20 withDataRequest:request];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didReturnTagList:(NSArray *)tagList{
    topTagsArray = tagList;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.filterTableView) {
        return rightDrawerTableViewArray.count;
    }
    else
        return 1;
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return 70.0f;
            break;
        case 1:
            return 50.0;
            break;
        default:
            return 0.0f;
            break;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (tableView == self.filterTableView) {
        return @"";
    }
    else
        return @"Search Results";
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    // Create header view and add label as a subview
    float height = [self tableView:tableView heightForHeaderInSection:section];
    UIView*view;
    if (height>0) {
        if (section == 0) {
            view = [[UIView alloc] initWithFrame:CGRectMake(0,0, tableView.frame.size.width, height)];
            [view setBackgroundColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:0.9]];
            
            // Create label with section title
            UILabel*label = [[UILabel alloc] init];
            label.frame = CGRectMake(20, 2, 150, height);
            label.textColor = [UIColor whiteColor];
            [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:19]];
            label.text = @"Show Only";
            label.backgroundColor = [UIColor clearColor];
            [label setCenter:CGPointMake(label.center.x, label.center.y)];
            [view addSubview:label];
            
            CGPoint countCenter = CGPointMake(view.frame.size.width-34, view.center.y);
            
            //Add a circle
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path addArcWithCenter:countCenter
                            radius:22.0
                        startAngle:0.0
                          endAngle:M_PI * 2.0
                         clockwise:YES];
            CAShapeLayer *circleLayer = [CAShapeLayer layer];
            circleLayer.path = path.CGPath;
            circleLayer.strokeColor = [[UIColor whiteColor] CGColor];
            circleLayer.fillColor = nil;
            circleLayer.lineWidth = 1.0;
            [view.layer addSublayer:circleLayer];
            
            //Add count label
            imageCountLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 2, 50, 50)];
            [imageCountLabel setCenter:countCenter];
            imageCountLabel.textColor = [UIColor whiteColor];
            [imageCountLabel setFont:[UIFont fontWithName:@"Akkurat" size:17]];
            imageCountLabel.text = [NSString stringWithFormat:@"%i", imageCount.intValue];
            [imageCountLabel setAdjustsFontSizeToFitWidth:YES];
            [imageCountLabel setMinimumScaleFactor:0.7];
            imageCountLabel.backgroundColor = [UIColor clearColor];
            imageCountLabel.textAlignment = NSTextAlignmentCenter;
            [view addSubview:imageCountLabel];
            
            // Save this shape layer in a class property for future reference,
            // namely so we can remove it later if we tap elsewhere on the screen.
        }
        else{
            view = [[UIView alloc] initWithFrame:CGRectMake(0,0, tableView.frame.size.width, height)];
            [view setBackgroundColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:0.9]];
            
            // Create label with section title
            UILabel *label = [[UILabel alloc] init];
            label.frame = CGRectMake(20, 10, 150, height);
            label.textColor = [UIColor whiteColor];
            [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:19]];
            label.text = @"Tags";
            label.backgroundColor = [UIColor clearColor];
            [label setCenter:CGPointMake(label.center.x, view.center.y)];
            [view addSubview:label];
            
            //searchbar
            self.tagsSearchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(view.frame.size.width-218, 5, 218, 40)];
            [self.tagsSearchBar setBarTintColor:[UIColor clearColor]];
            [self.tagsSearchBar setSearchBarStyle:UISearchBarStyleMinimal];
            [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
            [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont fontWithName:@"Akkurat" size:17]];
            [self.tagsSearchBar setTintColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:0.9]];
            [self.tagsSearchBar setPlaceholder:@"Search"];
            [self.tagsSearchBar setDelegate:self];
            
            //disable for now
            [self.tagsSearchBar setUserInteractionEnabled:NO];
            [self.tagsSearchBar setAlpha:0.8];
            
            [view addSubview:self.tagsSearchBar];
        }
        

    }
    else
    {
        view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.filterTableView) {
        return [[rightDrawerTableViewArray objectAtIndex:section]count];
    }
    //its the search tableView
    return 0;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.filterTableView) {
        return 44.0;
    }
    else
        return 44.0;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.filterTableView) {

        //if it's the social section
        if (indexPath.section == 0) {
            
            static NSString *CellIdentifier = @"socialCell";
            FluxSocialFilterCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[FluxSocialFilterCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            [cell.checkbox setDelegate:cell];
            [cell setDelegate:self];
            
            //disable the cell for now
            [cell setUserInteractionEnabled:NO];
            
            [cell.descriptorLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.descriptorLabel.font.pointSize]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            //set the cell properties to the array elements declared above
            [cell setDbTitle:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]dbTitle]];
            cell.descriptorLabel.text = [[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]title];
            [cell setIsActive:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]isChecked]];
            [cell.descriptorLabel setEnabled:NO];
            return cell;
        }
        //it's a tag
        else
        {
            static NSString *CellIdentifier = @"tagCell";
            FluxCheckboxCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[FluxCheckboxCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            [cell.descriptorLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.descriptorLabel.font.pointSize]];
            [cell.countLabel setFont:[UIFont fontWithName:@"Akkurat" size:cell.descriptorLabel.font.pointSize]];
            cell.descriptorLabel.text = [NSString stringWithFormat:@"#%@",[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]tagText]];
            cell.countLabel.text = [NSString stringWithFormat:@"%i",[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]count]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell setIsActive:[[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]isChecked]];
            [cell.checkbox setDelegate:cell];
            [cell setDelegate:self];
            
            if ([[[rightDrawerTableViewArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]isChecked]) {
                [cell.countLabel setAlpha:1.0];
            }
            else{
                [cell.countLabel setAlpha:0.5];
            }
            
            return cell;
        }

        
        
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        [(FluxSocialFilterCell*)[tableView cellForRowAtIndexPath:indexPath]cellWasTapped];
    }
    else{
        [(FluxCheckboxCell*)[tableView cellForRowAtIndexPath:indexPath]cellWasTapped];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark Cell Subview Delegates

//if the checkbox is selected, the callback comes here. In the method below we check which cell it is and mark the corresponding object as active.
- (void)SocialCell:(FluxSocialFilterCell *)checkCell boxWasChecked:(BOOL)checked{
    [self modifyDataFilter:dataFilter filterSting:checkCell.dbTitle forType:social_filterType andAdd:checked];
    //update the cell
    for (FluxSocialFilterCell* cell in [self.filterTableView visibleCells]) {
        if (cell == checkCell) {
            NSIndexPath *path = [self.filterTableView indexPathForCell:cell];
            [[[rightDrawerTableViewArray objectAtIndex:path.section]objectAtIndex:path.row] setIsActive:checked];
        }
    }
}

- (void)checkboxCell:(FluxCheckboxCell *)checkCell boxWasChecked:(BOOL)checked{
    NSString * tag = [checkCell.descriptorLabel.text substringFromIndex:1];
    [self modifyDataFilter:dataFilter filterSting:tag forType:tags_filterType andAdd:checked];
    
    if (checked) {
        [self updateImageCount:[checkCell.countLabel.text intValue]];
    }
    else
        [self updateImageCount:-[checkCell.countLabel.text intValue]];
    
    
    //update the cell
    for (FluxCheckboxCell* cell in [self.filterTableView visibleCells]) {
        if (cell == checkCell) {
            NSIndexPath *path = [self.filterTableView indexPathForCell:cell];
            [[[rightDrawerTableViewArray objectAtIndex:path.section]objectAtIndex:path.row] setIsActive:checked];
            if ([[[rightDrawerTableViewArray objectAtIndex:path.section]objectAtIndex:path.row] isChecked]) {
                [cell.countLabel setAlpha:1.0];
            }
            else{
                [cell.countLabel setAlpha:0.5];
            }
            break;
        }
    }
}

-(void)modifyDataFilter:(FluxDataFilter*)filter filterSting:(NSString*)string forType:(FluxFilterType)type andAdd:(BOOL)add{
    if (type == social_filterType) {
        if (add) {
            [dataFilter addCategoryToFilter:string];
        }
        else{
            [dataFilter removeCategoryFromFilter:string];
        }
    }
    if (type == tags_filterType) {
        if (add) {
            [dataFilter addHashTagToFilter:string];
        }
        else{
            [dataFilter removeHashTagFromFilter:string];
        }
    }
}

- (void)updateImageCount:(int)num{
    //if it's the first filter applied, make it the only active filter
    if (imageCount.intValue == startImageCount) {
        imageCount = [NSNumber numberWithInt:num];
    }
    
    //if not, add it up
    else{
        imageCount = [NSNumber numberWithInt:[imageCount intValue]+num];
    }

    //if we've subtracted back to 0, show the initial count (no filters applied anymore)
    if (imageCount.intValue == 0) {
        imageCount = [NSNumber numberWithInt:startImageCount];
    }
    
    [imageCountLabel setText:[NSString stringWithFormat:@"%i",imageCount.intValue]];

}



#pragma mark - UISearchDisplayController Delegate Methods
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    if (topTagsArray.count == 0) {
        FluxTagObject*tag = [[FluxTagObject alloc]init];
        [tag setTagText:@""];
        topTagsArray = [NSArray arrayWithObject:tag];
        [rightDrawerTableViewArray replaceObjectAtIndex:1 withObject:topTagsArray];
        [self.filterTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self performSelector:@selector(scrollSearchBArToTop) withObject:nil afterDelay:0.0];
    return YES;
}

-(void)scrollSearchBArToTop{
    [self.filterTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
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

// method to hide keyboard when user taps on a scrollview
-(void)hideKeyboard
{
    [self.tagsSearchBar resignFirstResponder];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self hideKeyboard];
}

#pragma mark - UI Actions

- (IBAction)cancelButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(FiltersTableViewDidPop:andChangeFilter:)]) {
        [delegate FiltersTableViewDidPop:self andChangeFilter:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(FiltersTableViewDidPop:andChangeFilter:)]) {
        [delegate FiltersTableViewDidPop:self andChangeFilter:dataFilter];
    }
    [self dismissViewControllerAnimated:YES completion:nil];

}
@end
