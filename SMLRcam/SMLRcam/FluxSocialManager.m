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
#import "FluxDataManager.h"
#import "UICKeyChainStore.h"
#import "ProgressHUD.h"

#define ERROR_TITLE_MSG @"Uh oh..."
#define ERROR_NO_ACCOUNTS @"You must add a Twitter account in the Settings app to sign in with Twitter"
#define ERROR_PERM_ACCESS @"We weren't granted access your twitter accounts"
#define ERROR_OK @"OK"

typedef enum FluxSocialManagerReturnType : NSUInteger {
    smr_no_request_specified = 0,
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
    self.TWApiManager = [[TWAPIManager alloc] init];
    
    return self;
}

#pragma mark Registering with Social Accounts

#pragma mark Twitter
- (void)registerWithTwitter{
    isRegister = YES;
    [self linkTwitter];
}

#pragma mark Facebook
- (void)registerWithFacebook{
    isRegister = YES;
    [self linkFacebook];
}



#pragma mark - Linking Social Accounts

#pragma mark Twitter

- (void)linkTwitter{
    
    NSString*username = [UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService];
    
    //If we've already linked then return the active account info
    if (username) {
        if (!isRegister) {
            if ([delegate respondsToSelector:@selector(SocialManager:didLinkTwitterAccountWithUsername:)]) {
                [delegate SocialManager:self didLinkTwitterAccountWithUsername:[UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService]];
                return;
            }
            if ([delegate respondsToSelector:@selector(SocialManager:didLinkTwitterAccount:)]) {
                //should always be granted (previous TW account exists in the keychain)
                [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (granted) {
                            for (ACAccount *acct in self.TWAccounts) {
                                if ([[username lowercaseString] isEqualToString:[acct.username lowercaseString]]) {
                                    [delegate SocialManager:self didLinkTwitterAccount:acct];
                                    return;
                                }
                            }
                        }
                    });
                }];
            }
        }
    }
    
    
    if (![TWAPIManager isLocalTwitterAccountAvailable]) {
        NSLog(@"You were not granted access to the Twitter accounts.");
        if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
            [delegate SocialManager:self didFailToLinkSocialAccount:@"Twitter"];
        }
        return;
    }
    
    
    [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if (self.TWAccounts.count > 1) {
                    
                    NSMutableArray*accountNames = [[NSMutableArray alloc]init];
                    for (ACAccount *acct in self.TWAccounts) {
                        [accountNames addObject:acct.accountDescription];
                    }
                    
                    [UIActionSheet showInView:self.window
                                    withTitle:@"Choose an Account:"
                            cancelButtonTitle:@"Cancel"
                       destructiveButtonTitle:nil
                            otherButtonTitles:accountNames
                                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                         
                                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                                             [self loginWithTwitterForAccountIndex:buttonIndex];
                                         }
                                         else{
                                             if (isRegister) {
                                                 if ([delegate respondsToSelector:@selector(SocialManager:didFailToRegisterSocialAccount:)]) {
                                                     [delegate SocialManager:self didFailToRegisterSocialAccount:@"Twitter"];
                                                 }
                                             }
                                             
                                         }
                                     }];
                }
                else{
                    if (self.TWAccounts.count > 0) {
                        [self loginWithTwitterForAccountIndex:0];
                    }
                    else{
                        if (isRegister) {
                            if ([delegate respondsToSelector:@selector(SocialManager:didFailToRegisterSocialAccount:)]) {
                                [delegate SocialManager:self didFailToRegisterSocialAccount:@"Twitter"];
                            }
                        }
                        else{
                            if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                                [delegate SocialManager:self didFailToLinkSocialAccount:@"Twitter"];
                            }
                        }
                        
                        
                        NSLog(@"The user has no accounts");
                    }
                    
                }
            }
            else {
                if (isRegister) {
                    if ([delegate respondsToSelector:@selector(SocialManager:didFailToRegisterSocialAccount:)]) {
                        [delegate SocialManager:self didFailToRegisterSocialAccount:@"Twitter"];
                    }
                }
                else{
                    if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                        [delegate SocialManager:self didFailToLinkSocialAccount:@"Twitter"];
                    }
                }
                
                
                NSLog(@"You were not granted access to the user's Twitter accounts.");
            }
        });
    }];
}

