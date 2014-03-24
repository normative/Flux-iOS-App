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

@interface FluxFlickrImageSelectViewController () <OFFlickrAPIRequestDelegate, NSURLSessionDownloadDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) OFFlickrAPIContext *flickrContext;
@property (nonatomic) OFFlickrAPIRequest *flickrRequest;

@property (nonatomic, strong) NSMutableArray *photoDownloadTasks;
@property (nonatomic, strong) NSMutableArray *photoNames;
@property (nonatomic, strong) NSMutableArray *photoURLs;

@property (nonatomic, weak) NSCache *photoCache;

@property (nonatomic) NSString *nextPhotoTitle;
@property (nonatomic) NSURLSession *urlSession;
@property (nonatomic) NSURLSessionDownloadTask *imageDownloadTask;
@property (weak, nonatomic) NSTimer *fetchTimer;

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
    self.photoURLs = [[NSMutableArray alloc] init];
    
    self.flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:OFSampleAppAPIKey sharedSecret:OFSampleAppAPISharedSecret];
    self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - Table View Controller delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.photoNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell Identifier"];
    cell.textLabel.text = [self.photoNames objectAtIndex:indexPath.row];
    
    // Currently downloading images directly just to show something (even though already downloaded separately)
    NSData *imageData = [NSData dataWithContentsOfURL:[self.photoURLs objectAtIndex:indexPath.row]];
    cell.imageView.image = [UIImage imageWithData:imageData];
    
    return cell;
}

# pragma mark - Flickr management

- (void)loadFlickrPhotos
{
    self.flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
    self.flickrRequest.delegate = self;
    [self.flickrRequest callAPIMethodWithGET:@"flickr.photos.getRecent" arguments:@{@"per_page": @"5"}];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
    NSLog(@"%@", response);
    
    NSDictionary *photos = [response valueForKeyPath:@"photos.photo"];
    
    for (NSDictionary *photoDict in photos)
    {
        // Extract title and URL of photo
        
        NSString *title = [photoDict objectForKey:@"title"];
        [self.photoNames addObject:(title.length > 0 ? title : @"Untitled")];
        
        NSURL *photoURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrLargeSize];
        [self.photoURLs addObject:photoURL];

        // Create a download task to manage image download
        
        NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithURL:photoURL];
        [self.photoDownloadTasks addObject:downloadTask];
        [downloadTask resume];
    }
    
    self.flickrRequest = nil;

    [self.tableView reloadData];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error
{
    self.flickrRequest = nil;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    // If image is large, consider creating the image off the main queue
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
    NSLog(@"Finished downloading image from location %@", location);
    
    NSError *error;
    BOOL result = [[NSFileManager defaultManager] removeItemAtURL:location error:&error];
    if (!result) {
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
