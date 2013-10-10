//
//  DWTagList.h
//
//  Created by Dominic Wroblewski on 07/07/2012.
//  Copyright (c) 2012 Terracoding LTD. All rights reserved.
//

#import <UIKit/UIKit.h>


@class DWTagList;
@protocol DWTagListDelegate <NSObject>
@optional

- (void)tagList:(DWTagList*)list selectedTagWithTitle:(NSString*)title andActive:(BOOL)active;

@end

enum tagState {
    tagInactive = 0,
    tagActive = 1
};

typedef enum tagState tagState;

@interface DWTagList : UIScrollView
{
    UIView *view;
    NSArray *textArray;
    NSArray *selectedArray;
    CGSize sizeFit;
    UIColor *lblBackgroundColor;
}

@property (nonatomic) BOOL viewOnly;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) NSArray *textArray;
@property (nonatomic, weak) id<DWTagListDelegate> tagDelegate;
@property (nonatomic, strong) UIColor *highlightedBackgroundColor;
@property (nonatomic) BOOL automaticResize;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, assign) CGFloat labelMargin;
@property (nonatomic, assign) CGFloat bottomMargin;
@property (nonatomic, assign) CGFloat horizontalPadding;
@property (nonatomic, assign) CGFloat verticalPadding;
@property (nonatomic, assign) CGFloat minimumWidth;

//array parameter is an array of FluxTagObjects
- (void)setTags:(NSArray *)array andSelectedArray:(NSArray*)selectedArr;

- (void)display;
- (CGSize)fittedSize;

@end

@interface DWTagView : UIView

@property (nonatomic, strong) UIView        *backgroundView;
@property (nonatomic, strong) UIButton      *button;
@property (nonatomic, strong) UILabel       *label;
@property (nonatomic) BOOL isSelected;

- (void)updateWithString:(NSString*)text font:(UIFont*)font constrainedToWidth:(CGFloat)maxWidth padding:(CGSize)padding minimumWidth:(CGFloat)minimumWidth;
- (void)setLabelText:(NSString*)text;

@end