- (void)createAliasWithName:(NSString *)alias_name andServiceID:(int) service_id
{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSString*str = [NSString stringWithFormat:@"Ignoring alias creation for external name %@. Failed with error %d",alias_name, (int)[e code]];
        NSLog(str);
        
    }];
    [[FluxDataManager theFluxDataManager] createAliasWithName: alias_name andServiceID: service_id andRequest: request];
}

- (void)loginWithTwitterForAccountIndex:(int)index{
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
            
            if (parts.count > 1) {
                
                // [UICKeyChainStore setString:[userInfo objectForKey:@"username"] forKey:FluxUsernameKey service:TwitterService];
                UICKeyChainStore *store = [UICKeyChainStore keyChainStoreWithService:TwitterService];
                [store setString:[parts objectAtIndex:3] forKey:FluxUsernameKey];
                [store setString:[parts objectAtIndex:0] forKey:FluxAccessTokenKey];
                [store setString:[parts objectAtIndex:1] forKey:FluxAccessTokenSecretKey];
                [store synchronize];

                
                //call delegate
                if (isRegister) {
                    if ([delegate respondsToSelector:@selector(SocialManager:didRegisterTwitterAccountWithUserInfo:)]) {
                        NSDictionary*userInfo = [[NSDictionary alloc]initWithObjectsAndKeys:[parts objectAtIndex:0], @"token", [parts objectAtIndex:3], @"username",[parts objectAtIndex:1], @"secret", [self.TWAccounts objectAtIndex:index] , @"account",[NSString stringWithFormat:@"@%@",[parts objectAtIndex:3]], @"socialName", nil];
                        [delegate SocialManager:self didRegisterTwitterAccountWithUserInfo:userInfo];
                    }
                }
                else{
                    [self createAliasWithName: [parts objectAtIndex:3] andServiceID: 2];
                    if ([delegate respondsToSelector:@selector(SocialManager:didLinkTwitterAccountWithUsername:)]) {
                        [delegate SocialManager:self didLinkTwitterAccountWithUsername:(NSString*)[parts objectAtIndex:3]];
                    }
                }
            }
            else{
                if (parts.count) {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Uh oh..."
                                                                      message:@"It looks like your password is missing from your Twitter account. Open the Settings app and add your password to your Twitter account to share with Twitter."
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                    NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [parts objectAtIndex:0]);
                }
                //call delegate
                if (isRegister) {
                    if ([delegate respondsToSelector:@selector(SocialManager:didFailToRegisterSocialAccount:)]) {
                        [delegate SocialManager:self didFailToRegisterSocialAccount:@"Twitter"];
                    }
                }
                else{
                    if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                        [delegate SocialManager:self didFailToLinkSocialAccount:@"Twitter"];
                    }
                }
                
            }
            

        }
        else {
            NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
            //call delegate
            if (isRegister) {
                if ([delegate respondsToSelector:@selector(SocialManager:didFailToRegisterSocialAccount:)]) {
                    [delegate SocialManager:self didFailToRegisterSocialAccount:@"Twitter"];
                }
            }
            else{
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

- (void)linkFacebookWithPublishPermissions{
    NSArray *permissions = [NSArray arrayWithObjects:@"publish_actions ", nil];
    //else, check if the active session has publush permission
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        // there is no active session, so start a new one with publish permissions
        [self checkIfActiveFBSessionHasPublishPermission];
    }
    else{
        if (FBSession.activeSession.state != FBSessionStateCreated) {
            // Create a new, logged out session.
            FBSession.activeSession = [[FBSession alloc] init];
        }
        
        
        [FBSession openActiveSessionWithPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:YES completionHandler:
         ^(FBSession *session,
           FBSessionState state, NSError *error) {
             if (!error) {
                 if (FBSession.activeSession.isOpen) {
                     [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                         if (!error) {
                             [UICKeyChainStore setString:FBSession.activeSession.accessTokenData.accessToken forKey:FluxTokenKey service:FacebookService];
                             [UICKeyChainStore setString:user.username forKey:FluxUsernameKey service:FacebookService];
                             [UICKeyChainStore setString:user.name forKey:FluxNameKey service:FacebookService];
                             
                             [self createAliasWithName:user.username andServiceID: 3];
                             if ([delegate respondsToSelector:@selector(SocialManagerDidAddFacebookPublishPermissions:)]) {
                                 [delegate SocialManagerDidAddFacebookPublishPermissions:self];
                             }
                             
                         }
                         
                         else{
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 NSLog(@"Facebook Publish Link Error: %@",error.localizedDescription);
                                 if ([delegate respondsToSelector:@selector(SocialManagerDidFailToAddAddFacebookPublishPermissions:andDidShowError:)]) {
                                     [delegate SocialManagerDidFailToAddAddFacebookPublishPermissions:self andDidShowError:NO];
                                 }
                                 
                             });
                             
                         }
                     }];
                 }
                 else{
                     
                 }
             }
             else{
                 NSLog(@"Facebook Publish Link Error: %@",error.localizedDescription);
                 if ([delegate respondsToSelector:@selector(SocialManagerDidFailToAddAddFacebookPublishPermissions:)]) {
                     [delegate SocialManagerDidFailToAddAddFacebookPublishPermissions:self andDidShowError:NO];
                 }
             }
         }];
    }
}

