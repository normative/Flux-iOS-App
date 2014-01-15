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

extern NSString* const FacebookPost;
extern NSString* const TwitterPost;

@class FluxSocialManager;
@protocol FluxSocialManagerDelegate <NSObject>
@optional
- (void)SocialManager:(FluxSocialManager*)socialManager didLinkFacebookAccountWithName: (NSString*)name;
- (void)SocialManager:(FluxSocialManager*)socialManager didLinkTwitterAccountWithUsername: (NSString*)username;
- (void)SocialManager:(FluxSocialManager*)socialManager didFailToLinkSocialAccount:(NSString*)accountType;

- (void)SocialManager:(FluxSocialManager*)socialManager didMakeSocialPosts:(NSArray*)socialPartners;
- (void)SocialManager:(FluxSocialManager*)socialManager didFailToMakeSocialPostWithType:(NSString*)socialType;
@end


typedef void (^socialLoginBlock)(NSString *);
typedef void (^socialLoginErrorBlock)(NSError *,NSString*);


@interface FluxSocialManager : NSObject <UIAlertViewDelegate>{
    NSMutableArray* outstandingPosts;
    NSMutableArray*posts;
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <FluxSocialManagerDelegate> delegate;

@property (atomic, strong) UIWindow *window;

@property (nonatomic, strong) ACAccountStore *TWAccountStore;
@property (nonatomic, strong) TWAPIManager *TWApiManager;
@property (nonatomic, strong) NSArray *TWAccounts;

// Callback for single image retrieved (either from cache or download)
@property (strong) socialLoginBlock socialLoginDidComplete;
@property (strong) socialLoginErrorBlock socialLoginDidFail;
- (void) whenSocialLoginReady:(NSString *)username;

- (void)linkFacebook;
- (void)linkTwitter;

- (void)socialPostTo:(NSArray*)socialPartners withStatus:(NSString*)status andImage:(UIImage*)image;


@end
