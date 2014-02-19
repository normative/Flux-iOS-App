//
//  FluxTagObject.h
//  Flux
//
//  Created by Kei Turner on 2013-09-12.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxTagObject : NSObject

@property (nonatomic, strong) NSString*tagText;
@property (nonatomic) int count;
@property (nonatomic) BOOL isChecked;
@property (nonatomic) BOOL isNotApplicable;

- (void)setIsActive:(BOOL)active;

- (id)initWithTitle:(NSString*)tagText andApplicable:(BOOL)applicable;

@end