- (void)checkIfActiveFBSessionHasPublishPermission{
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error){
                                  NSDictionary *permissions= [(NSArray *)[result data] objectAtIndex:0];
                                  if (![permissions objectForKey:@"publish_actions"]){
                                      // Publish permissions not found, ask for publish_actions
                                      [self addPublishPermissionToActiveFBSession];
                                      
                                  } else {
                                      // Publish permissions found
                                      if ([delegate respondsToSelector:@selector(SocialManagerDidAddFacebookPublishPermissions:)]) {
                                          [delegate SocialManagerDidAddFacebookPublishPermissions:self];
                                      }
                                  }
                                  
                              } else {
                                  // There was an error, handle it
                                  // See https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"Facebook Link Error: %@",error.localizedDescription);
                                  NSLog(@"%@",[FBErrorUtility userMessageForError:error]);
                                  [ProgressHUD showError:[FBErrorUtility userMessageForError:error]];
                                  if ([delegate respondsToSelector:@selector(SocialManagerDidFailToAddAddFacebookPublishPermissions: andDidShowError:)]) {
                                      [delegate SocialManagerDidFailToAddAddFacebookPublishPermissions:self andDidShowError:YES];
                                  }
                              }
                          }];
}

- (void)addPublishPermissionToActiveFBSession{
    [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                          defaultAudience:FBSessionDefaultAudienceFriends
                                        completionHandler:^(FBSession *session, NSError *error) {
                                            if (!error) {
                                                if ([FBSession.activeSession.permissions
                                                     indexOfObject:@"publish_actions"] == NSNotFound){
                                                    // Permission not granted, tell the user we will not publish
                                                    NSString*str = [NSString stringWithFormat:@"Access to publish to facebook denied."];
                                                    [ProgressHUD showError:str];
                                                    NSLog(@"%@",[FBErrorUtility userMessageForError:error]);
                                                    if ([delegate respondsToSelector:@selector(SocialManagerDidFailToAddAddFacebookPublishPermissions:andDidShowError:)]) {
                                                        [delegate SocialManagerDidFailToAddAddFacebookPublishPermissions:self andDidShowError:YES];
                                                    }
                                                    
                                                } else {
                                                    // Permission granted
                                                    if ([delegate respondsToSelector:@selector(SocialManagerDidAddFacebookPublishPermissions:)]) {
                                                        [delegate SocialManagerDidAddFacebookPublishPermissions:self];
                                                    }
                                                }
                                                
                                            } else {
                                                // There was an error, handle it
                                                // See https://developers.facebook.com/docs/ios/errors/
                                                NSLog(@"Facebook Permissions request error: %@",error.localizedDescription);
                                                if ([delegate respondsToSelector:@selector(SocialManagerDidFailToAddAddFacebookPublishPermissions:andDidShowError:)]) {
                                                    [delegate SocialManagerDidFailToAddAddFacebookPublishPermissions:self andDidShowError:NO];
                                                }
                                            }
                                        }];
}

