//
//  FluxRegisterUsernameViewController.h
//  Flux
//
//  Created by Kei Turner on 1/6/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxDataManager.h"

@class FluxRegisterUsernameViewController;
@protocol FluxRegisterUsernameViewDelegate <NSObject>
@optional
- (void)RegisterUsernameView:(FluxRegisterUsernameViewController*)usernameView didAcceptAddUsernameToUserInfo:(NSMutableDictionary *)userInfo;
@end

@interface FluxRegisterUsernameViewController : UIViewController<
    UITableViewDelegate, UITextFieldDelegate>{
    IBOutlet UITableView* usernameTableView;
    IBOutlet UIButton *createAccountButton;
    id __unsafe_unretained delegate;
    NSString*username;
    BOOL showUernamePrompt;
        
    BOOL sent;
}
    
@property (unsafe_unretained) id <FluxRegisterUsernameViewDelegate> delegate;
@property (nonatomic, strong)    NSMutableDictionary*userInfo;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
- (IBAction)createAccountButtonAction:(id)sender;

@end
