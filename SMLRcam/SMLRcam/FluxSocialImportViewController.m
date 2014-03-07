//
//  FluxSocialImportViewController.m
//  Flux
//
//  Created by Kei Turner on 2/19/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSocialImportViewController.h"
#import "FluxDataManager.h"
#import "FluxContactObject.h"
#import "ProgressHUD.h"
#import "UICKeyChainStore.h"
#import "FluxAddUserViewController.h"
#import "UIActionSheet+Blocks.h"
#import "FluxImageTools.h"

#import <Twitter/Twitter.h>
#import "TWAPIManager.h"
#import "TWSignedRequest.h"

#import <AddressBookUI/AddressBookUI.h>

@interface FluxSocialImportViewController ()

@end

@implementation FluxSocialImportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    loadDidFail = NO;
    alreadyAppeared = NO;
    isSearching = NO;
    [super viewDidLoad];
    self.importUserArray = [[NSMutableArray alloc]init];
    self.importUserImagesArray = [[NSMutableArray alloc]init];
    
    self.importFluxUserArray = [[NSMutableArray alloc]init];
    self.importFluxUserImagesArray = [[NSMutableArray alloc]init];
    
    self.searchResultsUserArray = [[NSMutableArray alloc]init];
    self.searchResultsImagesArray = [[NSMutableArray alloc]init];
    
    UIView *topview = [[UIView alloc] initWithFrame:CGRectMake(0,-480,320,480)];
    topview.backgroundColor = [UIColor clearColor];
    
    [self.importUserTableView addSubview:topview];

    
	// Do any additional setup after loading the view.
    [self loadData];

}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.view setAlpha:0.0];
    }];
    [[(FluxSearchCell*)[self.importUserTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] theSearchBar]resignFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setAlpha:1.0];
    }];
}

- (void)viewDidAppear:(BOOL)animated{
    alreadyAppeared = YES;
    
    if (loadDidFail) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)loadData{
    int serviceID = 0;
    // pull Twitter/fb credentials from keychain and pass up through API for contact request
    [self.view setUserInteractionEnabled:NO];
    NSDictionary *credentials = nil;
    
    if (self.serviceType == TwitterService) {
        // pull Twitter credentials and fire them up to the import API
        [self setTitle:@"Twitter"];
                [ProgressHUD show:@"Retrieving Twitter Contacts"];
        NSString *twtoken = [UICKeyChainStore stringForKey:FluxAccessTokenKey service:TwitterService];
        NSString *twtokensecret = [UICKeyChainStore stringForKey:FluxAccessTokenSecretKey service:TwitterService];
        credentials = [[NSDictionary alloc] initWithObjectsAndKeys:twtoken, @"access_token", twtokensecret, @"access_token_secret", nil];
        
        serviceID = 2;
    }

    else if (self.serviceType == FacebookService)
    {
                [ProgressHUD show:@"Retrieving Facebook Contacts"];
        [self setTitle:@"Facebook"];
        // pull Facebook credentials and fire them up to the import API
//        [UICKeyChainStore setString:FBSession.activeSession.accessTokenData.accessToken forKey:FluxTokenKey service:FacebookService];
//        [UICKeyChainStore setString:user.username forKey:FluxUsernameKey service:FacebookService];
//        [UICKeyChainStore setString:user.name forKey:FluxNameKey service:FacebookService];

        NSString *fbtoken = [UICKeyChainStore stringForKey:FluxTokenKey service:FacebookService];
        NSString *fbtokensecret = [UICKeyChainStore stringForKey:FluxUsernameKey service:FacebookService];
        credentials = [[NSDictionary alloc] initWithObjectsAndKeys:fbtoken, @"access_token", fbtokensecret, @"access_token_secret", nil];
        
        serviceID = 3;
    }
    
    //not twitter or facebook, it's contacts
    else{
        [self setTitle:@"Contacts"];
        [self collectContacts];
    }
    
    if (serviceID > 0)
    {
        // call the API...
        // build the request...
        FluxDataRequest*request = [[FluxDataRequest alloc]init];
        
        [request setContactListReady:^(NSArray *contacts, FluxDataRequest *completedRequest){
            //do something with the contacts - an array of FluxContacts
            
            self.importUserArray = [contacts mutableCopy];
            NSMutableIndexSet *removalSet = [[NSMutableIndexSet alloc]init];
            for (int i = 0; self.importUserArray.count; i++) {
//                NSLog(@"index: %i, object username: %@", i, [(FluxContactObject*)[self.importUserArray objectAtIndex:i]aliasName] );
                if ([(FluxContactObject*)[self.importUserArray objectAtIndex:i]userID]) {
                    [self.importFluxUserArray addObject:[self.importUserArray objectAtIndex:i]];
                    [removalSet addIndex:i];
                }
                else{
                    break;
                }
            }
            [self.importUserArray removeObjectsAtIndexes:removalSet];

            [self.importUserImagesArray removeAllObjects];
            for (int i = 0; i<self.importUserArray.count; i++) {
                [self.importUserImagesArray addObject:[NSNumber numberWithBool:NO]];
            }
            
            [self.importFluxUserImagesArray removeAllObjects];
            for (int i = 0; i<self.importFluxUserArray.count; i++) {
                [self.importFluxUserImagesArray addObject:[NSNumber numberWithBool:NO]];
            }
            [ProgressHUD dismiss];
            
            
            if (self.importFluxUserArray.count == 0 || self.importUserArray.count == 0) {
                [self showEmptyViewForError:nil];
            }
            else{
                [self.view setUserInteractionEnabled:YES];
                [self.importUserTableView reloadData];
            }

        }];
        
        
        [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            NSString*str;
            if (self.serviceType == TwitterService) {
                str = [NSString stringWithFormat:@"You've asked too much of Twitter for now, try again later."];
            }
            else{
                str = [NSString stringWithFormat:@"Contact Retrieval Failed"];
            }
            
            [ProgressHUD showError:str];
            
            loadDidFail = YES;
            if (alreadyAppeared) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                });
            }

        }];
        
        [[FluxDataManager theFluxDataManager] requestContactsFromService:serviceID withCredentials:credentials withDataRequest:request];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"pushProfileSegue"]) {
        FluxUserObject*userObj = [[FluxUserObject alloc]init];
        FluxContactObject*contact = (FluxContactObject*)sender;
        [userObj setUserID:contact.userID];
        [userObj setUsername:contact.username];
        [userObj setFriendState:contact.friendState];
        [userObj setIsFollower:contact.isFollower];
        [userObj setIsFollowing:contact.isFollowing];
        
        [(FluxPublicProfileViewController*)segue.destinationViewController setFluxDataManager:[(FluxAddUserViewController*)[[(UINavigationController*)self.parentViewController viewControllers] objectAtIndex:0] fluxDataManager]];
        [(FluxPublicProfileViewController*)segue.destinationViewController prepareViewWithUser:userObj];
        [(FluxPublicProfileViewController*)segue.destinationViewController setDelegate:self];
    }
    else{
        
    }
    
}

