//
//  FluxRegisterUsernameViewController.m
//  Flux
//
//  Created by Kei Turner on 1/6/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxRegisterUsernameViewController.h"
#import "FluxTextFieldCell.h"
#import "UICKeyChainStore.h"
#import "ProgressHUD.h"



@interface FluxRegisterUsernameViewController ()

@end

@implementation FluxRegisterUsernameViewController

@synthesize delegate;

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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    [createAccountButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:createAccountButton.titleLabel.font.pointSize]];
    
    [self setupContainerView];
    
    CGFloat ratio = 1.0;
    NSLayoutConstraint *constraint = [NSLayoutConstraint
                                      constraintWithItem:profileImageView
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:profileImageView
                                      attribute:NSLayoutAttributeHeight
                                      multiplier:ratio
                                      constant:0];
    constraint.priority = 1000;
    [profileImageView.superview addConstraint:constraint];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    if ([[self.userInfo objectForKey:@"partner"] isEqualToString:TwitterService]) {
        [self getTwitterProfilePic];
    }
    else if ([[self.userInfo objectForKey:@"partner"] isEqualToString:FacebookService]){
        [self getFacebookProfilePic];
    }
    else{
        
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.screenName = @"Register Unique Username View";
}

-(void) viewWillDisappear:(BOOL)animated {
//    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound && !sent) {
//        if ([delegate respondsToSelector:@selector(RegisterUsernameView:didAcceptAddUsernameToUserInfo:)]) {
//            [delegate RegisterUsernameView:self didAcceptAddUsernameToUserInfo:nil];
//        }
//    }
    [super viewWillDisappear:animated];
}

- (void)backAction{
    if ([delegate respondsToSelector:@selector(RegisterUsernameView:didAcceptAddUsernameToUserInfo:)]) {
        [delegate RegisterUsernameView:self didAcceptAddUsernameToUserInfo:nil];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupContainerView{
    usernameBorderLayer = [CALayer layer];
    
    usernameBorderLayer.cornerRadius = 5;
    usernameBorderLayer.borderWidth = 0.5;
    usernameBorderLayer.borderColor = [UIColor whiteColor].CGColor;
    usernameBorderLayer.frame = CGRectMake(0, 0, usernameContainerView.frame.size.width, usernameContainerView.frame.size.height);
    [usernameContainerView.layer addSublayer:usernameBorderLayer];
    
    
    theTextField = [[FluxTextField alloc]initWithFrame:usernameContainerView.bounds andPlaceholderText:@"username"];
    
    [theTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [theTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [theTextField setKeyboardType:UIKeyboardTypeDefault];
    [theTextField setSecureTextEntry:NO];
    [theTextField setReturnKeyType:UIReturnKeyGo];
    
    [theTextField setDelegate:self];
    theTextField.textAlignment = NSTextAlignmentCenter;
    [theTextField becomeFirstResponder];
    [usernameContainerView addSubview:theTextField];
    
    [checkMarkImageView setHidden:YES];
    [activityView startAnimating];
    [activityView setHidden:YES];
}


#pragma mark Text Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    //only letters and numbers
    NSCharacterSet *blockedCharacters = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    if (!([string rangeOfCharacterFromSet:blockedCharacters].location == NSNotFound) || [string isEqualToString:@"."] || [string isEqualToString:@"\n"]) {
        return NO;
    }
    
    NSString * text;
    //hit backspace
    if (range.length>0) {
        text = [textField.text substringToIndex:textField.text.length-1];
    }
    //typed a character
    else{
        text = [textField.text stringByAppendingString:string];
    }
    
    if (text.length > 16) {
        return NO;
    }
    
    username = text;
    [checkMarkImageView setHidden:YES];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self createAccountButtonAction:nil];
    return NO;
}

- (void)checkUsernameUniqueness{
    if (theTextField.text.length > 3) {
        [activityView setHidden:NO];
        
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setUsernameUniquenessComplete:^(BOOL unique, NSString*suggestion, FluxDataRequest*completedRequest){
            if (unique) {
                if (showUernamePrompt) {
                    showUernamePrompt = NO;
                }
                [checkMarkImageView setHidden:NO];
                [self performSelector:@selector(proceed) withObject:nil afterDelay:0.2];
            }
            
            else{
                showUernamePrompt = YES;
                [checkMarkImageView setHidden:YES];
                [ProgressHUD showError:@"This username has already been taken"];
            }
            [activityView setHidden:YES];
        }];
        [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            [activityView setHidden:YES];
            [checkMarkImageView setHidden:YES];
            NSLog(@"Unique lookup failed with error %d", (int)[e code]);
            [ProgressHUD showError:@"Something happened when checking for usernames, try again in a few minutes."];
        }];
        [self.fluxDataManager checkUsernameUniqueness:username withDataRequest:dataRequest];
    }
    else{
        [ProgressHUD showError:@"Usernames must be at least 4 characters"];
    }
}

#pragma mark - Profile Picture Methods

- (void)getFacebookProfilePic{
    NSString*profileImageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large",[self.userInfo objectForKey:@"username"]];
    
    dispatch_async
    (dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData =
        [NSData dataWithContentsOfURL:
         [NSURL URLWithString:profileImageUrl]];
        
        UIImage *image = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2;
            profileImageView.clipsToBounds = YES;
            profileImageView.image = image;
            [self.userInfo setObject:image forKey:@"profilePic"];
        });
    });
}

- (void)getTwitterProfilePic{
    
    
    username = [self.userInfo objectForKey:@"username"];
    ACAccount*acct = (ACAccount*)[self.userInfo objectForKey:@"account"];

    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"@"/1.1/users/show.json"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:username, @"screen_name",nil];
    
    SLRequest *aRequest  = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                              requestMethod:SLRequestMethodGET
                                                        URL:url
                                                 parameters:params];
    [aRequest setAccount:acct];
    [aRequest performRequestWithHandler:
     ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
         if (responseData) {
             NSDictionary *user = [NSJSONSerialization JSONObjectWithData:responseData
                                                                  options:NSJSONReadingAllowFragments
                                                                    error:NULL];
             
             NSString *profileImageUrl = [user objectForKey:@"profile_image_url"];
             profileImageUrl = [profileImageUrl stringByReplacingCharactersInRange:[profileImageUrl rangeOfString:@"_normal" options:NSBackwardsSearch] withString:@"_bigger"];
             
             dispatch_async
             (dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                 NSData *imageData =
                 [NSData dataWithContentsOfURL:
                  [NSURL URLWithString:profileImageUrl]];

                 UIImage *image = [UIImage imageWithData:imageData];

                 dispatch_async(dispatch_get_main_queue(), ^{
                     profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2;
                     profileImageView.clipsToBounds = YES;
                     profileImageView.image = image;
                     [self.userInfo setObject:image forKey:@"profilePic"];
                 });
             });
         }
     }];
}

- (void)proceed{
    [self.userInfo setObject:username forKey:@"username"];
    if ([delegate respondsToSelector:@selector(RegisterUsernameView:didAcceptAddUsernameToUserInfo:)]) {
        [delegate RegisterUsernameView:self didAcceptAddUsernameToUserInfo:self.userInfo];
    }
    sent = YES;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)createAccountButtonAction:(id)sender {
    [self checkUsernameUniqueness];
}

@end
