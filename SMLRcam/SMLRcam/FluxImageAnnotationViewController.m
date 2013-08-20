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

@interface FluxImageAnnotationViewController ()

@end

@implementation FluxImageAnnotationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - TextView Delegate
- (void)PlaceholderTextViewReturnButtonWasPressed:(KTPlaceholderTextView *)placeholderTextView{
    //[self ConfirmImage:nil];
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
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUploadImage:(FluxScanImageObject *)imageObject{
    progressView.progress = 1;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailWithError:(NSError *)e{
    [acceptButton setEnabled:YES];
}

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices uploadProgress:(float)bytesSent ofExpectedPacketSize:(float)size{
    if (progressView.frame.origin.y != 0) {

        
    }
    //subtract 10 for the end wait
    progressView.progress = bytesSent/size -0.05;
}


#pragma mark - view loading / popping

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    locationManager = [FluxLocationServicesSingleton sharedManager];
    
    [backgroundImageView setImage:[self BlurryImage:capturedImage withBlurLevel:0.2]];
    [self AddGradientImageToBackgroundWithAlpha:0.7];
    
    
    
    [self LoadUI];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    NSLog(@"Annotation Appeared");
}
- (void)viewDidAppear:(BOOL)animated{
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

- (void)LoadUI{
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
            //Keyboard is now a UIView reference to the UIKeyboard we want. From here we can add a subview
            //to th keyboard like a new button
            
            //Do what ever you want to do to your keyboard here...
        }
    }
    
    //hide progressView
    [progressView setHidden:YES];

    
    //time string, it takes the stores date, parses it and makes the
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM, YYYY h:mma"];
    NSString *temp =[formatter stringFromDate:timestamp];
    temp  = [temp stringByReplacingCharactersInRange:NSMakeRange (temp.length-2, 2) withString:[temp substringFromIndex:temp.length-2].lowercaseString];
    timestampLabel.text = temp;
    
    if (locationManager.placemark!=nil) {
        NSString * locationString = [locationManager.placemark.addressDictionary valueForKey:@"SubLocality"];
        locationString = [locationString stringByAppendingString:[NSString stringWithFormat:@", %@", [locationManager.placemark.addressDictionary valueForKey:@"SubAdministrativeArea"]]];
        locationLabel.text = locationString;
    }
    else{
        locationLabel.text = @"";
    }
}

- (void)setCapturedImage:(FluxScanImageObject *)imgObject andImageData:(NSMutableData *)imageData andImageMetadata:(NSMutableDictionary *)imageMetadata andTimestamp:(NSDate *)theTimestamp andLocation:(CLLocation *)theLocation{
    imageObject = imgObject;
    capturedImage = imageObject.contentImage;
    imgData = imageData;
    imgMetadata = imageMetadata;
    timestamp = theTimestamp;
    location = theLocation;
    
    NSString * locationString = [locationManager.placemark.addressDictionary valueForKey:@"SubLocality"];
    locationString = [locationString stringByAppendingString:[NSString stringWithFormat:@", %@", [locationManager.placemark.addressDictionary valueForKey:@"SubAdministrativeArea"]]];
    locationLabel.text = locationString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)PopViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    //[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)ConfirmImage:(id)sender {
    //if they don't want it saved, toss it. If the object doesnt exist (they haven't hit the switch), then it's saved by default.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool savelocally = [[defaults objectForKey:@"Save Pictures"]boolValue];
    bool pushToCloud = [[defaults objectForKey:@"Network Services"]boolValue];
    
    [imgMetadata setValue:annotationTextView.text forKey:(NSString *)@"descriptionString"];
    
    //if we're saving it anywhere
    if (savelocally || pushToCloud) {
        if (savelocally) {
            UIImageWriteToSavedPhotosAlbum(capturedImage , nil, nil, nil);
            
            //saves it locally for now.
            
            //destibnation path
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
            NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"ImagesFolder"];
            NSError *error;
            if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
            {
                [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
            }
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
            
            //add our image to the path
            NSString *fullPath = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [dateFormat stringFromDate:timestamp]]];
            [imgData writeToFile:fullPath atomically:YES];
            
            // build the metadata file...
            NSString *fullPathMeta = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", [dateFormat stringFromDate:timestamp]]];
            [imgMetadata writeToFile:fullPathMeta atomically:YES];
        }
        if (pushToCloud) {
            [progressView setFrame:CGRectMake(progressView.frame.origin.x, -10, progressView.frame.size.width, progressView.frame.size.height)];
            [progressView setHidden:NO];
            [UIView beginAnimations:@"lowerProgressView" context:nil];
            [UIView setAnimationDuration:0.5];
            [progressView setFrame:CGRectMake(progressView.frame.origin.x, 0, progressView.frame.size.width, progressView.frame.size.height)];
            [UIView commitAnimations];
            
            [acceptButton setEnabled:NO];
            progressView.progress = 0;
            [imageObject setDescriptionString:annotationTextView.text];
            FluxNetworkServices *networkServices = [[FluxNetworkServices alloc]init];
            [networkServices setDelegate:self];
            [networkServices uploadImage:imageObject];
        }
        //if we're not waiting for the OK from network services to exit the view, exit right here.
        else{
            [self dismissViewControllerAnimated:YES completion:nil];
        }

    }
    else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }


}
@end
