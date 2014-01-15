//
//  FluxSocialManager.m
//  Flux
//
//  Created by Kei Turner on 11/14/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxSocialManager.h"
#import "UICKeyChainStore.h"
#import "UIActionSheet+Blocks.h"

#define ERROR_TITLE_MSG @"Uh oh..."
#define ERROR_NO_ACCOUNTS @"You must add a Twitter account in the Settings app to sign in with Twitter"
#define ERROR_PERM_ACCESS @"We weren't granted access your twitter accounts"
#define ERROR_OK @"OK"

typedef enum FluxSocialManagerReturnType : NSUInteger {
    no_request_specified = 0,
    returnTypeBlock = 1,
    returnTypeDelegate = 2,
} FluxSocialManagerReturnType;

@implementation FluxSocialManager

@synthesize delegate;

- (id)init{
    self = [super init];
    
    id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    
    
    if ([appDelegate respondsToSelector:@selector(window)])
		self.window = [appDelegate performSelector:@selector(window)];
	else self.window = [[UIApplication sharedApplication] keyWindow];
    
    self.TWAccountStore = [[ACAccountStore alloc] init];
    [self.TWAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    self.TWApiManager = [[TWAPIManager alloc] init];
    
    return self;
}

#pragma mark - Linking Social Accounts

#pragma mark Twitter

- (void)linkTwitter{
    [self linkTwitterWithReturnType:returnTypeDelegate];
}


- (void)linkTwitterWithReturnType:(FluxSocialManagerReturnType)returnType{
    
    NSString*username = [UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService];
    if (username) {
        if (returnType == returnTypeBlock) {
            if (self.socialLoginDidComplete)
            {
                self.socialLoginDidComplete(username);
            }
        }
        else{
            if ([delegate respondsToSelector:@selector(SocialManager:didLinkTwitterAccountWithUsername:)]) {
                [delegate SocialManager:self didLinkTwitterAccountWithUsername:username];
            }
        }
        return;
    }
    
    
    if (![TWAPIManager isLocalTwitterAccountAvailable]) {
        if (returnType == returnTypeBlock) {
            if (self.socialLoginDidFail)
            {
                self.socialLoginDidFail(nil, TwitterService);
            }
        }
        else{
            NSLog(@"You were not granted access to the Twitter accounts.");
            if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                [delegate SocialManager:self didFailToLinkSocialAccount:@"Twitter"];
            }
        }
        
        
        return;
    }
    
    
    [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if (self.TWAccounts.count > 1) {
                    
                    NSMutableArray*accountNames = [[NSMutableArray alloc]init];
                    for (ACAccount *acct in self.TWAccounts) {
                        [accountNames addObject:acct.username];
                    }
                    
//                    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
//                    
//                    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
//                    [sheet setTag:returnType];
//                    [sheet showInView:self.window];
                    
                    [UIActionSheet showInView:self.window
                                    withTitle:@"Choose an Account:"
                            cancelButtonTitle:@"Cancel"
                       destructiveButtonTitle:nil
                            otherButtonTitles:accountNames
                                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                         
                                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                                             [self loginWithTwitterForAccountIndex:buttonIndex andReturnType:returnType];
                                         }
                                         else{
                                             if (returnType == returnTypeBlock) {
                                                 if (self.socialLoginDidFail)
                                                 {
                                                     self.socialLoginDidFail(nil, TwitterService);
                                                 }
                                             }
                                             else{
                                                 if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                                                     [delegate SocialManager:self didFailToLinkSocialAccount:TwitterService];
                                                 }
                                             }
                                         }
                                     }];
                }
                else{
                    [self loginWithTwitterForAccountIndex:0 andReturnType:returnType];
                }
            }
            else {
                if (returnType == returnTypeBlock) {
                    if (self.socialLoginDidFail)
                    {
                        self.socialLoginDidFail(nil, TwitterService);
                    }
                }
                else{
                    if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                        [delegate SocialManager:self didFailToLinkSocialAccount:@"Twitter"];
                    }
                    
                    NSLog(@"You were not granted access to the user's Twitter accounts.");
                }
                
            }
        });
    }];
}

