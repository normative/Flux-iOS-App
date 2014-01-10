//
//  FluxRegisterUsernameViewController.h
//  Flux
//
//  Created by Kei Turner on 1/6/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxDataManager.h"

#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "OAuth+Additions.h"
#import "TWAPIManager.h"
#import "TWSignedRequest.h"

@class FluxRegisterUsernameViewController;
@protocol FluxRegisterUsernameViewDelegate <NSObject>
@optional
- (void)RegisterUsernameView:(FluxRegisterUsernameViewController*)usernameView didAcceptAddUsernameToUserInfo:(NSMutableDictionary *)userInfo;
@end

@interface FluxRegisterUsernameViewController : UIViewController<
    UITableViewDelegate, UITextFieldDelegate>{
    IBOutlet UITableView* usernameTableView;
    id __unsafe_unretained delegate;
    NSString*username;
    BOOL showUernamePrompt;
        
    BOOL sent;
    IBOutlet UIImageView *profileImageView;
}
    
@property (unsafe_unretained) id <FluxRegisterUsernameViewDelegate> delegate;
@property (nonatomic, strong) NSString *suggestedUsername;
@property (nonatomic, strong) NSMutableDictionary*userInfo;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;


@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;


- (IBAction)createAccountButtonAction:(id)sender;





@end
