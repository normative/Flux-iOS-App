//
//  Flux_LocationServiceSingleton_Test.m
//  Flux
//
//  Created by Jacky So on 2013-08-16.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "FluxLocationServicesSingleton.h"

@interface Flux_LocationServiceSingleton_Test : SenTestCase

- (void) testSharedManager;

@end

@implementation Flux_LocationServiceSingleton_Test

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

- (void)testSharedManager
{
    STAssertNotNil((CLLocationManager *)[FluxLocationServicesSingleton sharedManager], @"Does not return a null object");
}

@end
