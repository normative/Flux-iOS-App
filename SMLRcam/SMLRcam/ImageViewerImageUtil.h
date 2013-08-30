//
//  ImageViewerImageUtil.h
//  ImageViewer
//
//  Created by Arjun Chopra on 8/12/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


typedef struct demoImageRec
{
	GLubyte* data;
	
	GLsizei size;
	
	GLuint width;
	GLuint height;
	GLenum format;
	GLenum type;
	
	GLuint rowByteSize;
	
} demoImage;
demoImage* imgLoadImageUIImage(UIImage *image, int flipVertical);
demoImage* imgLoadImage(const char* filepathname, int flipVertical);
demoImage* imgLoadImageJPG(const char* filepathname, int flipVertical);

void imgDestroyImage(demoImage* image);

