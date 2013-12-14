//
//  FluxRegisterEmailViewController.h
//  Flux
//
//  Created by Kei Turner on 12/9/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxRegisterEmailViewController;
@protocol FluxRegisterEmailViewDelegate <NSObject>
@optional
- (void)RegisterEmailView:(FluxRegisterEmailViewController*)emailView didAcceptAddEmailToUserInfo:(NSMutableDictionary *)userInfo;
@end

@interface FluxRegisterEmailViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>{
    IBOutlet UITableView* emailTableView;
    IBOutlet UIButton *createAccountButton;
    id __unsafe_unretained delegate;
    NSString*email;
    
    BOOL sent;
}
@property (unsafe_unretained) id <FluxRegisterEmailViewDelegate> delegate;
@property (nonatomic, strong)    NSMutableDictionary*userInfo;
- (IBAction)createAccountButtonAction:(id)sender;

@end