-(void)showEmptyViewForError:(NSError*)e{
    [emptyListLabel setFont:[UIFont fontWithName:@"Akkurat" size:emptyListLabel.font.pointSize]];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineSpacing = 6;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attribs = @{
                              NSForegroundColorAttributeName: emptyListLabel.textColor,
                              NSFontAttributeName: emptyListLabel.font,
                              NSParagraphStyleAttributeName : paragraphStyle
                              };
    
    NSMutableAttributedString *attributedText;
//    if (!e) {
        if (self.serviceType == TwitterService) {
            attributedText = [[NSMutableAttributedString alloc]
                              initWithString:@"No follow-back relationships found on Twitter."
                              attributes:attribs];
        }
        else if (self.serviceType == FacebookService){
            attributedText = [[NSMutableAttributedString alloc]
                              initWithString:@"Facebook didn't return any friends."
                              attributes:attribs];
        }
        else{
            attributedText = [[NSMutableAttributedString alloc]
                              initWithString:@"Contact search from your address book came back empty"
                              attributes:attribs];
        }
//    }
//    else{
//        attributedText = [[NSMutableAttributedString alloc]
//                          initWithString:@"Well this is awkward, it seems something broke."
//                          attributes:attribs];
//    }


    
    [emptyListLabel setAttributedText:attributedText];
    [emptyListLabel setNumberOfLines:3];
    
    [emptyListView setHidden:NO];
    [self.importUserTableView setHidden:YES];
}