- (void)loginWithTwitterForAccountIndex:(int)index andReturnType:(FluxSocialManagerReturnType)returnType{
    [self.TWApiManager performReverseAuthForAccount:self.TWAccounts[index] withHandler:^(NSData *responseData, NSError *error) {
        if (responseData) {
            NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            
            NSLog(@"Reverse Auth process returned: %@", responseStr);
            NSMutableArray *parts = [[responseStr componentsSeparatedByString:@"&"] mutableCopy];
            for (int i = 0; i<parts.count; i++) {
                NSString*string = (NSString*)[parts objectAtIndex:i];
                NSRange range = [string rangeOfString:@"="];
                [parts replaceObjectAtIndex:i withObject:(NSString*)[string substringFromIndex:range.location+1]];
            }
            
            [UICKeyChainStore setString:[parts objectAtIndex:0] forKey:FluxTokenKey service:TwitterService];
            [UICKeyChainStore setString:[parts objectAtIndex:3] forKey:FluxUsernameKey service:TwitterService];
            
            if (returnType == returnTypeBlock) {
                if (self.socialLoginDidComplete)
                {
                    self.socialLoginDidComplete((NSString*)[parts objectAtIndex:3]);
                }
            }
            else{
                //call delegate
                if ([delegate respondsToSelector:@selector(SocialManager:didLinkTwitterAccountWithUsername:)]) {
                    [delegate SocialManager:self didLinkTwitterAccountWithUsername:(NSString*)[parts objectAtIndex:3]];
                }
            }
            
            
        }
        else {
            if (returnType == returnTypeBlock) {
                if (self.socialLoginDidFail)
                {
                    self.socialLoginDidFail(error, TwitterService);
                }
            }
            else{
                NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
                
                if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                    [delegate SocialManager:self didFailToLinkSocialAccount:@"Twitter"];
                }
            }
            
        }
    }];
}

- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block
{
    ACAccountType *twitterType = [self.TWAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    ACAccountStoreRequestAccessCompletionHandler handler = ^(BOOL granted, NSError *error) {
        if (granted) {
            self.TWAccounts = [self.TWAccountStore accountsWithAccountType:twitterType];
        }
        
        block(granted);
    };
    
    //  This method changed in iOS6. If the new version isn't available, fall back to the original (which means that we're running on iOS5+).
    [self.TWAccountStore requestAccessToAccountsWithType:twitterType options:nil completion:handler];
}


#pragma mark Facebook

- (void)linkFacebook{
    [self linkFacebookWithReturnType:returnTypeDelegate];
}

- (void)linkFacebookWithReturnType:(FluxSocialManagerReturnType)returnType{
    if (!FBSession.activeSession.isOpen) {
        if (FBSession.activeSession.state != FBSessionStateCreated) {
            // Create a new, logged out session.
            FBSession.activeSession = [[FBSession alloc] init];
        }
        
        // if the session isn't open, let's open it now and present the login UX to the user
        NSArray *permissions = [NSArray arrayWithObjects:@"email", nil];
        [FBSession openActiveSessionWithReadPermissions:permissions
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session,
           FBSessionState state, NSError *error) {
             if (!error) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (FBSession.activeSession.isOpen) {
                         [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                             if (!error) {
                                 [UICKeyChainStore setString:FBSession.activeSession.accessTokenData.accessToken forKey:FluxTokenKey service:FacebookService];
                                 [UICKeyChainStore setString:user.username forKey:FluxUsernameKey service:FacebookService];
                                 [UICKeyChainStore setString:user.name forKey:FluxNameKey service:FacebookService];
                                 
                                 //call delegate
                                 if (returnType == returnTypeBlock) {
                                     if (self.socialLoginDidComplete)
                                     {
                                         self.socialLoginDidComplete(user.username);
                                     }
                                 }
                                 else{
                                     if ([delegate respondsToSelector:@selector(SocialManager:didLinkFacebookAccountWithName:)]) {
                                         [delegate SocialManager:self didLinkFacebookAccountWithName:user.name];
                                     }
                                 }
                             }
                             
                             else{
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     if (returnType == returnTypeBlock) {
                                         if (self.socialLoginDidFail)
                                         {
                                             self.socialLoginDidFail(error, FacebookService);
                                         }
                                     }
                                     else{
                                         NSLog(@"Facebook Link Error: %@",error.localizedDescription);
                                         if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                                             [delegate SocialManager:self didFailToLinkSocialAccount:@"Facebook"];
                                         }
                                     }
                                 });
                                 
                             }
                         }];
                     }
                 });
             }
             else{
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (returnType == returnTypeBlock) {
                         if (self.socialLoginDidFail)
                         {
                             self.socialLoginDidFail(error, FacebookService);
                         }
                     }
                     else{
                         NSLog(@"Facebook Link Error: %@",error.localizedDescription);
                         if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                             [delegate SocialManager:self didFailToLinkSocialAccount:@"Facebook"];
                         }
                     }
                 });
                 
             }
         }];
    }
}

#pragma mark - Social Posting
- (void)socialPostTo:(NSArray*)socialPartners withStatus:(NSString*)status andImage:(UIImage*)image{
    outstandingPosts = [socialPartners mutableCopy];
    posts = [socialPartners mutableCopy];
    
    if ([socialPartners containsObject:TwitterService]) {
        [self postToTwitterWithStatus:status andImage:image];
    }
    if ([socialPartners containsObject:FacebookService]) {
        [self postToFacebookWithStatus:status andImage:image];
    }
}

- (void)completedRequestWithType:(NSString*)socialType{
    [outstandingPosts removeObject:socialType];
    
    if (outstandingPosts == 0) {
        if ([delegate respondsToSelector:@selector(SocialManager:didMakeSocialPosts:)]) {
            [delegate SocialManager:self didMakeSocialPosts:posts];
        }
    }
}

