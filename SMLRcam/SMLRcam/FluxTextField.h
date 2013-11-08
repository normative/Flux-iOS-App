//
//  FluxTextField.h
//  Flux
//
//  Created by Kei Turner on 11/8/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

extern int const FluxTextFieldPositionTop;
extern int const FluxTextFieldPositionMiddle;
extern int const FluxTextFieldPositionBottom;

@interface FluxTextField : UITextField


- (id)initWithFrame:(CGRect)frame andPlaceholderText:(NSString*)placeholder;

@end
