//
//  FluxLoggerService.m
//  Flux
//
//  Created by Ryan Martens on 3/4/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxLoggerService.h"
#import "FluxDebugViewController.h"

@implementation FluxLoggerService
{
    DDFileLogger *fileLogger;
}

+ (id)sharedLoggerService {
    static FluxLoggerService *sharedFluxLoggerServiceSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFluxLoggerServiceSingleton = [[self alloc] init];
    });
    return sharedFluxLoggerServiceSingleton;
}

- (id)init
{
    if (self = [super init])
    {
        [self setupLogger];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureFileLogger) name:FluxDebugDidChangeDetailLoggerEnabled object:nil];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDebugDidChangeDetailLoggerEnabled object:nil];
}

- (void)setupLogger
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [self configureFileLogger];
    
    DDLogVerbose(@"Logging to TTY configured...");
}

- (void)configureFileLogger
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool enableDetailLogger = [[defaults objectForKey:FluxDebugDetailLoggerEnabledKey] boolValue];

    if (enableDetailLogger)
    {
        fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        
        [DDLog addLogger:fileLogger];
        
        DDLogVerbose(@"Logging is setup (\"%@\")", [fileLogger.logFileManager logsDirectory]);
    }
    else
    {
        if (fileLogger)
        {
            // TODO: Should probably remove all old logs from device
            NSArray *logFileNames = [fileLogger.logFileManager unsortedLogFileNames];
            NSLog(@"Log files: %@ in path %@", logFileNames, [fileLogger.logFileManager logsDirectory]);
            
            [DDLog removeLogger:fileLogger];
            fileLogger = nil;
        }
        
        DDLogVerbose(@"Logging to file is disabled...");
    }
}

- (NSMutableArray *)errorLogData
{
    NSMutableArray *errorLogFiles = [[NSMutableArray alloc] init];
    NSArray *sortedLogFileInfos = [fileLogger.logFileManager sortedLogFileInfos];
    for (DDLogFileInfo *logFileInfo in [sortedLogFileInfos reverseObjectEnumerator])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:logFileInfo.filePath];
        [errorLogFiles addObject:fileData];
    }
    return errorLogFiles;
}

@end