- (void)failedToCompleteRequestWithType:(NSString*)socialType{
    [outstandingPosts removeObject:socialType];
    [posts removeObject:socialType];
    
    if (outstandingPosts == 0) {
        if ([delegate respondsToSelector:@selector(SocialManager:didFailToMakeSocialPostWithType:)]) {
            [delegate SocialManager:self didFailToMakeSocialPostWithType:socialType];
        }
    }
}

#pragma mark Twitter
- (void)postToTwitterWithStatus:(NSString*)status andImage:(UIImage*)image{


    //to get around using a strong reference to self in a block warning
    __unsafe_unretained typeof(self) weakSelf = self;
    
    [self setSocialLoginDidComplete:^(NSString*username){
        ACAccountType *twitterType =
        [weakSelf.TWAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        SLRequestHandler requestHandler =
        ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if (responseData) {
                NSInteger statusCode = urlResponse.statusCode;
                if (statusCode >= 200 && statusCode < 300) {
                    NSDictionary *postResponseData =
                    [NSJSONSerialization JSONObjectWithData:responseData
                                                    options:NSJSONReadingMutableContainers
                                                      error:NULL];
                    NSLog(@"[SUCCESS!] Created Tweet with ID: %@", postResponseData[@"id_str"]);
                    [weakSelf completedRequestWithType:TwitterService];

                    
                }
                else {
                    NSLog(@"[ERROR] Server responded: status code %d %@", statusCode,
                          [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
                    [weakSelf failedToCompleteRequestWithType:TwitterService];
                }
            }
            else {
                NSLog(@"[ERROR] An error occurred while posting: %@", [error localizedDescription]);
                [weakSelf failedToCompleteRequestWithType:TwitterService];
            }
        };
        
        ACAccountStoreRequestAccessCompletionHandler accountStoreHandler =
        ^(BOOL granted, NSError *error) {
            if (granted) {
                NSArray *accounts = [weakSelf.TWAccountStore accountsWithAccountType:twitterType];
                NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                              @"/1.1/statuses/update_with_media.json"];
                NSDictionary *params = @{@"status" : status};
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                        requestMethod:SLRequestMethodPOST
                                                                  URL:url
                                                           parameters:params];
                NSData *imageData = UIImageJPEGRepresentation(image, 1.f);
                [request addMultipartData:imageData
                                 withName:@"media[]"
                                     type:@"image/jpeg"
                                 filename:@"image.jpg"];
                
                ACAccount* account;
                for (ACAccount *acct in weakSelf.TWAccounts) {
                    if ([username isEqualToString:acct.username]) {
                        account = acct;
                    }
                }
                [request setAccount:account];
                
                
                
                [request setAccount:[accounts lastObject]];
                [request performRequestWithHandler:requestHandler];
            }
            else {
                
                NSLog(@"[ERROR] An error occurred while asking for user authorization: %@",
                      [error localizedDescription]);
                [weakSelf failedToCompleteRequestWithType:TwitterService];
            }
        };
        
        [weakSelf.TWAccountStore requestAccessToAccountsWithType:twitterType
                                                     options:NULL
                                                  completion:accountStoreHandler];
    }];
    
    [self setSocialLoginDidFail:^(NSError*e,NSString*service){
        [weakSelf failedToCompleteRequestWithType:service];
    }];
    
    [self linkTwitterWithReturnType:returnTypeBlock];
}

#pragma mark Facebook
- (void)postToFacebookWithStatus:(NSString*)status andImage:(UIImage*)image{
    
    //to get around using a strong reference to self in a block warning
    __unsafe_unretained typeof(self) weakSelf = self;
    
    [self setSocialLoginDidComplete:^(NSString*username){
        NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
        [params setObject:status forKey:@"message"];
        [params setObject:UIImagePNGRepresentation(image) forKey:@"picture"];
        
        [FBRequestConnection startWithGraphPath:@"me/photos"
                                     parameters:params
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection,
                                                  id result,
                                                  NSError *error)
         {
             if (error)
             {
                 NSString * errorstring = [NSString stringWithFormat:@"Error: %@",error.localizedDescription];
                 NSLog(@"Facebook Post Error: %@",errorstring);
                 [weakSelf failedToCompleteRequestWithType:FacebookService];
             }
             else
             {
                 [weakSelf completedRequestWithType:FacebookService];
             }
         }];
    }];
    
    [self setSocialLoginDidFail:^(NSError*e, NSString*service){
        if ([weakSelf.delegate respondsToSelector:@selector(SocialManager:didFailToMakeSocialPostWithType:)]) {
            [weakSelf.delegate SocialManager:weakSelf didFailToMakeSocialPostWithType:FacebookService];
        }
    }];
    
    [self linkFacebookWithReturnType:returnTypeBlock];
    
    
    
}

@end
