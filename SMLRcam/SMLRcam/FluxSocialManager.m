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
    if (username) {
        [UICKeyChainStore removeAllItemsForService:TwitterService];
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
                                             else{
                                                 if ([delegate respondsToSelector:@selector(SocialManager:didFailToLinkSocialAccount:)]) {
                                                     [delegate SocialManager:self didFailToLinkSocialAccount:TwitterService];
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
                if (!isRegister) {
                    [UICKeyChainStore setString:[parts objectAtIndex:0] forKey:FluxTokenKey service:TwitterService];
                    [UICKeyChainStore setString:[parts objectAtIndex:3] forKey:FluxUsernameKey service:TwitterService];
                }
                
                //call delegate
                if (isRegister) {
                    if ([delegate respondsToSelector:@selector(SocialManager:didRegisterTwitterAccountWithUserInfo:)]) {
                        NSDictionary*userInfo = [[NSDictionary alloc]initWithObjectsAndKeys:[parts objectAtIndex:0], @"token", [parts objectAtIndex:3], @"username",[parts objectAtIndex:1], @"secret", [self.TWAccounts objectAtIndex:index] , @"account", nil];
                        [delegate SocialManager:self didRegisterTwitterAccountWithUserInfo:userInfo];
                    }
                }
                else{
                    if ([delegate respondsToSelector:@selector(SocialManager:didLinkTwitterAccountWithUsername:)]) {
                        [delegate SocialManager:self didLinkTwitterAccountWithUsername:(NSString*)[parts objectAtIndex:3]];
                    }
                }
            }
            else{
                if (parts.count) {
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


- (void)linkFacebook{
    if (!FBSession.activeSession.isOpen) {
        if (FBSession.activeSession.state != FBSessionStateCreated) {
            // Create a new, logged out session.
            FBSession.activeSession = [[FBSession alloc] init];
        }
        
        // if the session isn't open, let's open it now and present the login UX to the user
        NSArray *permissions = [NSArray arrayWithObjects:@"email", nil];
        [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:YES completionHandler:
         ^(FBSession *session,
           FBSessionState state, NSError *error) {
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
                                     if ([delegate respondsToSelector:@selector(SocialManager:didRegisterFacebookAccountWithUserInfo:)]) {
                                         [delegate SocialManager:self didRegisterFacebookAccountWithUserInfo:dict];
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
    
    if (outstandingPosts.count == 0) {
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
                [self failedToCompleteRequestWithType:TwitterService];
            }
        }
        else {
            NSLog(@"[ERROR] An error occurred while posting: %@", [error localizedDescription]);
            [self failedToCompleteRequestWithType:TwitterService];
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
            [self failedToCompleteRequestWithType:TwitterService];
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



//this won't work until we have an app backend from the looks of it
- (void)postToFacebookWithStatus:(NSString*)status andImage:(UIImage*)image{
    
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
    
    
    
    NSArray *permissionsNeeded = @[@"publish_actions"];
    
    // Request the permissions the user currently has
    [FBRequestConnection startWithGraphPath:@"/me/permissions" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error){
          NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
          NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
          
          // Check if all the permissions we need are present in the user's current permissions
          // If they are not present add them to the permissions to be requested
          for (NSString *permission in permissionsNeeded){
              if (![currentPermissions objectForKey:permission]){
                  [requestPermissions addObject:permission];
              }
          }
          
          // If we have permissions to request
          if ([requestPermissions count] > 0){
              // Ask for the missing permissions
              [FBSession.activeSession requestNewPublishPermissions:requestPermissions
                                                    defaultAudience:FBSessionDefaultAudienceFriends
                                                  completionHandler:^(FBSession *session, NSError *error) {
                                                      if (!error) {
                                                          // Permission granted, we can request the user information
                                                          [self postToFacebookWithPermissionsWithStatus:status andImage:image];
                                                      } else {
                                                          // An error occurred, handle the error
                                                          // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
                                                          NSLog(@"%@", error.description);
                                                      }
                                                  }];
          } else {
              [self postToFacebookWithPermissionsWithStatus:status andImage:image];
          }
          
        } else {
          // There was an error requesting the permission information
          // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
          NSLog(@"%@", error.description);
        }
        }];
    
    
    
    
    
//    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
//    [params setObject:status forKey:@"message"];
//    [params setObject:UIImagePNGRepresentation(image) forKey:@"picture"];
//    
//    [FBRequestConnection startWithGraphPath:@"me/photos"
//                                 parameters:params
//                                 HTTPMethod:@"POST"
//                          completionHandler:^(FBRequestConnection *connection,
//                                              id result,
//                                              NSError *error)
//     {
//         if (error)
//         {
//             NSString * errorstring = [NSString stringWithFormat:@"Error: %@",error.localizedDescription];
//             NSLog(@"Facebook Post Error: %@",errorstring);
//             [self failedToCompleteRequestWithType:FacebookService];
//         }
//         else
//         {
//             [self completedRequestWithType:FacebookService];
//         }
//     }];
}

- (void)postToFacebookWithPermissionsWithStatus:(NSString*)status andImage:(UIImage*)image{
    // Permissions are present, we can request the user information
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Flux", @"name",
                                   @"See a place like you’ve never seen it before.", @"caption",
                                   @"Flux gives you and your friends the ability to automatically place photos in the real world, the rest is up to you.",@"description",
                                   @"http://www.smlr.is/", @"link",
                                   @"http://imgur.com/ADMTzLB", @"picture",
                                   nil];
    
    // Make the request
    [FBRequestConnection startWithGraphPath:@"/me/feed"
                                 parameters:params
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // Link posted successfully to Facebook
            [self completedRequestWithType:FacebookService];
        } else {
            // An error occurred, we need to handle the error
            NSString * errorstring = [NSString stringWithFormat:@"Error: %@",error.localizedDescription];
            NSLog(@"Facebook Post Error: %@",errorstring);
            [self failedToCompleteRequestWithType:FacebookService];
        }
    }];
}

@end