- (void)linkFacebook{
    NSString*username = [UICKeyChainStore stringForKey:FluxUsernameKey service:FacebookService];
    
    //If we've already linked then return the active account info
    if (username) {
        if (!isRegister) {
            if ([delegate respondsToSelector:@selector(SocialManager:didLinkFacebookAccountWithName:)]) {
                [delegate SocialManager:self didLinkFacebookAccountWithName:[UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService]];
                return;
            }
        }
    }
    
    if (!FBSession.activeSession.isOpen) {
        if (FBSession.activeSession.state != FBSessionStateCreated) {
            // Create a new, logged out session.
            FBSession.activeSession = [[FBSession alloc] init];
        }
        
        // if the session isn't open, let's open it now and present the login UX to the user
        //NSArray *permissions = [NSArray arrayWithObjects:@"email",@"publish_actions ", nil];
        NSArray *permissions = [NSArray arrayWithObjects:@"email",@"basic_info", nil];
        [FBSession openActiveSessionWithReadPermissions:permissions
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          /* handle success + failure in block */
                                          if (!error) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  if (FBSession.activeSession.isOpen) {
                                                      [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
                                                          if (!error) {
                                                              if (!isRegister) {
                                                                  [UICKeyChainStore setString:FBSession.activeSession.accessTokenData.accessToken forKey:FluxTokenKey service:FacebookService];
                                                                  [UICKeyChainStore setString:user.username forKey:FluxUsernameKey service:FacebookService];
                                                                  [UICKeyChainStore setString:user.name forKey:FluxNameKey service:FacebookService];
                                                              }
                                                              
                                                              
                                                              
                                                              
                                                              //call delegate
                                                              if (isRegister) {
                                                                  NSMutableDictionary*dict = [NSMutableDictionary dictionaryWithDictionary:user];
                                                                  [dict setObject:FBSession.activeSession.accessTokenData.accessToken forKey:@"token"];
                                                                  [dict setObject:user.name forKey:@"socialName"];
                                                                  [dict setObject:user.username forKey:@"uniqueSocialName"];
                                                                  if ([delegate respondsToSelector:@selector(SocialManager:didRegisterFacebookAccountWithUserInfo:)]) {
                                                                      [delegate SocialManager:self didRegisterFacebookAccountWithUserInfo:dict];
                                                                  }
                                                              }
                                                              else{
                                                                  [self createAliasWithName:user.username andServiceID: 3];
                                                                  if ([delegate respondsToSelector:@selector(SocialManager:didLinkFacebookAccountWithName:)]) {
                                                                      [delegate SocialManager:self didLinkFacebookAccountWithName:user.name];
                                                                  }
                                                              }
                                                              
                                                          }
                                                          
                                                          else{
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  NSLog(@"Facebook Link Error: %@",error.localizedDescription);
                                                                  if (isRegister) {
                                                                      if ([delegate respondsToSelector:@selector(SocialManager:didFailToRegisterSocialAccount:)]) {
                                                                          [delegate SocialManager:self didFailToRegisterSocialAccount:@"Facebook"];
                                                                      }
                                                                  }
                                                                  else{
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
                                                  NSLog(@"Facebook Link Error: %@",error.localizedDescription);
                                                  if (isRegister) {
                                                      if ([delegate respondsToSelector:@selector(SocialManager:didFailToRegisterSocialAccount:)]) {
                                                          [delegate SocialManager:self didFailToRegisterSocialAccount:@"Facebook"];
                                                      }
                                                  }
                                                  else{
                                                      if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                                                          [delegate SocialManager:self didFailToLinkSocialAccount:@"Facebook"];
                                                      }
                                                  }
                                                  
                                              });
                                              
                                          }
                                      }];
//        [FBSession openActiveSessionWithPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:YES completionHandler:
//         ^(FBSession *session,
//           FBSessionState state, NSError *error) {
//             
//         }];
    }
}

#pragma mark - Social Posting
//assumes there are active link sessions (should check before calling)
- (void)socialPostTo:(NSArray*)socialPartners withStatus:(NSString*)status andImage:(UIImage*)image andSnapshot:(BOOL)snapshot{
    outstandingPosts = [socialPartners mutableCopy];
    posts = [socialPartners mutableCopy];
    
    if ([socialPartners containsObject:TwitterService]) {
        [self postToTwitterWithStatus:status andImage:image];
    }
    if ([socialPartners containsObject:FacebookService]) {
        if (snapshot) {
//            [self checkFacebookPermissionsForPost:[NSDictionary dictionaryWithObjectsAndKeys:status, @"status", image, @"image", nil]];
            [self postSnapshotToFacebookWithStatus:status andImage:image];
        }
        else{
            [self postToFacebookWithStatus:status andImage:image];
        }
    }
}

