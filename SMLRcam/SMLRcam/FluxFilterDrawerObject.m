//
//  FluxFilterDrawerObject.m
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxFilterDrawerObject.h"

@implementation FluxFilterDrawerObject

@synthesize title, titleImage, isChecked;

- (id)initWithTitle:(NSString *)atitle andtitleImage:(UIImage *)atitleImage andActive:(BOOL)bActive{
    self = [super init];
    if (self) {
        self.title = atitle;
        self.titleImage = atitleImage;
        self.isChecked = bActive;
    }
    
    return self;

}

- (void)setIsActive:(BOOL)active{
    self.isChecked = active;
}

@end
