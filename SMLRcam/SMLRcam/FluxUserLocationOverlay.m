//
//  FluxUserLocationOverlay.m
//  Flux
//
//  Created by Kei Turner on 1/20/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxUserLocationOverlay.h"





@implementation FluxUserLocationOverlay

- (id) init{
    
    if ((self = [super init])) {
        //customize here
        
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.bounds = CGRectMake(0, 0, 22, 22);
        self.pulseScaleFactor = 5.3;
        self.pulseAnimationDuration = 1.5;
        self.outerPulseAnimationDuration = 3;
        self.delayBetweenPulseCycles = 0;
        self.annotationColor = [UIColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1];
    }
    
    return self;
}

- (MKMapRect)boundingMapRect{
    MKMapPoint upperLeft = MKMapPointForCoordinate(self.coordinate);
    MKMapRect bounds = MKMapRectMake(upperLeft.x, upperLeft.y, self.radius*2, self.radius*2);
    return bounds;
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate{
    _coordinate = coordinate;
    self.boundingMapRect = self.boundingMapRect;
}
+ (NSMutableDictionary*)cachedRingImages {
    static NSMutableDictionary *cachedRingLayers = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{ cachedRingLayers = [NSMutableDictionary new]; });
    return cachedRingLayers;
}


- (void)rebuildLayers {
    [_colorHaloLayer removeFromSuperlayer];
    _colorHaloLayer = nil;
    
    [_colorStaticLayer removeFromSuperlayer];
    _colorStaticLayer = nil;
    
    _pulseAnimationGroup = nil;
    

    [self.layer addSublayer:self.colorStaticLayer];
    //[self.layer addSublayer:self.colorHaloLayer];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if(newSuperview) {
        [self rebuildLayers];
        //[self popIn];
    }
}

- (void)popIn {
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    bounceAnimation.values = @[@0.05, @1.25, @0.8, @1.1, @0.9, @1.0];
    bounceAnimation.duration = 0.3;
    bounceAnimation.timingFunctions = @[easeInOut, easeInOut, easeInOut, easeInOut, easeInOut, easeInOut];
    [self.layer addAnimation:bounceAnimation forKey:@"popIn"];
}

- (void)setDelayBetweenPulseCycles:(NSTimeInterval)delayBetweenPulseCycles {
    _delayBetweenPulseCycles = delayBetweenPulseCycles;
    
    if(self.superview)
        [self rebuildLayers];
}

- (void)setPulseAnimationDuration:(NSTimeInterval)pulseAnimationDuration {
    _pulseAnimationDuration = pulseAnimationDuration;
    
    if(self.superview)
        [self rebuildLayers];
}

#pragma mark - Getters

- (UIColor *)pulseColor {
    if(!_pulseColor)
        return self.annotationColor;
    return _pulseColor;
}

- (CAAnimationGroup*)pulseAnimationGroup {
    if(!_pulseAnimationGroup) {
        CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        
        _pulseAnimationGroup = [CAAnimationGroup animation];
        _pulseAnimationGroup.duration = self.outerPulseAnimationDuration + self.delayBetweenPulseCycles;
        _pulseAnimationGroup.repeatCount = INFINITY;
        _pulseAnimationGroup.removedOnCompletion = NO;
        _pulseAnimationGroup.timingFunction = defaultCurve;
        
        NSMutableArray *animations = [NSMutableArray new];
        
        CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
        pulseAnimation.fromValue = @0.0;
        pulseAnimation.toValue = @1.0;
        pulseAnimation.duration = self.outerPulseAnimationDuration;
        [animations addObject:pulseAnimation];
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        animation.duration = self.outerPulseAnimationDuration;
        animation.values = @[@0.45, @0.45, @0];
        animation.keyTimes = @[@0, @0.2, @1];
        animation.removedOnCompletion = NO;
        [animations addObject:animation];
        
        _pulseAnimationGroup.animations = animations;
    }
    return _pulseAnimationGroup;
}

#pragma mark - Graphics

- (CALayer*)colorStaticLayer {
    if(!_colorStaticLayer) {
        _colorStaticLayer = [CALayer layer];
        CGFloat width = self.bounds.size.width*self.pulseScaleFactor;
        _colorStaticLayer.bounds = CGRectMake(0, 0, width, width);
        _colorStaticLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _colorStaticLayer.contentsScale = [UIScreen mainScreen].scale;
        _colorStaticLayer.backgroundColor =  [UIColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1].CGColor;
        _colorStaticLayer.cornerRadius = width/2;
        _colorStaticLayer.opacity = 0.1;
    }
    return _colorStaticLayer;
}

- (CALayer *)colorHaloLayer {
    if(!_colorHaloLayer) {
        _colorHaloLayer = [CALayer layer];
        CGFloat width = self.bounds.size.width*self.pulseScaleFactor;
        _colorHaloLayer.bounds = CGRectMake(0, 0, width, width);
        _colorHaloLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _colorHaloLayer.contentsScale = [UIScreen mainScreen].scale;
        _colorHaloLayer.backgroundColor =  [UIColor colorWithRed:0.000 green:0.478 blue:1.000 alpha:1].CGColor;
        _colorHaloLayer.cornerRadius = width/2;
        _colorHaloLayer.opacity = 0;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if(self.delayBetweenPulseCycles != INFINITY) {
                CAAnimationGroup *animationGroup = self.pulseAnimationGroup;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [_colorHaloLayer addAnimation:animationGroup forKey:@"pulse"];
                });
            }
        });
    }
    return _colorHaloLayer;
}


- (UIImage*)circleImageWithColor:(UIColor*)color height:(float)height {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, height), NO, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UIBezierPath* fillPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, height, height)];
    [color setFill];
    [fillPath fill];
    
    UIImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGColorSpaceRelease(colorSpace);
    
    return dotImage;
}




@end
