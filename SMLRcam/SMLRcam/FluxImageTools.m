//
//  FluxImageTools.m
//  Flux
//
//  Created by Kei Turner on 10/31/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxImageTools.h"

@implementation FluxImageTools

-(UIImage*)blurImage:(UIImage *)img withBlurLevel:(float)blurLevel{
    //CGImage blows away image metadata, keep orientation
    UIImageOrientation orientation = img.imageOrientation;
    
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:img.CGImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGAffineTransform transform = CGAffineTransformIdentity;
    CIImage *outputImage;
    
//    CIFilter *darkenFilter= [CIFilter filterWithName:@"CIColorControls"];
//    [darkenFilter setValue:inputImage forKey:@"inputImage"];
//    [darkenFilter setValue:[NSNumber numberWithFloat:0.5] forKey:@"inputBrightness"];
//    outputImage = [darkenFilter outputImage];
    
    //clamp the borders so the blur doesnt shrink the borders of the image
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:inputImage forKey:kCIInputImageKey];
    [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    outputImage = [clampFilter outputImage];
    
    float blur = blurLevel*50;
    
    //adds gaussian blur to the image
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputImageKey, outputImage, @"inputRadius", [NSNumber numberWithFloat:blur], nil];
    outputImage = [blurFilter outputImage];

    

    
    //output the image
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:inputImage.extent];
    UIImage *blurredImage = [UIImage imageWithCGImage:cgimg scale:1.0 orientation:orientation];
    CGImageRelease(cgimg);
    
    return blurredImage;
}


@end