#pragma mark - ScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [[(FluxSearchCell*)[self.importUserTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] theSearchBar]resignFirstResponder];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (isSearching) {
        return 1;
    }
    if (self.importFluxUserArray.count > 0){
        return 3;
    }
    else
        return 2;
    

}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (isSearching) {
        return @"Search Results";
    }
    else if (self.importFluxUserArray.count > 0){
        if (section == 0) {
            return @"";
        }
        else if (section == 1) {
            return @"Already on Flux";
        }
        else if (section == 2) {
            return @"Not using Flux yet";
        }
        //wont't hit
        else{
            return @"";
        }
    }
    else{
        if (section == 0) {
            return @"";
        }
        else
        {
            return @"Not using Flux yet";
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0.0;
    }
    if (isSearching) {
        return 20.0;
    }
    else if (self.importFluxUserArray.count > 0){
        return 20.0;
    }
    
    else{
        return 20.0;
    }
    
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return nil;
    }
    if (isSearching) {
        return [self standardHeaderForSection:section];
    }
    else if (self.importFluxUserArray.count > 0){
        return [self standardHeaderForSection:section];
    }
    else{
        return [self standardHeaderForSection:section];
    }
}
- (UIView*)standardHeaderForSection:(NSInteger)section{
    float height = [self tableView:self.importUserTableView heightForHeaderInSection:section];
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.importUserTableView.frame.size.width, height)];
    [view setBackgroundColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:0.7]];
    
    // Create label with section title
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 10, 150, height);
    label.textColor = [UIColor whiteColor];
    [label setFont:[UIFont fontWithName:@"Akkurat" size:12]];
    label.text = [self tableView:self.importUserTableView titleForHeaderInSection:section];
    label.backgroundColor = [UIColor clearColor];
    [label setCenter:CGPointMake(label.center.x, view.center.y+1)];
    [view addSubview:label];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isSearching) {
        return self.searchResultsUserArray.count+1;
    }

    else if (self.importFluxUserArray.count > 0){
        if (section == 0) {
            return 1;
        }
        else if (section == 1) {
            return self.importFluxUserArray.count;
        }
        else if (section == 2) {
            return self.importUserArray.count;
        }
        //wont't hit
        else{
            return 1;
        }
    }
    else{
        if (section == 0) {
            return 1;
        }
        else
        {
            return self.importUserArray.count;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        FluxSearchCell * cell = [tableView dequeueReusableCellWithIdentifier:@"searchCell"];
        if (!cell) {
            cell = [[FluxSearchCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"searchCell"];
        }
        [cell.theSearchBar setDelegate:cell];
        [cell setDelegate:self];
        return cell;
    }
    int index = indexPath.row;
    
    if (isSearching) {
        index = indexPath.row - 1;
        NSString*cellIdentifier;
        if ([(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index]userID]) {
            cellIdentifier = @"fluxImportCell";
        }
        else{
            cellIdentifier = @"standardImportCell";
        }
        
        FluxImportContactCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[FluxImportContactCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        [cell initCellWithType:self.serviceType];
        [cell setDelegate:self];
        [cell setContactObject:(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index]];
        if ([[self.searchResultsImagesArray objectAtIndex:index] isKindOfClass:[UIImage class]]) {
            [cell.profileImageView setImage:[self.searchResultsImagesArray objectAtIndex:index]];
        }
        else{
            __weak FluxImportContactCell *weakCell = cell;
            
            [cell.profileImageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:cell.contactObject.profilePicURL]]
                                         placeholderImage:[UIImage imageNamed:@"emptyProfileImage_big"]
                                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                                      if (image) {
                                                          //if there's an image
                                                          if (index < self.searchResultsImagesArray.count) {
                                                              //and there is an index there
                                                              if ([[(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] aliasName] isEqualToString:weakCell.contactObject.aliasName]) {
                                                                  //and it's the same index as when we started, then updatw the image
                                                                  [self.searchResultsImagesArray replaceObjectAtIndex:index withObject:image];
                                                                  
                                                                  [weakCell.profileImageView setImage:image];
                                                                  //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                                                  //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                                                  [weakCell setNeedsLayout];
                                                                  //}
                                                              }
                                                          }

                                                      }
                                                      
                                                  }
                                                  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                                      NSLog(@"profile image done broke :(");
                                                  }];
        }
        return cell;
        
    }

    NSString*cellIdentifier;
    if (self.importFluxUserArray.count > 0 && indexPath.section == 1){
        cellIdentifier = @"fluxImportCell";
    }
    else{
        cellIdentifier = @"standardImportCell";
    }
    

    FluxImportContactCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxImportContactCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell initCellWithType:self.serviceType];
    [cell setDelegate:self];
    
    if (self.importFluxUserArray.count > 0 && indexPath.section == 1){
        [cell setContactObject:(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index]];

    }
    else{
        [cell setContactObject:(FluxContactObject*)[self.importUserArray objectAtIndex:index]];
    }
    
    

    if (self.importFluxUserArray.count > 0 && indexPath.section == 1){
        if ([[self.importFluxUserImagesArray objectAtIndex:index] isKindOfClass:[UIImage class]]) {
            [cell.profileImageView setImage:[self.importFluxUserImagesArray objectAtIndex:index]];
        }
        else{
            __weak FluxImportContactCell *weakCell = cell;
            
            [cell.profileImageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:cell.contactObject.profilePicURL]]
                                         placeholderImage:[UIImage imageNamed:@"emptyProfileImage_big"]
                                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                                      if (image) {
                                                          [self.importFluxUserImagesArray replaceObjectAtIndex:index withObject:image];
                                                          
                                                          [weakCell.profileImageView setImage:image];
                                                          //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                                          //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                                          [weakCell setNeedsLayout];
                                                          //}
                                                      }
                                                      
                                                  }
                                                  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                                      NSLog(@"profile image done broke :(");
                                                  }];
        }
    }
    else{
        if ([[self.importUserImagesArray objectAtIndex:index] isKindOfClass:[UIImage class]]) {
            [cell.profileImageView setImage:[self.importUserImagesArray objectAtIndex:index]];
        }
        else{
            __weak FluxImportContactCell *weakCell = cell;
            
            [cell.profileImageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:cell.contactObject.profilePicURL]]
                                         placeholderImage:[UIImage imageNamed:@"emptyProfileImage_big"]
                                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                                                      if (image) {
                                                          [self.importUserImagesArray replaceObjectAtIndex:index withObject:image];
                                                          
                                                          [weakCell.profileImageView setImage:image];
                                                          //only required if no placeholder is set to force the imageview on the cell to be laid out to house the new image.
                                                          //if(weakCell.imageView.frame.size.height==0 || weakCell.imageView.frame.size.width==0 ){
                                                          [weakCell setNeedsLayout];
                                                          //}
                                                      }
                                                      
                                                  }
                                                  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                                                      NSLog(@"profile image done broke :(");
                                                  }];
        }
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.importFluxUserArray.count > 0 && indexPath.section == 1) {
        FluxImportContactCell*cell = (FluxImportContactCell*)[self.importUserTableView cellForRowAtIndexPath:indexPath];
        if ([[self.importFluxUserImagesArray objectAtIndex:indexPath.row] isKindOfClass:[UIImage class]]) {
            [cell.contactObject setProfilePic:(UIImage*)[self.importFluxUserImagesArray objectAtIndex:indexPath.row]];
        }
        [self performSegueWithIdentifier:@"pushProfileSegue" sender:cell.contactObject];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else{
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - Search Cell Delegate
-(void)SearchCell:(FluxSearchCell *)searchCell didType:(NSString *)query{
    [self.searchResultsUserArray removeAllObjects];
    [self.searchResultsImagesArray removeAllObjects];
    isSearching = YES;
    if (query.length > 0) {
        
//        NSPredicate *pred =[NSPredicate predicateWithFormat:@"aliasName beginswith[c] %@", query];
//        self.searchResultsUserArray = [NSMutableArray arrayWithObjects:[self.importUserArray filteredArrayUsingPredicate:pred],[self.importFluxUserArray filteredArrayUsingPredicate:pred] ,nil];
        
        NSIndexSet *fluxUserIndexSet = [self.importFluxUserArray indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
            NSString*s;
            if (self.serviceType == FacebookService) {
                s = [(FluxContactObject*)obj displayName];
            }
            else{
                s = [(FluxContactObject*)obj aliasName];
            }

            NSString *t = [(FluxContactObject*)obj username];
            BOOL startsWith = [s hasPrefix: query] || [t hasPrefix: query] || [s hasPrefix: [query capitalizedString]]  || [s hasPrefix: [query uppercaseString]]  || [s hasPrefix: [query lowercaseString]] || [t hasPrefix: [query capitalizedString]]  || [t hasPrefix: [query uppercaseString]]  || [t hasPrefix: [query lowercaseString]];
;
            return startsWith;
        }];
        
        NSIndexSet *userIndexSet = [self.importUserArray indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
            NSString*s;
            if (self.serviceType == FacebookService) {
                s = [(FluxContactObject*)obj displayName];
            }
            else{
                s = [(FluxContactObject*)obj aliasName];
            }
            
            BOOL startsWith = [s hasPrefix: query] || [s hasPrefix: [query capitalizedString]]  || [s hasPrefix: [query uppercaseString]]  || [s hasPrefix: [query lowercaseString]];
            return startsWith;
        }];
        
        //add the indexes from the user pool first
        unsigned index = [fluxUserIndexSet firstIndex];
        while ( index != NSNotFound )
        {
//            if ( index < fluxUserIndexSet.count ){
                [self.searchResultsUserArray addObject: [self.importFluxUserArray objectAtIndex:index]];
                [self.searchResultsImagesArray addObject:[self.importFluxUserImagesArray objectAtIndex:index]];
                index = [fluxUserIndexSet indexGreaterThanIndex: index];
//            }
        }
        
        //then the rest
        index = [userIndexSet firstIndex];
        while ( index != NSNotFound )
        {
//            if (index < userIndexSet.count ){
                [self.searchResultsUserArray addObject: [self.importUserArray objectAtIndex:index]];
                [self.searchResultsImagesArray addObject:[self.importUserImagesArray objectAtIndex:index]];
                index = [userIndexSet indexGreaterThanIndex: index];
//            }
        }
        
        
    }
    else{
        isSearching = NO;
    }
    [self.importUserTableView reloadData];
    [[(FluxSearchCell*)[self.importUserTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] theSearchBar]becomeFirstResponder];
}



