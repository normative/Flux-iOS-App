//
//  SMLRcamImageAnnotationViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-29.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxImageAnnotationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AddressBook/ABPerson.h>

NSString* const FluxImageAnnotationDidAcquireNewPicture = @"FluxImageAnnotationDidAcquireNewPicture";
NSString* const FluxImageAnnotationDidAcquireNewPictureLocalIDKey = @"FluxImageAnnotationDidAcquireNewPictureLocalIDKey";

@interface FluxImageAnnotationViewController ()

@end

@implementation FluxImageAnnotationViewController

@synthesize fluxImageCache;
@synthesize fluxMetadata;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View Control Callback Methods
- (void)PlaceholderTextViewReturnButtonWasPressed:(KTPlaceholderTextView *)placeholderTextView{
    //[self ConfirmImage:nil];
}

- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
    [imageObject setCategoryID:(segmentedControl.selectedSegmentIndex + 1)];
}

#pragma mark - image manipulation

//blurs an image using coreImage. Blur is between 0-1
- (UIImage *)BlurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur {
    
    //CGImage blows away image metadata, keep orientation
    UIImageOrientation orientation = image.imageOrientation;
    CGFloat normalizedBlur = blur*50;
    if (normalizedBlur > 50) {
        normalizedBlur = 50;
    }
    if (normalizedBlur < 0) {
        return image;
    }
    
    //init stuff
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGAffineTransform transform = CGAffineTransformIdentity;
    CIImage *outputImage;
    
    //clamp the borders so the blur doesnt shrink the borders of the image
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:inputImage forKey:kCIInputImageKey];
    [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    outputImage = [clampFilter outputImage];
    
    //adds gaussian blur to the image
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputImageKey, inputImage, @"inputRadius", @(normalizedBlur), nil];
    outputImage = [blurFilter outputImage];
    
    //output the image
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[inputImage extent]];
    UIImage *blurredImage = [UIImage imageWithCGImage:cgimg scale:1.0 orientation:orientation];
    CGImageRelease(cgimg);

    return blurredImage;
}

