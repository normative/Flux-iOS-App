//
//  IDMCaptionView.h
//  IDMPhotoBrowser
//
//  Created by Michael Waterfall on 30/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IDMPhotoProtocol.h"
#import "FluxPhotoCaptionView.h"

@class IDMCaptionView;
@protocol IDMCaptionViewDelegate <NSObject>
@optional
- (void)CaptionView:(IDMCaptionView *)captionView didSelectUsername:(NSString*)username andProfileImage:(UIImage*)profPic;
- (void)CaptionViewShouldEditAnnotation:(IDMCaptionView *)captionView;
- (void)CaptionView:(IDMCaptionView *)captionView shouldReportImage:(IDMPhoto*)photo;

@end

@interface IDMCaptionView : UIView <FluxPhotoCaptionViewDelegate>{
    id __unsafe_unretained delegate;
}
@property (unsafe_unretained) id <IDMCaptionViewDelegate> delegate;
@property (nonatomic, strong)FluxPhotoCaptionView *captionView;

// Init
- (id)initWithPhoto:(id<IDMPhoto>)photo;

// To create your own custom caption view, subclass this view
// and override the following two methods (as well as any other
// UIView methods that you see fit):

// Override -setupCaption so setup your subviews and customise the appearance
// of your custom caption
// You can access the photo's data by accessing the _photo ivar
// If you need more data per photo then simply subclass IDMPhoto and return your
// subclass to the photo browsers -photoBrowser:photoAtIndex: delegate method
- (void)setupCaption;

- (void)setupProfilePicture;

// Override -sizeThatFits: and return a CGSize specifying the height of your
// custom caption view. With width property is ignored and the caption is displayed
// the full width of the screen
- (CGSize)sizeThatFits:(CGSize)size;
- (CGRect)captionFrame;
- (void)resizeCaption:(CGRect)newFrame;

@end
