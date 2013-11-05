//
//  FluxUserObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxUserObject : NSObject

@property (nonatomic) int userID;
@property (nonatomic, weak) NSString*name;
@property (nonatomic, weak) NSString*username;
@property (nonatomic, weak) NSString*password;
@property (nonatomic, weak) NSString*email;
@property (nonatomic, weak) UIImage*profilePic;

- (id)initWithName:(NSString*)theName
   andUsername:(NSString*)theUsername
         andPassword:(NSString*)thePassword
       andEmail:(NSString*)theEmail
andProfilePic:(UIImage*)theProfilePic;

@end
