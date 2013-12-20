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
- (void)PlaceholderTextViewDidBeginEditing:(KTPlaceholderTextView*)placeholderTextView;
- (void)PlaceholderTextViewDidGoBeyondMax:(KTPlaceholderTextView*)placeholderTextView;
- (void)PlaceholderTextViewDidReturnWithinMax:(KTPlaceholderTextView*)placeholderTextView;
@end

@interface KTPlaceholderTextView : UITextView <UITextViewDelegate, NSLayoutManagerDelegate> {
    
    NSString*placeholderString;
    UILabel *placeholderLabel;
    UILabel*charCount;
    int maxCount;
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <KTPlaceholderTextViewDelegate> theDelegate;

- (void)setPlaceholderColor:(UIColor*)color;
- (void)setPlaceholderText:(NSString*)thePlaceholder;
- (void)resetView;
- (void)setCharCountVisible:(BOOL)visible;
- (void)setMaxCharCount:(int)count;


@end