#pragma mark - SocialImport Cell Delegate
-(void)ImportContactCellFriendFollowButtonWasTapped:(FluxImportContactCell *)importContactCell{
    [[(FluxSearchCell*)[self.importUserTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] theSearchBar]resignFirstResponder];
    NSMutableArray*options = [[NSMutableArray alloc]init];
    
    NSString*sendFriendRequest = @"Send Friend Request";
    NSString*addFollower = @"Follow";
    NSString*acceptFriendRequest = @"Accept Friend Request";
    NSString*cancelFriendRequest;
    if (!importContactCell.contactObject.isFollowing) {
        [options addObject:addFollower];
    }
    if (!importContactCell.contactObject.friendState) {
        [options addObject:sendFriendRequest];
    }
    if (importContactCell.contactObject.friendState == 2) {
        cancelFriendRequest = @"Cancel Friend Request";
    }
    
    else{
        if (importContactCell.contactObject.friendState == 1) {
            [options addObject:acceptFriendRequest];
        }
    }
    
    //shows an alert View with options depending on current social status. deals with dataModel updates + tableView updates too
    [UIActionSheet showInView:self.view
                    withTitle:nil
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:(cancelFriendRequest? cancelFriendRequest : nil)
            otherButtonTitles:options
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             //link facebook
                             int index = [self.importUserTableView indexPathForCell:importContactCell].row;
                             if (isSearching) {
//                                 rowIndex =
                             }
                             
                             if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:addFollower]) {
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 
                                 [request setFollowUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"Followed");
                                     if (isSearching) {
                                         if (self.searchResultsUserArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] setIsFollowing:YES];
                                                 
                                                 [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                         
                                         for (int i = 0; i<self.importFluxUserArray.count; i++) {
                                             if ([[(FluxContactObject*)[self.importFluxUserArray objectAtIndex:i]username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 [(FluxContactObject*)[self.importFluxUserArray objectAtIndex:i] setIsFollowing:YES];
                                                 break;
                                             }
                                         }
                                     }
                                     else{
                                         if (self.importFluxUserArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index] username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index] setIsFollowing:YES];
                                                 
                                                 [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                     }

                                     //call the delegate
//                                     if ([delegate respondsToSelector:@selector(AddUserViewController:didFollowUser:)]) {
//                                         [delegate AddUserViewController:self didFollowUser:friendFollowerCell.userObject];
//                                     }
                                 }];
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Adding a follower failed with error %d", (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager addFollowerWithUserID:importContactCell.contactObject.userID withDataRequest:request];
                             }
                             if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:sendFriendRequest]) {
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 [request setSendFriendRequestReady:^(int userID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"friend request sent");
                                     
                                     if (isSearching) {
                                         if (self.searchResultsUserArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] setFriendState:2];
                                                 
                                                 [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                         
                                         for (int i = 0; i<self.importFluxUserArray.count; i++) {
                                             if ([[(FluxContactObject*)[self.importFluxUserArray objectAtIndex:i]username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 [(FluxContactObject*)[self.importFluxUserArray objectAtIndex:i] setFriendState:2];
                                                 break;
                                             }
                                         }
                                     }
                                     else{
                                         //if it hasn;t been cleared
                                         if (self.importFluxUserArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index] username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index] setFriendState:2];
                                                 [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                     }
                                     

                                 }];
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Adding a follower failed with error %d", (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager sendFriendRequestToUserWithID:importContactCell.contactObject.userID withDataRequest:request];
                             }
                             if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:acceptFriendRequest]) {
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 [request setAcceptFriendRequestReady:^(int newFriendUserID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"friended");
                                     
                                     if (isSearching) {
                                         if (self.searchResultsUserArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] setFriendState:3];
                                                 
                                                 [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                         
                                         for (int i = 0; i<self.importFluxUserArray.count; i++) {
                                             if ([[(FluxContactObject*)[self.importFluxUserArray objectAtIndex:i]username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 [(FluxContactObject*)[self.importFluxUserArray objectAtIndex:i] setFriendState:3];
                                                 break;
                                             }
                                         }
                                     }
                                     else{
                                         //if it hasn;t been cleared
                                         if (self.importFluxUserArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index] username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index] setFriendState:3];
                                                 [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                     }

                                 }];
                                 
//                                 if ([delegate respondsToSelector:@selector(AddUserViewController:didAddFriend:)]) {
//                                     [delegate AddUserViewController:self didAddFriend:friendFollowerCell.userObject];
//                                 }
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Accepting friend request from %@ failed with error %d",importContactCell.contactObject.username, (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager acceptFriendRequestFromUserWithID:importContactCell.contactObject.userID withDataRequest:request];
                             }
                             
                             
                             if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:cancelFriendRequest]) {
                                 FluxDataRequest*request = [[FluxDataRequest alloc]init];
                                 
                                 [request setUnfriendUserReady:^(int followingUserID, FluxDataRequest*completedRequest){
                                     //do something with the UserID
                                     NSLog(@"friend request cancelled");
                                     
                                     if (isSearching) {
                                         if (self.searchResultsUserArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] setFriendState:0];
                                                 
                                                 [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                         
                                         for (int i = 0; i<self.importFluxUserArray.count; i++) {
                                             if ([[(FluxContactObject*)[self.importFluxUserArray objectAtIndex:i]username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 [(FluxContactObject*)[self.importFluxUserArray objectAtIndex:i] setFriendState:0];
                                                 break;
                                             }
                                         }
                                     }
                                     else{
                                         //if it hasn;t been cleared
                                         if (self.importFluxUserArray.count > index) {
                                             //...and it's still the same cell
                                             if ([[(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index] username] isEqualToString:[importContactCell.titleLabel.text substringFromIndex:1]]) {
                                                 //update it
                                                 [(FluxContactObject*)[self.importFluxUserArray objectAtIndex:index] setFriendState:0];
                                                 [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }
                                         }
                                     }
                                     

                                 }];
                                 
                                 
                                 [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                                     
                                     NSString*str = [NSString stringWithFormat:@"Unfriending failed with error %d", (int)[e code]];
                                     [ProgressHUD showError:str];
                                     
                                 }];
                                 [self.fluxDataManager unfriendWithUserID:importContactCell.contactObject.userID withDataRequest:request];
                             }
                         }
                     }];

}

