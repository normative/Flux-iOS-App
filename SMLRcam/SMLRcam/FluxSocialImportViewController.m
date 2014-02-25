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
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    int serviceID = 0;
    // pull Twitter/fb credentials from keychain and pass up through API for contact request
    // get results back and use rows to populate the self.importUserArray
    // then regen the tableview data with [tableview reload data]
    NSDictionary *credentials = nil;
    NSString *contactType = self.title;
    if ([contactType compare:@"Twitter"] == NSOrderedSame )
    {
        // pull Twitter credentials and fire them up to the import API
        NSString *twtoken = [UICKeyChainStore stringForKey:FluxAccessTokenKey service:TwitterService];
        NSString *twtokensecret = [UICKeyChainStore stringForKey:FluxAccessTokenSecretKey service:TwitterService];
        credentials = [[NSDictionary alloc] initWithObjectsAndKeys:twtoken, @"access_token", twtokensecret, @"access_token_secret", nil];

        serviceID = 2;
    }
    else if ([contactType compare:@"Facebook"] == NSOrderedSame )
    {
        // pull Facebook credentials and fire them up to the import API
        NSString *fbtoken = [UICKeyChainStore stringForKey:FluxAccessTokenKey service:FacebookService];
        NSString *fbtokensecret = [UICKeyChainStore stringForKey:FluxAccessTokenSecretKey service:FacebookService];
        credentials = [[NSDictionary alloc] initWithObjectsAndKeys:fbtoken, @"access_token", fbtokensecret, @"access_token_secret", nil];
        
        serviceID = 3;
    }
    
    if (serviceID > 0)
    {
        // call the API...
        // build the request...
        FluxDataRequest*request = [[FluxDataRequest alloc]init];
        
        [request setContactListReady:^(NSArray *contacts, FluxDataRequest *completedRequest){
            //do something with the contacts - an array of FluxContacts
            NSLog(@"Contacts returned");
            if (contacts.count > 0)
            {
                // spin through and add the contacts into the importUserArray
                for (FluxContactObject *c in contacts)
                {
                    NSLog(@"contact userid: %d, username: %@, social name: %@, display name: %@, pic URL: %@", c.userID, c.username, c.alias_name, c.display_name, c.profile_pic_URL);
                }
                
                // now regenerate the data
            }
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.importUserArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString*cellIdentifier;
    cellIdentifier = @"standardSocialCell";

    FluxFriendFollowerCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxFriendFollowerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell setDelegate:self];
    [cell initCell];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
