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
@property (nonatomic)int count;
@property (nonatomic)FluxFilterType filterType;




- (id)initWithTitle:(NSString*)atitle andFilterType:(FluxFilterType)type;

@end