- (void)ImportContactCell:(FluxImportContactCell *)importContactCell shouldInvite:(FluxContactObject *)contact{
    [[(FluxSearchCell*)[self.importUserTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] theSearchBar]resignFirstResponder];
    int index = [self.importUserTableView indexPathForCell:(FluxImportContactCell*)importContactCell].row;
    [self willInviteCell:importContactCell atIndex:index];
    if (contact.emails) {
        if (contact.emails.count > 1) {
                [UIActionSheet showInView:self.view
                                withTitle:@"Choose an email:"
                        cancelButtonTitle:@"Cancel"
                   destructiveButtonTitle:nil
                        otherButtonTitles:contact.emails
                                 tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                     if (buttonIndex != actionSheet.cancelButtonIndex) {
                                         NSLog(@"Tapped email:%@",[actionSheet buttonTitleAtIndex:buttonIndex]);
                                     }
                                 }];
        }
    }
    else if (self.serviceType == TwitterService){
        SLRequestHandler requestHandler =
        ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if (responseData) {
                NSInteger statusCode = urlResponse.statusCode;
                if (statusCode >= 200 && statusCode < 300) {
                    NSDictionary *postResponseData =
                    [NSJSONSerialization JSONObjectWithData:responseData
                                                    options:NSJSONReadingMutableContainers
                                                      error:NULL];
                    NSLog(@"[SUCCESS!] Created DirectMessage with ID: %@", postResponseData[@"id_str"]);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self didInviteCell:importContactCell atIndex:index andSucceeded:YES];
                    });
                    
                }
                else {
                    NSLog(@"[ERROR] Server responded: status code %d %@", statusCode,
                          [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
                    [ProgressHUD showError:[NSString stringWithFormat:@"Sending invitation to @%@ failed", contact.aliasName]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self didInviteCell:importContactCell atIndex:index andSucceeded:NO];
                    });
                }
            }
            else {
                NSLog(@"[ERROR] An error occurred while posting DM: %@", [error localizedDescription]);
                [ProgressHUD showError:[NSString stringWithFormat:@"Sending invitation to @%@ failed", contact.aliasName]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self didInviteCell:importContactCell atIndex:index andSucceeded:NO];
                });
            }
        };
        
        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/direct_messages/new.json"];
        //    NSDictionary *params = @{@"user_id" : contact.socialID, @"text" : @"I've invited you to try Flux. See what you can discover: smlr.is"};
        NSDictionary *params = [[NSDictionary alloc]initWithObjectsAndKeys:contact.socialID, @"user_id", @"I've invited you to try Flux. See what you can discover: smlr.is", @"text", nil];
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                requestMethod:SLRequestMethodPOST
                                                          URL:url
                                                   parameters:params];
        [request setAccount:self.TWAccount];
        [request performRequestWithHandler:requestHandler];
        
    }
    else if (self.serviceType == FacebookService){
        NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         contact.aliasName, @"to", // only send-able to this contact now
                                         @"fbAPPID://authorize#target_url=[MYURL]", @"link",
                                         nil];
        
        [FBWebDialogs
         presentRequestsDialogModallyWithSession:nil
         message:@"See a place like you've never seen it before."  /*shows up on web only, displayed below name, which is below app title*/
         title:nil
         parameters:params
         handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
             if (!error) {
                 if (result == FBWebDialogResultDialogCompleted) {
                     NSLog(@"sent FB invite to %@",contact.displayName);
                     [self didInviteCell:importContactCell atIndex:index andSucceeded:YES];
                 }
                 else{
                     NSLog(@"Cancelled invite");
                     [self didInviteCell:importContactCell atIndex:index andSucceeded:NO];
                 }
             }
             else{
                 [ProgressHUD showError:[NSString stringWithFormat:@"Sending invitation to @%@ failed", contact.displayName]];
                 [self didInviteCell:importContactCell atIndex:index andSucceeded:NO];
             }
         }];
    }
    //should never hit
    else{
        
    }
}

