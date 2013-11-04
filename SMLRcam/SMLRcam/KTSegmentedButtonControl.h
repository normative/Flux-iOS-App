//
//  KTSegmentedButtonControl.h
//  Flux
//
//  Created by Kei Turner on 2013-09-09.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KTSegmentedButtonControl;
@protocol KTSegmentedControlDelegate <NSObject>
@optional
- (void)SegmentedControlValueDidChange:(KTSegmentedButtonControl *)segmentedControl;
@end

@interface KTSegmentedButtonControl : UIView{
    NSArray* selectionImages;
    NSArray* standardImages;
    
    NSMutableArray*buttons;
    __weak id <KTSegmentedControlDelegate> delegate;
}
@property (nonatomic, weak) id <KTSegmentedControlDelegate> delegate;
@property (nonatomic) int selectedIndex;


- (void)initWithImages:(NSArray*)selectionArr andStandardImages:(NSArray*)standardArr;
- (void)setSelectedSegmentIndex:(int)index;

@end


