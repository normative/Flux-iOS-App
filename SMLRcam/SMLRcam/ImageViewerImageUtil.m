//
//  ImageViewerImageUtil.m
//  ImageViewer
//
//  Created by Arjun Chopra on 8/12/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//

#include "ImageViewerImageUtil.h"

#import <UIKit/UIKit.h>
demoImage *imgLoadImageUIImage(UIImage *imageClass, int flipVertical)
{
    //UIImage* imageClass = [[UIImage alloc] initWithContentsOfFile:filepathString];
	
	CGImageRef cgImage = imageClass.CGImage;
    
    
    /*
     if (!cgImage)
     {
     [filepathString release];
     [imageClass release];
     return NULL;
     }*/
	
	demoImage* image = malloc(sizeof(demoImage));
	image->width = CGImageGetWidth(cgImage);
	image->height = CGImageGetHeight(cgImage);
	image->rowByteSize = image->width * 4;
	image->data = malloc(image->height * image->rowByteSize);
	image->format = GL_RGBA;
	image->type = GL_UNSIGNED_BYTE;
	
	CGContextRef context = CGBitmapContextCreate(image->data, image->width, image->height, 8, image->rowByteSize, CGImageGetColorSpace(cgImage), kCGImageAlphaNoneSkipLast);
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	if(flipVertical)
	{
		CGContextTranslateCTM(context, 0.0, image->height);
		CGContextScaleCTM(context, 1.0, -1.0);
	}
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, image->width, image->height), cgImage);
	CGContextRelease(context);
	
	return image;
    
}
demoImage* imgLoadImageJPG(const char* filepathname, int flipVertical)
{
	NSString *filepathString = [[NSString alloc] initWithUTF8String:filepathname];
	

	UIImage* imageClass = [[UIImage alloc] initWithContentsOfFile:filepathString];
	
	CGImageRef cgImage = imageClass.CGImage;
    /*
	if (!cgImage)
	{
		[filepathString release];
		[imageClass release];
		return NULL;
	}*/
	
	demoImage* image = malloc(sizeof(demoImage));
	image->width = CGImageGetWidth(cgImage);
	image->height = CGImageGetHeight(cgImage);
	image->rowByteSize = image->width * 4;
	image->data = malloc(image->height * image->rowByteSize);
	image->format = GL_RGBA;
	image->type = GL_UNSIGNED_BYTE;
	
	CGContextRef context = CGBitmapContextCreate(image->data, image->width, image->height, 8, image->rowByteSize, CGImageGetColorSpace(cgImage), kCGImageAlphaNoneSkipLast);
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	if(flipVertical)
	{
		CGContextTranslateCTM(context, 0.0, image->height);
		CGContextScaleCTM(context, 1.0, -1.0);
	}
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, image->width, image->height), cgImage);
	CGContextRelease(context);
	/*
	if(NULL == image->data)
	{
		[filepathString release];
		[imageClass release];
		
		imgDestroyImage(image);
		return NULL;
	}
	
	[filepathString release];
	[imageClass release];
	*/
	return image;
}

void imgDestroyImage(demoImage* image)
{
	free(image->data);
	free(image);
}