- (void)willInviteCell:(FluxImportContactCell*)importCell atIndex:(int)index{
    if (isSearching) {
        index--;
        if (self.searchResultsUserArray.count > index) {
            //...and it's still the same cell
            if ([(self.serviceType == FacebookService) ? [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] displayName] : [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] aliasName]  isEqualToString:(self.serviceType == FacebookService ? importCell.titleLabel.text : [importCell.titleLabel.text substringFromIndex:1])]) {
                //update it
                [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] setInviteSending:YES];
            }
        }
        
        for (int i = 0; i<self.importUserArray.count; i++) {
            if ([(self.serviceType == FacebookService) ? [(FluxContactObject*)[self.importUserArray objectAtIndex:i] displayName] : [(FluxContactObject*)[self.importUserArray objectAtIndex:i] aliasName]  isEqualToString:(self.serviceType == FacebookService ? importCell.titleLabel.text : [importCell.titleLabel.text substringFromIndex:1])]) {
                [(FluxContactObject*)[self.importUserArray objectAtIndex:i] setInviteSent:YES];
                break;
            }
        }
        
        
        
        [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index+1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else{
        
        if (self.importUserArray.count > index) {
            //...and it's still the same cell
            if ([(self.serviceType == FacebookService) ? [(FluxContactObject*)[self.importUserArray objectAtIndex:index] displayName] : [(FluxContactObject*)[self.importUserArray objectAtIndex:index] aliasName]  isEqualToString:(self.serviceType == FacebookService ? importCell.titleLabel.text : [importCell.titleLabel.text substringFromIndex:1])]) {
                //update it
                [(FluxContactObject*)[self.importUserArray objectAtIndex:index] setInviteSending:YES];
                [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:(self.importFluxUserArray.count > 0) ? 2 : 1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                
            }
        }
    }
}

- (void)didInviteCell:(FluxImportContactCell*)importCell atIndex:(int)index andSucceeded:(BOOL)succeeded{
    if (isSearching) {
        index--;
        if (self.searchResultsUserArray.count > index) {
            //...and it's still the same cell
            if ([(self.serviceType == FacebookService) ? [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] displayName] : [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] aliasName]  isEqualToString:(self.serviceType == FacebookService ? importCell.titleLabel.text : [importCell.titleLabel.text substringFromIndex:1])]) {
                //update it
                [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] setInviteSending:NO];
                [(FluxContactObject*)[self.searchResultsUserArray objectAtIndex:index] setInviteSent:succeeded];
            }
        }
        //incredibly inneficient
        for (int i = 0; i<self.importUserArray.count; i++) {
            if ([(self.serviceType == FacebookService) ? [(FluxContactObject*)[self.importUserArray objectAtIndex:i] displayName] : [(FluxContactObject*)[self.importUserArray objectAtIndex:i] aliasName]  isEqualToString:(self.serviceType == FacebookService ? importCell.titleLabel.text : [importCell.titleLabel.text substringFromIndex:1])]) {
                [(FluxContactObject*)[self.importUserArray objectAtIndex:i] setInviteSending:NO];
                [(FluxContactObject*)[self.importUserArray objectAtIndex:i] setInviteSent:succeeded];
                break;
            }
        }
        
        
        
        [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index+1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else{
        if (self.importUserArray.count > index) {
            //...and it's still the same cell
            
            if ([(self.serviceType == FacebookService) ? [(FluxContactObject*)[self.importUserArray objectAtIndex:index] displayName] : [(FluxContactObject*)[self.importUserArray objectAtIndex:index] aliasName]  isEqualToString:(self.serviceType == FacebookService ? importCell.titleLabel.text : [importCell.titleLabel.text substringFromIndex:1])]) {
                //update it
                [(FluxContactObject*)[self.importUserArray objectAtIndex:index] setInviteSending:NO];
                [(FluxContactObject*)[self.importUserArray objectAtIndex:index] setInviteSent:succeeded];
                [self.importUserTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:(self.importFluxUserArray.count > 0) ? 2 : 1]] withRowAnimation:UITableViewRowAnimationAutomatic];
                
            }
        }
    }
}

