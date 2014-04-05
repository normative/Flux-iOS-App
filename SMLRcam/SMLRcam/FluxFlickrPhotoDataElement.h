//
//  FluxFlickrPhotoDataElement.h
//  Flux
//
//  Created by Ryan Martens on 4/4/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxFlickrPhotoDataElement : NSObject

@property (nonatomic, strong) NSString *photo_id;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSURL *largeImageURL;
@property (nonatomic, strong) NSURL *thumbImageURL;
@property (nonatomic, strong) UIImage *largeImage;
@property (nonatomic, strong) UIImage *thumbImage;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@end