//adds a black gradient to the background image, and uses the alpha parameter to adjust the alpha of the new gradient view
- (void)AddGradientImageToBackgroundWithAlpha:(CGFloat)alpha{
    UIImageView *darkenImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"verticalBlackGradient.png"]];
    [darkenImageView setFrame:backgroundImageView.frame];
    [darkenImageView setContentMode:UIViewContentModeScaleAspectFill];
    [darkenImageView setAlpha:alpha];
    [backgroundImageView addSubview:darkenImageView];
}
#pragma mark - Network Services
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUploadImage:(FluxScanImageObject *)updatedImageObject
{
    // Temporarily disable progress bar and transition.
//    progressView.progress = 1;
//    [self PopViewController:nil];
    
    NSLog(@"%s: Adding image object %@ to cache.", __func__, updatedImageObject.localID);

    if ([fluxMetadata objectForKey:updatedImageObject.localID] != nil)
    {
        // FluxScanImageObject exists in the local cache. Replace it with updated object.
        [fluxMetadata setObject:updatedImageObject forKey:updatedImageObject.localID];
        
        if ([fluxImageCache objectForKey:updatedImageObject.localID] != nil)
        {
            NSLog(@"Image with string ID %@ exists in cache.", updatedImageObject.localID);
        }
        else
        {
            NSLog(@"Image with string ID %@ does not exist in cache.", updatedImageObject.localID);
        }
    }
    else
    {
        NSLog(@"Image with string ID %@ does not exist in local cache!", updatedImageObject.localID);
    }
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailWithError:(NSError *)e{
    [acceptButton setEnabled:YES];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Image upload failed with error %d", (int)[e code]]
                                                        message:[e localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [progressView setHidden:YES];
    progressView.progress = 0;
    
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices uploadProgress:(float)bytesSent ofExpectedPacketSize:(float)size{
    if (progressView.frame.origin.y != 0) {

        
    }
    //subtract 10 for the end wait
    progressView.progress = bytesSent/size -0.05;
}

# pragma mark - orientation and rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - view loading / popping

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [backgroundImageView setImage:[self BlurryImage:capturedImage withBlurLevel:0.2]];
    [self AddGradientImageToBackgroundWithAlpha:0.7];
    
    [self LoadUI];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    UIImageView*tempBackgroundImageView = [[UIImageView alloc]initWithFrame:backgroundImageView.frame];
    [tempBackgroundImageView setContentMode:backgroundImageView.contentMode];
    [tempBackgroundImageView setImage:capturedImage];
    [self.view insertSubview:tempBackgroundImageView belowSubview:backgroundImageView];
    
    [backgroundImageView setAlpha:0.0];
    [backgroundImageView setHidden:NO];
    
    [UIView beginAnimations:@"fadein_darkened_image" context:nil];
    [UIView setAnimationDuration:0.4];
    
    [tempBackgroundImageView setAlpha:0.0];
    [backgroundImageView setAlpha:1.0];
    
    [UIView commitAnimations];
}

- (void)LoadUI
{
    [annotationTextView SetPlaceholderText:[NSString stringWithFormat:@"Tell your story"]];
    [annotationTextView becomeFirstResponder];
    id keyboard;
    
    //loop through subviews and find the kayboard. set the return key off and adjust transparency
    for(int i = 0; i < [annotationTextView.subviews count]; i++)
	{
		keyboard = [annotationTextView.subviews objectAtIndex:i];
		if([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES)
        {
            [keyboard setAlpha:0.7];
            break;
        }
    }
    
    //hide progressView
    [progressView setHidden:YES];

    [timestampLabel setFont:[UIFont fontWithName:@"Akkurat" size:timestampLabel.font.pointSize]];
    [locationLabel setFont:[UIFont fontWithName:@"Akkurat" size:locationLabel.font.pointSize]];
    
    //time string, it takes the stores date, parses it and makes the
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM, YYYY h:mma"];

    NSString *temp =[formatter stringFromDate:[NSDate date]];
    temp  = [temp stringByReplacingCharactersInRange:NSMakeRange (temp.length-2, 2) withString:[temp substringFromIndex:temp.length-2].lowercaseString];
    timestampLabel.text = temp;
    locationLabel.text = locationDescription;
    
    HMSegmentedControl *segmentedControl = [[HMSegmentedControl alloc] initWithSectionImages:@[[UIImage imageNamed:@"person_unselected"], [UIImage imageNamed:@"place_unselected"], [UIImage imageNamed:@"thing_unselected"], [UIImage imageNamed:@"event_unselected"]] sectionSelectedImages:@[[UIImage imageNamed:@"person_selected"], [UIImage imageNamed:@"place_selected"], [UIImage imageNamed:@"thing_selected"], [UIImage imageNamed:@"event_selected"]]];
    [segmentedControl setFrame:objectSelectionSegmentedControl.frame];
    
    [segmentedControl setSegmentEdgeInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    [segmentedControl setSelectionIndicatorHeight:0.0f];
    [segmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
    [segmentedControl setBackgroundColor:[UIColor clearColor]];
    [segmentedControl setSelectionLocation:HMSegmentedControlSelectionLocationDown];
    [segmentedControl setSelectionStyle:HMSegmentedControlSelectionStyleTextWidthStrip];
    [segmentedControl setSelectedSegmentIndex:1];
    [imageObject setCategoryID:2];
    
    [self.view addSubview:segmentedControl];
}

- (void)setCapturedImage:(FluxScanImageObject *)imgObject andImage:(UIImage *)theImage andLocationDescription:(NSString *)theLocationString
      andNetworkServices:(FluxNetworkServices *)theNetworkServices
{
    imageObject = imgObject;
    capturedImage = theImage;
    locationDescription = theLocationString;
    networkServices = theNetworkServices;
    [networkServices setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)PopViewController:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AnnotationViewPopped" object:imageObject];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)ConfirmImage:(id)sender
{
    [imageObject setDescriptionString:annotationTextView.text];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool savelocally = [[defaults objectForKey:@"Save Pictures"]boolValue];
    bool pushToCloud = [[defaults objectForKey:@"Network Services"]boolValue];
    
    // Generate a string image id for local use
    NSString *localID = [imageObject generateUniqueStringID];
    [imageObject setLocalID:localID];
    [imageObject setLocalThumbID:[NSString stringWithFormat:@"%@_thumb", imageObject.localID]];
//    [imageObject setImageIDFromDateAndUser];
    
    // Set the server-side image id to a negative value until server returns actual
    [imageObject setImageID:-1];
    
    // Add the image and metadata to the local cache
    [fluxImageCache setObject:capturedImage forKey:imageObject.localID];
    [fluxMetadata setObject:imageObject forKey:imageObject.localID];
    
    // Post notification for observers prior to upload
    NSMutableDictionary *userInfoDict = [[NSMutableDictionary alloc] init];
    [userInfoDict setObject:imageObject.localID forKey:FluxImageAnnotationDidAcquireNewPictureLocalIDKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageAnnotationDidAcquireNewPicture
                                                        object:self userInfo:userInfoDict];
    
    // Perform any additional (optional) image save tasks
    if (savelocally || pushToCloud) {
        if (savelocally)
        {
            UIImageWriteToSavedPhotosAlbum(capturedImage , nil, nil, nil);
        }
        if (pushToCloud)
        {
            [acceptButton setEnabled:NO];
            [annotationTextView setUserInteractionEnabled:NO];
            [networkServices uploadImage:imageObject andImage:capturedImage];
            
            // For now, exit immediately
            [self PopViewController:nil];
        }
        //if we're not waiting for the OK from network services to exit the view, exit right here.
        else
        {
            [self PopViewController:nil];
        }

    }
    else
    {
        [self PopViewController:nil];
    }


}
@end
