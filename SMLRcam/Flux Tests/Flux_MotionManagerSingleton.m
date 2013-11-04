//
//  Flux_MotionManagerSingleton.m
//  Flux
//
//  Created by Jacky So on 2013-08-16.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "FluxMotionManagerSingleton.h"

@interface Flux_MotionManagerSingleton : SenTestCase

@end

@implementation Flux_MotionManagerSingleton

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testShareManager
{
    STAssertNotNil((CMMotionManager *)[FluxMotionManagerSingleton sharedManager], @"Does not return a null object");
}

- (void)testStartLocating
{
    
}

@end
