//
//  FluxPrivacyPolicyViewController.h
//  Flux
//
//  Created by Kei Turner on 2014-04-09.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@interface FluxPrivacyPolicyViewController : GAITrackedViewController
@property (strong, nonatomic) IBOutlet UIWebView *webView;
- (IBAction)doneButtonAction:(id)sender;

@end
