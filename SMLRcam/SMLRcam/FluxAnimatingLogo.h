//
//  FluxAnimatingLogo.h
//  Flux
//
//  Created by Kei Turner on 2014-03-12.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxAnimatingLogo : UIView{
    UIImageView*imageView1;
    UIImageView*imageView2;
}
@property (nonatomic) BOOL isAnimating;
- (void)setFirstAnimationSet:(NSMutableArray*)animationSet1 andSecondAnimationSet:(NSMutableArray*)animationSet2;

-(void)startAnimating;
-(void)stopAnimating;

@end
