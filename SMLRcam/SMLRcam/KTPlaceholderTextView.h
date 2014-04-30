//
//  KTPlaceholderTextView.h
//  Flux
//
//  Created by Kei Turner on 2013-07-31.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>


@class KTPlaceholderTextView;
@protocol KTPlaceholderTextViewDelegate <NSObject>
@optional
- (void)PlaceholderTextViewReturnButtonWasPressed:(KTPlaceholderTextView *)placeholderTextView;
- (void)PlaceholderTextViewDidEdit:(KTPlaceholderTextView *)placeholderTextView;
- (void)PlaceholderTextViewDidBeginEditing:(KTPlaceholderTextView*)placeholderTextView;
- (void)PlaceholderTextViewDidGoBeyondMax:(KTPlaceholderTextView*)placeholderTextView;
- (void)PlaceholderTextViewDidReturnWithinMax:(KTPlaceholderTextView*)placeholderTextView;
@end

@interface KTPlaceholderTextView : UITextView <UITextViewDelegate, NSLayoutManagerDelegate> {
    
    NSString*placeholderString;
    UILabel *placeholderLabel;
    UILabel*charCount;
    int maxCount;
    int warnCount;
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <KTPlaceholderTextViewDelegate> theDelegate;
@property (nonatomic) bool countCharactersToZero;

- (void)setPlaceholderColor:(UIColor*)color;
- (void)setPlaceholderText:(NSString*)thePlaceholder;
- (void)resetView;
- (void)setShowsCharCount:(BOOL)visible;
- (void)setMaxCharCount:(int)count;
- (void)setWarnCharCount:(int)count;

@end
