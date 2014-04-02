//
//  FluxFlickrImageSelectViewController.m
//  Flux
//
//  Created by Ryan Martens on 3/24/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxFlickrImageSelectViewController.h"

#import <objectiveflickr/ObjectiveFlickr.h>
#import "OFAPIKey.h"
#import "PECropViewController.h"

@interface FluxFlickrImageSelectViewController () <OFFlickrAPIRequestDelegate, NSURLSessionDownloadDelegate, PECropViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) OFFlickrAPIContext *flickrContext;
@property (nonatomic) OFFlickrAPIRequest *flickrRequest;

@property (nonatomic, strong) NSMutableArray *photoDownloadTasks;
@property (nonatomic, strong) NSMutableArray *photoNames;
@property (nonatomic, strong) NSMutableArray *photoSetIDs;
@property (nonatomic, strong) NSMutableArray *photoSets;
@property (nonatomic, strong) NSMutableArray *photoThumbURLs;
@property (nonatomic, strong) NSMutableArray *photoLargeURLs;

@property (nonatomic, weak) NSCache *photoCache;

@property (nonatomic) NSString *nextPhotoTitle;
@property (nonatomic) NSURLSession *urlSession;
@property (nonatomic) NSURLSessionDownloadTask *imageDownloadTask;
@property (weak, nonatomic) NSTimer *fetchTimer;

@property (nonatomic) bool selectedPhotoset;

@end

@implementation FluxFlickrImageSelectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.rowHeight = 95;
    
    self.photoDownloadTasks = [[NSMutableArray alloc] init];
    self.photoNames = [[NSMutableArray alloc] init];
    self.photoSetIDs = [[NSMutableArray alloc] init];
    self.photoSets = [[NSMutableArray alloc] init];
    self.photoThumbURLs = [[NSMutableArray alloc] init];
    self.photoLargeURLs = [[NSMutableArray alloc] init];
    
    self.flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:OFSampleAppAPIKey sharedSecret:OFSampleAppAPISharedSecret];
    self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    self.selectedPhotoset = NO;
    
    [self loadFlickrPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)selectButtonAction:(id)sender
{
    if (!self.selectedPhotoset)
    {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        NSString *photoset_id = [self.photoSetIDs objectAtIndex:selectedIndexPath.row];
        
        [self.flickrRequest callAPIMethodWithGET:@"flickr.photosets.getPhotos" arguments:@{@"photoset_id": photoset_id, @"per_page": @"5"}];
        
        self.selectedPhotoset = YES;
        [self.tableView reloadData];
    }
    else
    {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        NSString *photo_name = [self.photoNames objectAtIndex:selectedIndexPath.row];
        NSString *photoURL = [self.photoLargeURLs objectAtIndex:selectedIndexPath.row];
        
        // Create a download task to manage image download
        
        NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithURL:photoURL];
        [self.photoDownloadTasks addObject:downloadTask];
        [downloadTask resume];

//        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

# pragma mark - Table View Controller delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.selectedPhotoset)
    {
        return self.photoNames.count;
    }
    else
    {
        return self.photoSets.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedPhotoset)
    {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell Identifier"];
        cell.textLabel.text = [self.photoNames objectAtIndex:indexPath.row];
        
        // Currently downloading images directly just to show something (even though already downloaded separately)
        NSData *imageData = [NSData dataWithContentsOfURL:[self.photoThumbURLs objectAtIndex:indexPath.row]];
        cell.imageView.image = [UIImage imageWithData:imageData];
        
        return cell;
    }
    else
    {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell Identifier"];
        cell.textLabel.text = [self.photoSets objectAtIndex:indexPath.row];
        
        return cell;
    }
}

# pragma mark - Flickr management

- (void)loadFlickrPhotos
{
    self.flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
    self.flickrRequest.delegate = self;
    [self.flickrRequest callAPIMethodWithGET:@"flickr.people.findByUsername" arguments:@{@"username": @"Yale University"}];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
    NSLog(@"%@", response);
    
    if ([response valueForKeyPath:@"user.nsid"])
    {
        NSString *nsid = [response valueForKeyPath:@"user.nsid"];
        
        [self.flickrRequest callAPIMethodWithGET:@"flickr.photosets.getList" arguments:@{@"user_id": nsid, @"per_page": @"100"}];
    }
    else if ([response valueForKeyPath:@"photosets.photoset"])
    {
        NSDictionary *photosets = [response valueForKeyPath:@"photosets.photoset"];
        
        for (NSDictionary *photosetDict in photosets)
        {
            // Extract title of each photoset
            
            NSString *photoset_id = [photosetDict valueForKeyPath:@"id"];
            NSString *title = [photosetDict valueForKeyPath:@"title._text"];
            [self.photoSets addObject:(title.length > 0 ? title : @"Untitled")];
            [self.photoSetIDs addObject:photoset_id];
            
            [self.tableView reloadData];
        }
    }
    else if ([response valueForKeyPath:@"photoset.photo"])
    {
        NSDictionary *photos = [response valueForKeyPath:@"photoset.photo"];
        
        for (NSDictionary *photoDict in photos)
        {
            // Extract title and URL of photo
            
            NSString *title = [photoDict objectForKey:@"title"];
            [self.photoNames addObject:(title.length > 0 ? title : @"Untitled")];
            
            NSURL *photoThumbURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrThumbnailSize];
            [self.photoThumbURLs addObject:photoThumbURL];

            NSURL *photoLargeURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrLargeSize];
            [self.photoLargeURLs addObject:photoLargeURL];

//            // Create a download task to manage thumbnail image download
//            
//            NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithURL:photoThumbURL];
//            [self.photoDownloadTasks addObject:downloadTask];
//            [downloadTask resume];
        }
        
        self.flickrRequest = nil;

        [self.tableView reloadData];
    }
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error
{
    self.flickrRequest = nil;
}

- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{
    // Dismiss the crop selector overlay
    [controller dismissViewControllerAnimated:YES completion:^{

        // We now have the cropped image. This can be passed up the chain for use as an overlay.
        // TODO - package and send cropped information

        // Dismiss the view controller of the FlickrImageSelect VC
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }];
}

- (void)cropViewControllerDidCancel:(PECropViewController *)controller
{
    // Dismiss the crop selector overlay
    [controller dismissViewControllerAnimated:YES completion:^{
        
        // Dismiss the view controller of the FlickrImageSelect VC
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }];
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    // If image is large, consider creating the image off the main queue
    
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
    NSLog(@"Finished downloading image from location %@", location);
    
    // Add PECropViewController for overlaying functionality for cropping image
    PECropViewController *controller = [[PECropViewController alloc] init];
    controller.delegate = self;
    controller.image = image;
    
    controller.keepingCropAspectRatio = YES;
    
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat length = MIN(width, height);
    controller.imageCropRect = CGRectMake((width - length) / 2,
                                          (height - length) / 2,
                                          length,
                                          length);
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    [self presentViewController:navigationController animated:YES completion:nil];

    // Delete the temporary image as it is no longer needed (we keep the UIImage in memory for now)
    NSError *error;
    BOOL result = [[NSFileManager defaultManager] removeItemAtURL:location error:&error];
    if (!result)
    {
        NSLog(@"Error removing temp file at: %@, error: %@", location, error);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"Getting image (%llu of %llu KB)", totalBytesWritten / 1024, totalBytesExpectedToWrite / 1024);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error)
    {
        
    }
    
    self.imageDownloadTask = nil;
}

@end