#pragma mark - SocialInvites
#pragma mark Twitter
- (void)inviteUserFromTwitter:(FluxContactObject*)contact{
    

}

#pragma mark - address book loading


//
//    // Request authorization to Address Book
//    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
//
//    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
//        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
//            if (granted) {
//                [self collectContacts];
//
//                // First time access has been granted
//            } else {
//                // User denied access
//                // Display an alert telling user the contact could not be added
//            }
//        });
//    }
//    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
//        // The user has previously given access
//        [self collectContacts];
//    }
//    else {
//        // The user has previously denied access
//        // Send an alert telling user to change privacy setting in settings app
//    }

-(void)collectContacts
{
    [ProgressHUD show:@"Retrieving Contacts"];
    CFErrorRef*e = NULL;
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, e);
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            NSArray *thePeople = (__bridge_transfer NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBook);
            for (int i = 0; i<thePeople.count; i++) {
                // Get all the info if theres an email (we can do something with it)
                ABRecordRef ref = CFArrayGetValueAtIndex((__bridge CFArrayRef)(thePeople), i);
                ABMultiValueRef emailMultiValue = ABRecordCopyValue(ref, kABPersonEmailProperty);
                NSArray *emailAddresses = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emailMultiValue);
                
                
                NSString *firstName = (__bridge NSString *)ABRecordCopyValue(ref,kABPersonFirstNameProperty);
                NSString *lastName = (__bridge NSString *)ABRecordCopyValue(ref,kABPersonLastNameProperty);
                if (emailAddresses.count > 0) {
                    
                    NSData  *imgData = (__bridge NSData*)ABPersonCopyImageDataWithFormat(ref, kABPersonImageFormatThumbnail);
                    UIImage  *img = [UIImage imageWithData:imgData];

                    FluxContactObject*contact = [[FluxContactObject alloc]init];
                    if (firstName || lastName) {
                        if (firstName && lastName) {
                            [contact setAliasName:[NSString stringWithFormat:@"%@ %@",firstName, lastName]];
                        }
                        else if (!firstName){
                            [contact setAliasName:[NSString stringWithFormat:@"%@", lastName]];
                        }
                        else{
                            [contact setAliasName:[NSString stringWithFormat:@"%@", firstName]];
                        }
                    }
                    else{
                        [contact setAliasName:[NSString stringWithFormat:@"%@", [emailAddresses objectAtIndex:0]]];
                    }
                    
                    [contact setEmails:emailAddresses];
                    
                    if (img) {
                        NSData *imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation((img), 1.0)];
                        int imageSize = imageData.length;
                        FluxImageTools *tools = [[FluxImageTools alloc]init];

                        UIImage * newImage =  [tools resizedImage:img toSize:CGSizeMake(80, 80) interpolationQuality:0.1];
                        imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation((newImage), 1.0)];
                        imageSize = imageData.length;
                        
                        [contact setProfilePic:newImage];
                        [self.importUserImagesArray addObject:newImage];
                    }
                    else{
                        [self.importUserImagesArray addObject:[NSNumber numberWithBool:NO]];
                    }
                    [self.importUserArray addObject:contact];
                }
            }
//            self.importUserDisplayArray = [self.importUserArray mutableCopy];
            if (self.importUserArray.count > 0) {
                [self.view setUserInteractionEnabled:YES];
                [self.importUserTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            }
            else{
                NSError*e = [[NSError alloc]init];
                [self showEmptyViewForError:e];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [ProgressHUD dismiss];
            });
            
        }
        else{
            [ProgressHUD showError:@"You didn't give Flux permission. Please goto the Settings app and enable this permission to import from Contacts"];
        }

    });
}



@end
