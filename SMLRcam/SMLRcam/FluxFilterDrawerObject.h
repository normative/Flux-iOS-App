//
//  FluxFilterDrawerObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxFilterDrawerObject : NSObject{
   
}

@property (nonatomic, weak) NSString *title;
@property (nonatomic, weak) UIImage *titleImage;
@property (nonatomic)BOOL isChecked;




- (id)initWithTitle:(NSString*)atitle andtitleImage:(UIImage*)atitleImage andActive:(BOOL)bActive;

- (void)setIsActive:(BOOL)active;

@end