- (void)socialPostTo:(NSArray*)socialPartners withStatus:(NSString*)status directedToUser:(NSString *)userid{
    outstandingPosts = [socialPartners mutableCopy];
    posts = [socialPartners mutableCopy];
    
    if ([socialPartners containsObject:TwitterService]) {
        [self postDMToTwitterUser:userid withMessage:status];
    }
    
    if ([socialPartners containsObject:FacebookService]) {
        [ProgressHUD showError:@"Can not direct messages in Facebook at this time"];
    }
}


- (void)completedRequestWithType:(NSString*)socialType{
    [outstandingPosts removeObject:socialType];
    
    if (outstandingPosts.count == 0) {
        if ([delegate respondsToSelector:@selector(SocialManager:didMakeSocialPosts:)]) {
            [delegate SocialManager:self didMakeSocialPosts:posts];
        }
    }
}

- (void)failedToCompleteRequestWithType:(NSString*)socialType andAlreadyShownError:(BOOL)alreadyShownError{
    [outstandingPosts removeObject:socialType];
    [posts removeObject:socialType];
    
    if (outstandingPosts == 0) {
        if ([delegate respondsToSelector:@selector(SocialManager:didFailToMakeSocialPostWithType: andDidShowError:)]) {
            [delegate SocialManager:self didFailToMakeSocialPostWithType:socialType andDidShowError:alreadyShownError];
        }
    }
}

#pragma mark Twitter
- (void)postToTwitterWithStatus:(NSString*)status andImage:(UIImage*)image{

    NSString *username = [UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService];
    
    
    ACAccountType *twitterType =
    [self.TWAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    self.TWAccounts = [self.TWAccountStore accountsWithAccountType:twitterType];
    
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
                [self completedRequestWithType:TwitterService];
                
                
            }
            else {
                NSLog(@"[ERROR] Server responded: status code %d %@", statusCode,
                      [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
                [self failedToCompleteRequestWithType:TwitterService andAlreadyShownError:NO];
            }
        }
        else {
            NSLog(@"[ERROR] An error occurred while posting: %@", [error localizedDescription]);
            [self failedToCompleteRequestWithType:TwitterService andAlreadyShownError:NO];
        }
    };
    
    ACAccountStoreRequestAccessCompletionHandler accountStoreHandler =
    ^(BOOL granted, NSError *error) {
        if (granted) {
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
            for (ACAccount *acct in self.TWAccounts) {
                if ([[username lowercaseString] isEqualToString:[acct.username lowercaseString]]) {
                    account = acct;
                    break;
                }
            }
            [request setAccount:account];
            [request performRequestWithHandler:requestHandler];
        }
        else {
            
            NSLog(@"[ERROR] An error occurred while asking for user authorization: %@",
                  [error localizedDescription]);
            [self failedToCompleteRequestWithType:TwitterService andAlreadyShownError:NO];
        }
    };
    
    [self.TWAccountStore requestAccessToAccountsWithType:twitterType
                                                     options:NULL
                                                  completion:accountStoreHandler];
}

