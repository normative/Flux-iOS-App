//
// MIAnnotation.m
//
// Copyright (c) 2013 Shemet Dmitriy
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MIAnnotation.h"
#import "MIAnnotation+Package.h"
#import "FluxMapImageObject.h"

#define showAltitude NO

@interface MIAnnotation ()
{
	CLLocationCoordinate2D _coordinate;

	MIQuadTreeRef _content;

	NSUInteger _count;

	NSString *_title;
	NSString *_subtitle;
	NSMutableSet *_annotations;
}

@property (nonatomic) NSUInteger count;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) BOOL readAvailable;

- (void)didReceiveMemoryWarning;

@end

@implementation MIAnnotation

#pragma mark - Init

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationDidReceiveMemoryWarningNotification
												  object:nil];
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didReceiveMemoryWarning)
													 name:UIApplicationDidReceiveMemoryWarningNotification
												   object:nil];
	}

	return self;
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning
{
	_annotations = nil;
	_title = nil;
	_subtitle = nil;
}

#pragma mark - MKAnnotation

- (NSString *)title
{
	if (_title == nil && _readAvailable)
	{
        if (showAltitude) {
            _title = [[NSString alloc] initWithFormat:@"%i", (int)_count];
        }
        else{
            _title = [[NSString alloc] initWithFormat:@"%i images", (int)_count];
        }
	}
//    NSLog(@"Count: %lu",(unsigned long)_annotations.count);

	return _title;
}

//uncomment this to show the altitude subtitle
//- (NSString *)subtitle
//{
//    FluxMapImageObject*tmp = (FluxMapImageObject*)[self.allAnnotations anyObject];
//    //double smallest = tmp.latitude;
//    double largest = fabs(tmp.altitudeDiff);
//    
//    for(FluxMapImageObject* obj in self.allAnnotations) {
////        if (obj.latitude < smallest) {
////            smallest = obj.latitude;
////        }
//        if (fabs(obj.latitude) > largest) {
//            largest = fabs(obj.altitudeDiff);
//        }
//    }
//    
//	if (_subtitle == nil && _readAvailable)
//	{
//        BOOL isMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
//        if (isMetric) {
//            _subtitle = [[NSString alloc] initWithFormat:@"±%.fm altitude", largest];
//        }
//        else{
//            _subtitle = [[NSString alloc] initWithFormat:@"±%.fft altitude", largest*0.3048];
//        }
//		
//	}
//
//	return _subtitle;
//}

#pragma mark - MIAnnotation

- (BOOL)contains:(id <MKAnnotation>)annotation
{
	if (!(_readAvailable)) return NO;

	if ([annotation class] == [MIAnnotation class])
	{
        if (!((MIAnnotation *)annotation)->_readAvailable) return NO;
		return MIQuadTreeIsDescendant(_content, ((MIAnnotation *)annotation)->_content);
	}

	return MIQuadTreeContainsPoint(_content, MIPointMake(MKMapPointForCoordinate([annotation coordinate]), (__bridge void *)annotation));
}

void _MIAnnotationTraversCallback(MIPoint point, MITraverseResultType resultType, MITraverse *traverse)
{
	[((__bridge NSMutableSet *) traverse->context) addObject:(__bridge id <MKAnnotation>)point.identifier];
}

- (NSSet *)allAnnotations
{
	if (_annotations == nil && _readAvailable)
	{
		_annotations = [[NSMutableSet alloc] initWithCapacity:_count];

		MITraverse traverse =
		{
			.callback = _MIAnnotationTraversCallback,
			.context = (__bridge void *) _annotations,
		};
		MIQuadTreeTraversPoints(_content, &traverse);
	}

	return _annotations;
}

- (id <MKAnnotation>)anyAnnotation
{
	if (!_readAvailable) return nil;

	if (_annotations != nil)
	{
		return [_annotations anyObject];
	}

	return (__bridge id <MKAnnotation>)MIQuadTreeAnyPoint(_content).identifier;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object
{
	return [self class] == [object class] && self->_content == ((MIAnnotation *)object)->_content;
}

- (NSUInteger)hash
{
	return (NSUInteger)_content;
}

#pragma mark - Properties & Flags

- (void)setContent:(MIQuadTreeRef)content
{
	if (_content == content) return;

	_content = content;

	_annotations = nil;
	_title = nil;
	_subtitle = nil;

	if (_content != NULL)
	{
		[self setReadAvailable:YES];
		[self updateContentData];
	}
	else
	{
		[self setReadAvailable:NO];
	}
}

- (MIQuadTreeRef)content
{
	return _content;
}

- (void)setReadAvailable:(BOOL)readAvailable
{
	_readAvailable = readAvailable && _content != NULL;
}

@end

@implementation MIAnnotation (Package)

@dynamic content, readAvailable;

- (void)updateContentData
{
	if (_readAvailable)
	{
		[self setCount:MIQuadTreeGetCount(_content)];
		[self setCoordinate:MKCoordinateForMapPoint(MIQuadTreeGetCentroid(_content))];
	}
	else
	{
		[self setCount:0];
		[self setCoordinate:(CLLocationCoordinate2D){0.0, 0.0}];
	}
}

@end