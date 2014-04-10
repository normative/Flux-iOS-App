//
//  FluxPrivacyPolicyViewController.m
//  Flux
//
//  Created by Kei Turner on 2014-04-09.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxPrivacyPolicyViewController.h"

@implementation FluxPrivacyPolicyViewController


- (void)viewDidLoad{
    [super viewDidLoad];
    self.screenName = @"Privacy Policy";
    
    NSString *fullURL = @"http://www.smlr.is/privacy-policy-m/";
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:requestObj];
    
    [headerLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:headerLabel.font.pointSize]];
    
}
- (IBAction)doneButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