- (void)postDMToTwitterUser:(NSString *)userid withMessage:(NSString*)text{
    
    NSString *username = [UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService];
    
    ACAccountType *twitterType =
    [self.TWAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    self.TWAccounts = [self.TWAccountStore accountsWithAccountType:twitterType];
    
    SLRequestHandler requestHandler =
    ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (responseData) {
            NSInteger statusCode = urlResponse.statusCode;
            if (statusCode >= 200 && statusCode < 300) {
                NSDictionary *postResponseData =
                [NSJSONSerialization JSONObjectWithData:responseData
                                                options:NSJSONReadingMutableContainers
                                                  error:NULL];
                NSLog(@"[SUCCESS!] Created DirectMessage with ID: %@", postResponseData[@"id_str"]);
                [self completedRequestWithType:TwitterService];
                
                
            }
            else {
                NSLog(@"[ERROR] Server responded: status code %d %@", statusCode,
                      [NSHTTPURLResponse localizedStringForStatusCode:statusCode]);
                [self failedToCompleteRequestWithType:TwitterService andAlreadyShownError:NO];
            }
        }
        else {
            NSLog(@"[ERROR] An error occurred while posting DM: %@", [error localizedDescription]);
            [self failedToCompleteRequestWithType:TwitterService andAlreadyShownError:NO];
        }
    };
    
    ACAccountStoreRequestAccessCompletionHandler accountStoreHandler =
    ^(BOOL granted, NSError *error) {
        if (granted) {
            NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/direct_messages/new.json"];
            NSDictionary *params = @{@"userid" : userid, @"text" : text};
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:url
                                                       parameters:params];
            
            ACAccount* account;
            for (ACAccount *acct in self.TWAccounts) {
                if ([[username lowercaseString] isEqualToString:[acct.username lowercaseString]]) {
                    account = acct;
                    break;
                }
            }
            [request setAccount:account];
            [request performRequestWithHandler:requestHandler];
        }
        else {
            
            NSLog(@"[ERROR] An error occurred while asking for user authorization: %@",
                  [error localizedDescription]);
            [self failedToCompleteRequestWithType:TwitterService andAlreadyShownError:NO];
        }
    };
    
    [self.TWAccountStore requestAccessToAccountsWithType:twitterType
                                                 options:NULL
                                              completion:accountStoreHandler];
}


#pragma mark Facebook

- (IBAction)ShareLinkWithAPICalls:(id)sender {
    // We will post on behalf of the user, these are the permissions we need:
    
}

//uses different workding than the standard image post
- (void)postSnapshotToFacebookWithStatus:(NSString*)status andImage:(UIImage*)image{
    //fb graph object post
    // Create an object
    if (!FBSession.activeSession.isOpen) {
        [FBSession openActiveSessionWithAllowLoginUI: NO];
    }
//    
//
//    
//    // can include any of the "publish" or "manage" permissions
//    NSArray *permissions =
//    [NSArray arrayWithObjects:@"publish_actions", nil];
//    
//    [[FBSession activeSession] reauthorizeWithPublishPermissions:permissions
//                                                 defaultAudience:FBSessionDefaultAudienceFriends
//                                               completionHandler:^(FBSession *session, NSError *error) {
//                                                   /* handle success + failure in block */
//                                               }];
    
    
    // Create an object
    NSMutableDictionary<FBOpenGraphObject> *picture = [FBGraphObject openGraphObjectForPost];
    
    // specify that this Open Graph object will be posted to Facebook
    picture.provisionedForPost = YES;
    
    // Add the standard object properties, including the image you just staged
    picture[@"og"] = @{ @"title":@"Flux", @"type":@"scene.scene", @"description":@"my description"};
    
    
    
    
    [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error) {
            NSLog(@"Successfuly staged image with staged URI: %@", [result objectForKey:@"uri"]);
            //Package image inside a dictionary, inside an array like we'll need it for the object
            NSArray *image = @[@{@"url": [result objectForKey:@"uri"], @"user_generated" : @"true" }];
            
            NSMutableDictionary<FBOpenGraphObject> *pictureObject = [FBGraphObject openGraphObjectForPost];
            
            // specify that this Open Graph object will be posted to Facebook
            pictureObject.provisionedForPost = YES;
            
            // Add the standard object properties
            pictureObject[@"og"] = @{ @"title":@"This is a title", @"type":@"fluxapp:scene", @"description":@"description", @"image":image };
            
            
            
            NSMutableDictionary<FBGraphObject> *action = [FBGraphObject graphObject];
            action[@"scene"] = pictureObject;
            [action setObject:@"true" forKey:@"fb:explicitly_shared"];
            [action setObject:status forKey:@"message"];
            
            [FBRequestConnection startForPostWithGraphPath:@"me/fluxapp:capture"
                                               graphObject:action
                                         completionHandler:^(FBRequestConnection *connection,
                                                             id result,
                                                             NSError *error) {
                                             if (!error) {
                                                 // Success, the restaurant has been liked
                                                 NSLog(@"Posted OG action, id: %@", [result objectForKey:@"id"]);
                                                 [self completedRequestWithType:FacebookService];
                                                 
                                             } else {
                                                 // An error occurred, we need to handle the error
                                                 // See: https://developers.facebook.com/docs/ios/errors
                                                 NSLog(@"Error: %@, %@",error.description, error.debugDescription);
                                                 [self failedToCompleteRequestWithType:FacebookService andAlreadyShownError:NO];
                                             }
                                         }];
        }
        else{
            NSLog(@"Error: %@, %@",error.description, error.debugDescription);
            [self failedToCompleteRequestWithType:FacebookService andAlreadyShownError:NO];
        }
        
    }];
}

