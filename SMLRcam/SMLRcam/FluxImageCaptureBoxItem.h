//
//  FluxImageCaptureBoxItem.h
//  Flux
//
//  Created by Kei Turner on 2/3/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxImageCaptureBoxItem : NSObject

@property (nonatomic, strong)UIView*whiteBox;
@property (nonatomic, strong)UIView*fadedBox;
@property (nonatomic) BOOL isMarked;

@end
