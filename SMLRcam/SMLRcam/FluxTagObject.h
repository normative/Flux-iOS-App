//
//  FluxTagObject.h
//  Flux
//
//  Created by Kei Turner on 2013-09-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxTagObject : NSObject

@property (nonatomic, strong) NSString*tagText;
@property (nonatomic) int count;
@property (nonatomic) BOOL isChecked;

- (void)setIsActive:(BOOL)active;

@end