//this won't work until we have an app backend from the looks of it
- (void)postToFacebookWithStatus:(NSString*)status andImage:(UIImage*)image{
    
    //link to SMLR post
////    [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
////        if (!error){
////            NSString *uri = [result valueForKey:@"uri"];
//    
//            NSMutableDictionary<FBOpenGraphObject> *object = [FBGraphObject openGraphObjectForPost];
//            object.provisionedForPost = YES;
//            object[@"type"] = @":<OBJECT_NAME>";
//            object[@"url"] = @"http://www.smlr.is/";
//            object[@"title"] = @"My Title";
//            
//            object[@"description"] = status;
//            object[@"user_generated"] = @"true";
//            
////            object[@"image"] = @[@{@"url": uri, @"user_generated":@"true"}];
//    
//            // for og:image we assign the image that we just staged, using the uri we got as a response
//            // the image has to be packed in a dictionary like this:
//            object[@"image"] = image;
//            
//            [FBRequestConnection startForPostOpenGraphObject:object
//                                           completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//                                               if (error)
//                                               {
//                                                   NSString * errorstring = [NSString stringWithFormat:@"Error: %@",error.localizedDescription];
//                                                   NSLog(@"Facebook Post Error: %@",errorstring);
//                                                   [self failedToCompleteRequestWithType:FacebookService];
//                                               }
//                                               else
//                                               {
//                                                   [self completedRequestWithType:FacebookService];
//                                               }
//                                           }];
////        }
////    }];


    //fb graph object post
    // Create an object
    if (!FBSession.activeSession.isOpen) {
        [FBSession openActiveSessionWithAllowLoginUI: NO];
    }


    // Create an object
    NSMutableDictionary<FBOpenGraphObject> *picture = [FBGraphObject openGraphObjectForPost];

    // specify that this Open Graph object will be posted to Facebook
    picture.provisionedForPost = YES;

    // Add the standard object properties, including the image you just staged
    picture[@"og"] = @{ @"title":@"Flux", @"type":@"picture.picture", @"description":@"my description"};




    [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error) {
            NSLog(@"Successfuly staged image with staged URI: %@", [result objectForKey:@"uri"]);
            //Package image inside a dictionary, inside an array like we'll need it for the object
            NSArray *image = @[@{@"url": [result objectForKey:@"uri"], @"user_generated" : @"true" }];

            NSMutableDictionary<FBOpenGraphObject> *pictureObject = [FBGraphObject openGraphObjectForPost];

            // specify that this Open Graph object will be posted to Facebook
            pictureObject.provisionedForPost = YES;

            // Add the standard object properties
            pictureObject[@"og"] = @{ @"title":@"", @"type":@"fluxapp:picture", @"description":@"this is a new capture description", @"image":image };



            NSMutableDictionary<FBGraphObject> *action = [FBGraphObject graphObject];
            action[@"picture"] = pictureObject;
            [action setObject:@"true" forKey:@"fb:explicitly_shared"];

            [FBRequestConnection startForPostWithGraphPath:@"me/fluxapp:take"
                                               graphObject:action
                                         completionHandler:^(FBRequestConnection *connection,
                                                             id result,
                                                             NSError *error) {
                                             if (!error) {
                                                 // Success, the restaurant has been liked
                                                 NSLog(@"Posted OG action, id: %@", [result objectForKey:@"id"]);
                                                 [self completedRequestWithType:FacebookService];
                                                 
                                             } else {
                                                 // An error occurred, we need to handle the error
                                                 // See: https://developers.facebook.com/docs/ios/errors
                                                 NSLog(@"Error: %@, %@",error.description, error.debugDescription);
                                             }
                                         }];
        }
        else{
            NSLog(@"Error: %@, %@",error.description, error.debugDescription);
        }
        
    }];
}


@end
