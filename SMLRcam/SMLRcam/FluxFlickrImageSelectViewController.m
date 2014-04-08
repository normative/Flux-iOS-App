//
//  FluxFlickrImageSelectViewController.m
//  Flux
//
//  Created by Ryan Martens on 3/24/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxFlickrImageSelectViewController.h"

#import "FluxFlickrEditDescriptionViewController.h"
#import "FluxFlickrPhotoDataElement.h"
#import "FluxFlickrPhotosetDataElement.h"
#import <objectiveflickr/ObjectiveFlickr.h>
#import "OFAPIKey.h"
#import "PECropViewController.h"

const NSTimeInterval descriptionDownloadTimeoutInterval = 5.0;

NSString* const FluxFlickrImageSelectCroppedImageKey = @"FluxFlickrImageSelectCroppedImageKey";
NSString* const FluxFlickrImageSelectDescriptionKey = @"FluxFlickrImageSelectDescriptionKey";

@interface FluxFlickrImageSelectViewController () <FluxFlickrEditDescriptionProtocol, OFFlickrAPIRequestDelegate, NSURLSessionDownloadDelegate, PECropViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) OFFlickrAPIContext *flickrContext;
@property (nonatomic) OFFlickrAPIRequest *flickrRequest;

// Collections for storing photos and photosets displayed in UITableView
@property (nonatomic, strong) NSMutableArray *photoList;
@property (nonatomic, strong) NSMutableArray *photosetList;

// Configuration for NSURLSession
@property (nonatomic) NSURLSession *urlSession;

// Lock and condition for photo description
@property (nonatomic, strong) NSCondition *timeoutLock;
@property (nonatomic) bool didRetrieveDescription;
@property (nonatomic, strong) NSString *photoDescription;

// Flag to indicate whether we have selected a photoset yet in the workflow
@property (nonatomic) bool didSelectPhotoset;
@property (nonatomic, strong) NSString *selectedPhotosetName;

@property (nonatomic, strong) UIImage *croppedImage;

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
    
    self.timeoutLock = [[NSCondition alloc] init];
    self.didRetrieveDescription = NO;
    self.photoDescription = @"No description available";
    
    self.tableView.rowHeight = 95;
    
    self.photoList = [[NSMutableArray alloc] init];
    self.photosetList = [[NSMutableArray alloc] init];
    
    self.flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:OFSampleAppAPIKey sharedSecret:OFSampleAppAPISharedSecret];
    self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    self.didSelectPhotoset = NO;
    
    [self loadFlickrPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancelFlickerImageSelect
{
    if ([self.delegate respondsToSelector:@selector(FluxFlickrImageSelectViewControllerDidCancel:)])
    {
        [self.delegate FluxFlickrImageSelectViewControllerDidCancel:self];
    }
}

- (IBAction)cancelButtonAction:(id)sender
{
    [self cancelFlickerImageSelect];
}

- (IBAction)selectButtonAction:(id)sender
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

    if (selectedIndexPath)
    {
        if (!self.didSelectPhotoset)
        {
            // Photoset selected
            
            FluxFlickrPhotosetDataElement *photosetElement = [self.photosetList objectAtIndex:selectedIndexPath.row];
            
            self.selectedPhotosetName = photosetElement.title;

            [self.flickrRequest callAPIMethodWithGET:@"flickr.photosets.getPhotos" arguments:@{@"photoset_id": photosetElement.photoset_id, @"per_page": @"100"}];
            
            self.didSelectPhotoset = YES;
            [self.tableView reloadData];
        }
        else
        {
            // Photo selected

            FluxFlickrPhotoDataElement *photoElement = [self.photoList objectAtIndex:selectedIndexPath.row];
            
            // Create a download task to manage image download
            
            NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithURL:photoElement.largeImageURL];
            photoElement.downloadTask = downloadTask;
            [downloadTask resume];

            // Get the description of the image for use as an annotation
            self.didRetrieveDescription = NO;
            [self.flickrRequest callAPIMethodWithGET:@"flickr.photos.getInfo" arguments:@{@"photo_id": photoElement.photo_id}];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pushFlickrEditDescriptionView"])
    {
        FluxFlickrEditDescriptionViewController *flickrEditVC = (FluxFlickrEditDescriptionViewController *)segue.destinationViewController;

        NSString *annotation = [NSString stringWithFormat:@"#yale '%@' %@", self.selectedPhotosetName, self.photoDescription];

        flickrEditVC.delegate = self;
        flickrEditVC.annotationText = annotation;
    }
}

- (void)launchAnnotationView
{
    [self performSegueWithIdentifier:@"pushFlickrEditDescriptionView" sender:self];
}

# pragma mark - Table View Controller delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.didSelectPhotoset)
    {
        return self.photosetList.count;
    }
    else
    {
        return self.photoList.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FlickrCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    if (!self.didSelectPhotoset)
    {
        FluxFlickrPhotosetDataElement *photosetElement = [self.photosetList objectAtIndex:indexPath.row];
        
        cell.textLabel.font = [UIFont systemFontOfSize:14.0];
        cell.textLabel.text = photosetElement.title;
    }
    else
    {
        FluxFlickrPhotoDataElement *photoElement = [self.photoList objectAtIndex:indexPath.row];

        // Clear out image so we don't see imagery from another row when a cell is re-used
        cell.imageView.image = nil;
        
        if (!photoElement.thumbImage)
        {
            // Download and display thumbnail image
            NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithURL:photoElement.thumbImageURL
                                                            completionHandler:^(NSData *data, NSURLResponse *response,
                                                                                NSError *error) {
                                                                if (!error)
                                                                {
                                                                    UIImage *image = [[UIImage alloc] initWithData:data];
                                                                    photoElement.thumbImage = image;
                                                                    
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        // Only update the cell if it is still in view
                                                                        UITableViewCell *updateCellRequired = [tableView cellForRowAtIndexPath:indexPath];
                                                                        if (updateCellRequired)
                                                                        {
                                                                            [self populateFlickrImageCell:cell withPhotoElement:photoElement];
                                                                            
                                                                            // Force the cell to be re-drawn
                                                                            [cell setNeedsLayout];
                                                                        }
                                                                    });
                                                                }
                                                            }];
            [dataTask resume];
        }
        
        [self populateFlickrImageCell:cell withPhotoElement:photoElement];
    }
    
    return cell;
}

