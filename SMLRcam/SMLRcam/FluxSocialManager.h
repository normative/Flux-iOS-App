//
//  FluxSocialManager.h
//  Flux
//
//  Created by Kei Turner on 11/14/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "OAuth+Additions.h"
#import "TWAPIManager.h"
#import "TWSignedRequest.h"
#import <FacebookSDK/FacebookSDK.h>


@class FluxSocialManager;
@protocol FluxSocialManagerDelegate <NSObject>
@optional
- (void)SocialManager:(FluxSocialManager*)socialManager didLinkFacebookAccountWithName: (NSString*)name;
- (void)SocialManager:(FluxSocialManager*)socialManager didLinkTwitterAccountWithUsername: (NSString*)username;
- (void)SocialManager:(FluxSocialManager*)socialManager didLinkTwitterAccount: (ACAccount*)theAccount;
- (void)SocialManager:(FluxSocialManager*)socialManager didFailToLinkSocialAccount:(NSString*)accountType withMessage:(NSString*)message;

- (void)SocialManagerDidAddFacebookPublishPermissions:(FluxSocialManager*)socialManager;
- (void)SocialManagerDidFailToAddAddFacebookPublishPermissions:(FluxSocialManager*)socialManager andDidShowError:(BOOL)errorShownAlready;


- (void)SocialManager:(FluxSocialManager*)socialManager didRegisterFacebookAccountWithUserInfo: (NSDictionary*)userInfo;
- (void)SocialManager:(FluxSocialManager*)socialManager didRegisterTwitterAccountWithUserInfo: (NSDictionary*)userInfo;
- (void)SocialManager:(FluxSocialManager*)socialManager didFailToRegisterSocialAccount:(NSString*)accountType andMessage:(NSString*)message;

- (void)SocialManager:(FluxSocialManager*)socialManager didMakeSocialPosts:(NSArray*)socialPartners;
- (void)SocialManager:(FluxSocialManager*)socialManager didFailToMakeSocialPostWithType:(NSString*)socialType andDidShowError:(BOOL)errorShownAlready;
@end


@interface FluxSocialManager : NSObject <UIAlertViewDelegate>{
    NSMutableArray* outstandingPosts;
    NSMutableArray*posts;
    id __unsafe_unretained delegate;
    
    BOOL isRegister;
}

@property (unsafe_unretained) id <FluxSocialManagerDelegate> delegate;

@property (atomic, strong) UIWindow *window;

@property (nonatomic, strong) ACAccountStore *TWAccountStore;
@property (nonatomic, strong) TWAPIManager *TWApiManager;
@property (nonatomic, strong) NSArray *TWAccounts;

// Callback for single image retrieved (either from cache or download)


- (void)linkFacebook;
- (void)linkTwitter;

- (void)linkFacebookWithPublishPermissions;

- (void)registerWithFacebook;
- (void)registerWithTwitter;

- (void)socialPostTo:(NSArray*)socialPartners withStatus:(NSString*)status andImage:(UIImage*)image andSnapshot:(BOOL)snapshot;
- (void)socialPostTo:(NSArray*)socialPartners withStatus:(NSString*)status directedToUser:(NSString *)userid;


@end
