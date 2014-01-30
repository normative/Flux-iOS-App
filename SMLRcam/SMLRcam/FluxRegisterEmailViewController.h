//
//  FluxRegisterEmailViewController.h
//  Flux
//
//  Created by Kei Turner on 12/9/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"
#import "FluxDataManager.h"
#import "FluxRegisterUsernameViewController.h"


@class FluxRegisterEmailViewController;
@protocol FluxRegisterEmailViewDelegate <NSObject>
@optional
- (void)RegisterEmailView:(FluxRegisterEmailViewController*)emailView didAddToUserInfo:(NSMutableDictionary *)userInfo;
@end

@interface FluxRegisterEmailViewController : GAITrackedViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, FluxRegisterUsernameViewDelegate>{
    IBOutlet UITableView* emailTableView;
    id __unsafe_unretained delegate;
    NSString*email;
    
    BOOL sent;
}
@property (unsafe_unretained) id <FluxRegisterEmailViewDelegate> delegate;

@property (nonatomic, strong) FluxDataManager *fluxDataManager;
@property (nonatomic, strong)    NSMutableDictionary*userInfo;
- (IBAction)createAccountButtonAction:(id)sender;

@end