- (void)populateFlickrImageCell:(UITableViewCell *)cell withPhotoElement:(FluxFlickrPhotoDataElement *)photoElement
{
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:10.0];
    cell.textLabel.text = photoElement.title;
    cell.imageView.image = photoElement.thumbImage;

    if (photoElement.title.length > 50)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
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
            // Extract title and id for each photoset
            
            FluxFlickrPhotosetDataElement *photosetElement = [[FluxFlickrPhotosetDataElement alloc] init];
            
            photosetElement.photoset_id = [photosetDict valueForKeyPath:@"id"];

            NSString *title = [photosetDict valueForKeyPath:@"title._text"];
            photosetElement.title = (title.length > 0 ? title : @"Untitled");
            
            [self.photosetList addObject:photosetElement];
            
            [self.tableView reloadData];
        }
    }
    else if ([response valueForKeyPath:@"photoset.photo"])
    {
        NSDictionary *photos = [response valueForKeyPath:@"photoset.photo"];
        
        for (NSDictionary *photoDict in photos)
        {
            // Extract title and URL of photo
            
            FluxFlickrPhotoDataElement *photoElement = [[FluxFlickrPhotoDataElement alloc] init];
            
            NSString *title = [photoDict objectForKey:@"title"];
            photoElement.title = (title.length > 0 ? title : @"Untitled");

            photoElement.photo_id = [photoDict objectForKey:@"id"];
            photoElement.thumbImageURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrThumbnailSize];
            photoElement.largeImageURL = [self.flickrContext photoSourceURLFromDictionary:photoDict size:OFFlickrLargeSize];
            
            [self.photoList addObject:photoElement];
        }
        
        [self.tableView reloadData];
    }
    else if ([response valueForKeyPath:@"photo"])
    {
        NSDictionary *photoDict = [response valueForKeyPath:@"photo"];
        
        // Extract description of photo
        NSString *descriptionText = [photoDict valueForKeyPath:@"description._text"];
        if (descriptionText)
        {
            self.photoDescription = descriptionText;
        }
        
        // Send signal that description is available
        [self.timeoutLock lock];
        self.didRetrieveDescription = YES;
        [self.timeoutLock signal];
        [self.timeoutLock unlock];
    }
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error
{
    self.flickrRequest = nil;
}

#pragma mark - PECropViewControllerDelegate methods

- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{
    // Dismiss the crop selector overlay
    [controller dismissViewControllerAnimated:YES completion:^{
        // Make sure that we have the description, otherwise timeout and use default
        [self.timeoutLock lock];
        while (!self.didRetrieveDescription)
        {
            [self.timeoutLock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:descriptionDownloadTimeoutInterval]];
        }
        [self.timeoutLock unlock];

        self.croppedImage = croppedImage;
        
        [self launchAnnotationView];
    }];
}

- (void)cropViewControllerDidCancel:(PECropViewController *)controller
{
    // Dismiss the crop selector overlay
    [controller dismissViewControllerAnimated:YES completion:^{
        [self cancelFlickerImageSelect];
    }];
}

#pragma mark - NSURLSessionTaskDelegate methods

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
}

# pragma mark - FluxFlickrEditDescriptionProtocol methods

- (void)FluxFlickrEditDescriptionViewController:(FluxFlickrEditDescriptionViewController *)picker didFinishEditingDescriptionWithInfo:(NSDictionary *)info
{
    // Description edit complete
    NSString *annotation = info[FluxFlickrEditDescriptionAnnotationKey];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        // We now have the cropped image and edited description. These can be passed up the chain for use as an overlay.
        if ([self.delegate respondsToSelector:@selector(FluxFlickrImageSelectViewController:didFinishPickingMediaWithInfo:)])
        {
            NSDictionary *imageDict = @{FluxFlickrImageSelectCroppedImageKey : self.croppedImage, FluxFlickrImageSelectDescriptionKey : annotation};
            [self.delegate FluxFlickrImageSelectViewController:self didFinishPickingMediaWithInfo:imageDict];
        }
    }];
}

- (void)FluxFlickrEditDescriptionViewControllerDidCancel:(FluxFlickrEditDescriptionViewController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self cancelFlickerImageSelect];
    }];
}

@end
