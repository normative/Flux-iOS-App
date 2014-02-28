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
    [[(FluxSearchCell*)[self.importUserTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] theSearchBar]resignFirstResponder];
}

- (void)loadData{
    int serviceID = 0;
    // pull Twitter/fb credentials from keychain and pass up through API for contact request
    
    NSDictionary *credentials = nil;
    
    if (self.serviceType == TwitterService) {
        // pull Twitter credentials and fire them up to the import API
        [self setTitle:@"Twitter"];
        NSString *twtoken = [UICKeyChainStore stringForKey:FluxAccessTokenKey service:TwitterService];
        NSString *twtokensecret = [UICKeyChainStore stringForKey:FluxAccessTokenSecretKey service:TwitterService];
        credentials = [[NSDictionary alloc] initWithObjectsAndKeys:twtoken, @"access_token", twtokensecret, @"access_token_secret", nil];
        
        serviceID = 2;
    }

    else if (self.serviceType == FacebookService)
    {
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
                if ([(FluxContactObject*)[self.importUserArray objectAtIndex:i]userID]) {
                    [self.importFluxUserArray addObject:[self.importUserArray objectAtIndex:i]];
                    [self.importUserArray removeObjectAtIndex:i];
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
            [self.importUserTableView reloadData];
        }];
        
        
        [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            
            NSString*str = [NSString stringWithFormat:@"Contact fetch failed with error %d", (int)[e code]];
            [ProgressHUD showError:str];
            
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
        return 1;
    

}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (isSearching) {
        return @"Search Results";
    }
    switch (section) {
        case 1:
            return @"Already on Flux";
            break;
        case 2:
            return @"Not using Flux  ...yet";
            break;
        default:
            return @"";
            break;
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
        return 0.0;
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
        return nil;
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
    [label setCenter:CGPointMake(label.center.x, view.center.y)];
    [view addSubview:label];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isSearching) {
        return self.searchResultsUserArray.count+1;
    }

    else if (self.importFluxUserArray.count > 0){
        if (section == 1) {
            return self.importFluxUserArray.count+1;
        }
        else{
            return self.importUserArray.count+1;
        }
    }
    else{
        return self.importUserArray.count+1;
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
    int index = indexPath.row-1;
    
    if (isSearching) {
        NSString*cellIdentifier = @"standardImportCell";
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
                                                          [self.searchResultsImagesArray replaceObjectAtIndex:index withObject:image];
                                                          
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
            NSString *s = [(FluxContactObject*)obj aliasName];
            BOOL startsWith = [s hasPrefix: query];
            return startsWith;
        }];
        
        NSIndexSet *userIndexSet = [self.importUserArray indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
            NSString *s = [(FluxContactObject*)obj aliasName];
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
    
}

- (void)ImportContactCell:(FluxImportContactCell *)importContactCell shouldInvite:(FluxContactObject *)contact{
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
            [self.importUserTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
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
