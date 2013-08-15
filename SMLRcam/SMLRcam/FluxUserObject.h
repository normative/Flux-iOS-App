//
//  FluxUserObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxUserObject : NSObject

@property (nonatomic, weak) NSString*dateCreated;
@property (nonatomic, weak) NSString*firstName;
@property (nonatomic, weak) NSString*lastName;
@property (nonatomic, weak) NSString*userName;
@property (nonatomic) int userID;
@property (nonatomic) BOOL privacy;

@end
