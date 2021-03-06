//
//  FluxTimeFilterScrollView.h
//  Flux
//
//  Created by Kei Turner on 2013-10-21.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxTimeFilterScrollView;
@protocol TimeFilterScrollViewTapDelegate <NSObject>
@optional
- (void)timeFilterScrollView:(FluxTimeFilterScrollView *)scrollView didTapAtPoint:(CGPoint)point;
- (void)timeFilterScrollView:(FluxTimeFilterScrollView *)scrollView shouldBeginTouchAtPoint:(CGPoint)point;
- (void)timeFilterScrollView:(FluxTimeFilterScrollView *)scrollView shouldEndTouchAtPoint:(CGPoint)point;
@end

@interface FluxTimeFilterScrollView : UIScrollView{
    UIView*subview;
    __weak id <TimeFilterScrollViewTapDelegate> tapDelegate;
    UITapGestureRecognizer*tapRecognizer;
}
@property (nonatomic, weak) id <TimeFilterScrollViewTapDelegate> tapDelegate;

@end
