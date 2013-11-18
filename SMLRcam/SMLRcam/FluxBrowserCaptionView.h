//
//  FluxBrowserCaptionView.h
//  Flux
//
//  Created by Kei Turner on 11/18/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "IDMCaptionView.h"
#import "FluxBrowserPhoto.h"

@interface FluxBrowserCaptionView : IDMCaptionView{
    UILabel *captionLabel;
    UILabel *timestampLabel;
    UILabel *usernameLabel;
    UIImageView *usernameImageView;
    UIImageView *clockImageView;
    
    id<IDMPhoto> _photo;
}

@end
