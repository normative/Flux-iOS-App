//
//  FluxUserObject.m
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxUserObject.h"

@implementation FluxUserObject

- (id)initWithName:(NSString*)theName andUsername:(NSString *)theUsername andPassword:(NSString *)thePassword andEmail:(NSString *)theEmail andBio:(NSString *)theBio andProfilePic:(UIImage *)theProfilePic{
    self = [super init];
    if (self)
    {
        self.name = theName;
        self.username = theUsername;
        self.password = thePassword;
        self.bio = theBio;
        self.email = theEmail;
        self.profilePic = theProfilePic;
    }
    
    return self;
}

@end
