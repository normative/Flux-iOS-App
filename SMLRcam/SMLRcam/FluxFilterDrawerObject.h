//
//  FluxFilterDrawerObject.h
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxDataFilter.h"

@interface FluxFilterDrawerObject : NSObject{
   
}

@property (nonatomic, weak) NSString *title;
@property (nonatomic, weak) UIImage *titleImage;
@property (nonatomic)BOOL isChecked;
@property (nonatomic)FluxFilterType filterType;




- (id)initWithTitle:(NSString*)atitle andFilterType:(FluxFilterType)type andtitleImage:(UIImage*)atitleImage andActive:(BOOL)bActive;
- (void)setIsActive:(BOOL)active;

@end
