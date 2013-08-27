//
//  KTPlaceholderTextView.h
//  Flux
//
//  Created by Kei Turner on 2013-07-31.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>


@class KTPlaceholderTextView;
@protocol KTPlaceholderTextViewDelegate <NSObject>
@optional
- (void)PlaceholderTextViewReturnButtonWasPressed:(KTPlaceholderTextView *)placeholderTextView;
@end

@interface KTPlaceholderTextView : UITextView {
    
    NSString*placeholderString;
    UILabel *placeholderLabel;
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <KTPlaceholderTextViewDelegate> delegate;

- (void)setPlaceholderColor:(UIColor*)color;
- (void)SetPlaceholderText:(NSString*)thePlaceholder;

@end
