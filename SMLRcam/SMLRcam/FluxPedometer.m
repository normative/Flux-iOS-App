//
//  FluxPedometer.m
//  Flux
//
//  Created by Denis Delorme on 10/18/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxPedometer.h"

const int THRESHOLD_WINDOW_SIZE  = 40;              // sliding window size (1/60's second) for back-checking for horizontal accel peaks after vert threshold reached
const int SPEED_CALC_WINDOW_SIZE = 75;              // sliding window size (1/60's second) for back-checking for approx speed calc after vert threshold reached

const double ACCEL_VERT_LOW_THRESHOLD = -0.075;     // vert accel < threshold is required (but not sufficient) for (first) step trigger
const double ACCEL_VERT_RETURN_THRESHOLD = 0.0;     // vert accel > threshold "resets" step state to look for next step valley
const double ACCEL_HORIZ_THRESHOLD = 0.08;          // horiz accel > threshold is required (but not sufficient) for (first) step trigger
const double ACCEL_DHORIZ_THRESHOLD = 0.0075;       // d(horiz accel) > threshold is required (but not sufficient) for (first) step trigger
const double VELOCITY_THRESHOLD = 0.175;            // minimum velocity in m/s

const double MAX_HORIZ_ACCEL =  0.3;
const double MIN_HORIZ_ACCEL = -0.3;
const double MAX_VERT_ACCEL  =  0.4;
const double MIN_VERT_ACCEL  = -0.4;
const double MAX_DELTA      =  0.03;
const double MIN_DELTA      = -0.04;

const double MAX_STRIDE_TIME = 1.3;
const double MIN_STRIDE_TIME = 0.1;

const int BLOCK_SIZE_AVG  = 10;       // setup the block size for the (averaging) low pass filter


@interface FluxPedometer ()



@end

@implementation FluxPedometer

- (FluxPedometer *)init
{
    countState = stepCount = 0;
    
    samplecount = 0;
    vertAccelTrend = FLAT;
    
//    [self setupLogging];

//    isPaused = NO;
    
	// Do any additional setup after loading the view, typically from a nib.
    
    return self;
}

#pragma mark - motion manager
// this code needs to be executed/set up from whatever creates the Pedometer
//- (void)setupMotionManager{
//    motionManager = [[CMMotionManager alloc] init];
//    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
//    if (!motionManager.isDeviceMotionAvailable) {
//    }
//    
//    [motionManager startDeviceMotionUpdates];
//    [motionManager startAccelerometerUpdates];
//    
//    [self startDeviceMotion];
//}
//
//- (void)startDeviceMotion{
//    if (motionManager) {
//        // New in iOS 5.0: Attitude that is referenced to true north
//        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
//        motionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1/60.0 target:self selector:@selector(UpdateDeviceMotion:) userInfo:nil repeats:YES];
//    }
//}
//
//- (void)stopDeviceMotion{
//    if (motionManager) {
//        [motionManager stopDeviceMotionUpdates];
//        [motionUpdateTimer invalidate];
//    }
//}

- (CMAcceleration *)reorientAccels:(CMDeviceMotion *)devM withOutAccels:(CMAcceleration *)outaccels
{
    // do whatever needs to be done to transform existing device motion / accels
    // to compensate for device orientation
    
    if ((outaccels != nil) && (devM != nil))
    {
        outaccels->x = devM.userAcceleration.x;
        outaccels->y = devM.userAcceleration.y;
        outaccels->z = devM.userAcceleration.z;
    }
    
    return outaccels;
}

- (void)processMotion:(CMDeviceMotion *)devMotion
{
//    if (!isPaused)
    {
        // do the filtering prior to drawing...
        double currsample = 0.0;
        double slopeDir = 0.0;
        double speed = 0.0;
        CMAcceleration newAccels;
        
        [self reorientAccels:devMotion withOutAccels:&newAccels];
        
        // raw sample
        samples[0][samplecount] = newAccels.x;    // lateral (l/r)
        samples[1][samplecount] = newAccels.y;    // vertical (u/d)
        samples[2][samplecount] = newAccels.z;    // line-of-sight (f/b)
        
        double sum[3] = { 0.0, 0.0, 0.0 };
        
        // average of last BLOCK_SIZE_AVG raw samples (poor-mans low pass filter)
        for (int x = 0; x < BLOCK_SIZE_AVG; x++)
        {
            int idx = ((samplecount - x) + MAXSAMPLES) % MAXSAMPLES;
            sum[0] = sum[0] + samples[0][idx];
            sum[2] = sum[2] + samples[2][idx];
        }
        
        lpf[0][samplecount] = sum[0] / (double)(BLOCK_SIZE_AVG);
        lpf[2][samplecount] = sum[2] / (double)(BLOCK_SIZE_AVG);
        currsample = lpf[2][samplecount];
        
        sum[0] = sum[1] = sum[2] = 0.0;
        
        // unaveraged delta of current raw vertical accel value with previous value
        int lastsampleidx = (samplecount - 1 + MAXSAMPLES) % MAXSAMPLES;
        
        delta[1][samplecount] = samples[1][samplecount] - samples[1][lastsampleidx];
        
        // determine accel line direction trend
        trendDir currAccelTrend = (delta[1][samplecount] < 0.0) ? FALLING : RISING;
        trendDir prevAccelTrend = (delta[1][lastsampleidx] < 0.0) ? FALLING : RISING;
        currAccelTrend = (currAccelTrend == prevAccelTrend) ? currAccelTrend : FLAT;
        
        bool peakFound = ((vertAccelTrend != currAccelTrend) && (currAccelTrend != FLAT));
        
        if (peakFound)
        {
            vertAccelTrend = currAccelTrend;
            
            // now figure out if we have started walking...
            int peakIdx = (samplecount - 2 + MAXSAMPLES) % MAXSAMPLES;
            if (!isWalking)
            {
                if ((samples[1][peakIdx] < ACCEL_VERT_LOW_THRESHOLD) && (samples[1][peakIdx] > MIN_VERT_ACCEL) && (vertAccelTrend == RISING))        // vert accel threshold ~ -0.1
                {
                    // have a valley point in vertical accel - look for thresholded horiz accels and calc speed in sliding window
                    bool foundHorizAccel = false;
                    
                    double lastSample = 0;
                    bool foundFirstZero = false;
                    bool foundSecondZero = false;
                    int segmentCount = 0;
                    bool movingForward = false;
                    double maxHAccel = 0.0;
                    double minHAccel = 0.0;
                    
                    lastSample = lpf[2][peakIdx];
                    
                    for (int x = 0; ((x < SPEED_CALC_WINDOW_SIZE) && !(foundHorizAccel && foundSecondZero)); x++)
                    {
                        int idx = ((peakIdx - x) + MAXSAMPLES) % MAXSAMPLES;
                        
                        if ((lastSample >= 0.0) && (lpf[2][idx] < 0.0))
                        {
                            // crossed 0 from + to - (traversing backwards through samples)
                            if (!foundFirstZero)
                            {
                                // moving backwards??
                                movingForward = false;
                                foundFirstZero = true;
                            }
                            else
                            {
                                // end of speed calc
                                foundSecondZero = true;
                            }
                        }
                        else if ((lastSample <= 0.0) && (lpf[2][idx] > 0.0))
                        {
                            // crossed 0 from - to + (traversing backwards through samples)
                            if (!foundFirstZero)
                            {
                                // moving forwards??
                                movingForward = true;
                                foundFirstZero = true;
                            }
                            else
                            {
                                foundSecondZero = true;
                            }
                        }
                        
                        if (!foundHorizAccel)
                        {
                            if (lpf[2][idx] > maxHAccel)
                            {
                                maxHAccel = lpf[2][idx];
                            }
                            else if (lpf[2][idx] < minHAccel)
                            {
                                minHAccel = lpf[2][idx];
                            }
                            if ((foundFirstZero) && (!foundHorizAccel))
                            {
                                if (movingForward)
                                {
                                    foundHorizAccel = (maxHAccel >= ACCEL_HORIZ_THRESHOLD);
                                }
                                else
                                {
                                    foundHorizAccel = (minHAccel <= -ACCEL_HORIZ_THRESHOLD);
                                }
                            }
                        }
                        
                        lastSample = lpf[2][idx];
                        
                        if ((foundFirstZero) && (!foundSecondZero))
                        {
                            speed += lpf[2][idx];
                            ++segmentCount;
                        }
                        
                        // too far back to find lateral accel peak.
                        if ((x > THRESHOLD_WINDOW_SIZE) && (!foundHorizAccel))
                            break;
                    }
                    
                    if (segmentCount > 0)
                    {
                        // accels in G's - convert to a useful unit (m/s/s)
                        speed = fabs((speed * 9.81) / 60.0);      // set up speed as ?m?/s, take magnitude
                    }
                    
                    if (foundHorizAccel && (speed > VELOCITY_THRESHOLD))
                    {
                        [self turnWalkingOn:movingForward];
                        countState = 1;
                    }
                }
            }
            else
            {
                if ((samples[1][samplecount] > MAX_VERT_ACCEL) || (samples[1][samplecount] < MIN_VERT_ACCEL)
                    || (fabs(lpf[2][samplecount]) > MAX_HORIZ_ACCEL) || -fabs((lpf[2][samplecount]) < MIN_HORIZ_ACCEL))
                {
                    // accel out of range - stop walking
                    [self turnWalkingOff];
                    countState = 0;
                }
                else
                {
                    if (countState == 1)
                    {
                        if ((vertAccelTrend == FALLING) && (samples[1][peakIdx] > ACCEL_VERT_RETURN_THRESHOLD))
                        {
                            // apex of leg swing
                            if ([self didTakeStep])
                            {
                                countState = 0;
                            }
                        }
                    }
                    else if ((vertAccelTrend == RISING) && samples[1][peakIdx] < ACCEL_VERT_LOW_THRESHOLD)
                    {
                        // foot-fall
                        countState = 1;
                    }
                }
            }
        }
        
        if (isWalking)
            slopeDir = 2.0;
        else
            slopeDir = 0.0;
        
        NSString *logStr = [NSString stringWithFormat:@"%f, %f, %f, %f, %f, %f, %d, %d, %f, %f\n",
                            samples[0][samplecount],
                            samples[1][samplecount],
                            samples[2][samplecount],
                            lpf[2][samplecount],
                            delta[2][samplecount],
                            delta[1][samplecount],
                            vertAccelTrend,
                            (peakFound ? 1 : 0),
                            (walkingDirection * 0.2),
                            speed
                            ];
        [self writeMotionLog:logStr];
        
        if ((++samplecount) >= MAXSAMPLES)
            samplecount %= MAXSAMPLES;
        
    }
}

#pragma mark - step count logic

- (bool)didTakeStep
{
    if (walkingTimer)
    {
        double timeSinceLastStep = ([[NSDate date] timeIntervalSinceDate:[walkingTimer fireDate]]) + 1;
        
        //error check, in this time a person could not take a step
        if (timeSinceLastStep < MIN_STRIDE_TIME)
        {
            return false;
        }
        else
        {
            [walkingTimer invalidate];
            walkingTimer = nil;
        }
    }
    
    switch (walkingDirection) {
        case FORWARDS:
            stepCount++;
            break;
        case BACKWARDS:
            stepCount--;
            break;
        default:
            break;
    }
    
    walkingTimer = [NSTimer scheduledTimerWithTimeInterval:MAX_STRIDE_TIME
                                                    target:self
                                                  selector:@selector(turnWalkingOff)
                                                  userInfo:nil
                                                   repeats:NO];
    return true;
}

- (void)turnWalkingOn:(bool)movingForward
{
    isWalking = YES;
    
    if (movingForward)
    {
        walkingDirection = FORWARDS;
    }
    else
    {
        walkingDirection = BACKWARDS;
    }
}

- (void)turnWalkingOff{
    isWalking = NO;
    walkingDirection = UNKNOWN;
    if (walkingTimer)
    {
        [walkingTimer invalidate];
        walkingTimer = nil;
    }
    
    NSLog(@"Cancelled");
}

#pragma mark - Logging

- (void) setupLogging
{
    dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd', 'HH':'mm':'ss'.'SSS', '"];
    
//    motionFileLock = [[NSLock alloc] init];
    
    [self createNewLogFiles];
}

- (void) createNewLogFiles
{
    NSDateFormatter *fileDateFormat = [[NSDateFormatter alloc] init];
    [fileDateFormat setDateFormat:@"yyyyMMdd'_'HHmmss"];
    
    NSDate *curDate = [NSDate date];
    NSString *curDateString = [fileDateFormat stringFromDate:curDate];
    
    NSString *motionName = [NSString stringWithFormat:@"Documents/%@_accel.csv", curDateString];
    
//    [motionFileLock lock];
    
    motionFilename = [NSHomeDirectory() stringByAppendingPathComponent:motionName];
    [[NSFileManager defaultManager] createFileAtPath:motionFilename contents:nil attributes:nil];
    motionFile = [NSFileHandle fileHandleForWritingAtPath:motionFilename];
    
    NSString *motionFileHeader = @"Date, Time, X (lr), Y (ud), Z (fb), lpf, delta, delta vert, trend, peakFound, isWalking, speed\n";
    [motionFile writeData:[motionFileHeader dataUsingEncoding:NSUTF8StringEncoding]];
    
//    [motionFileLock unlock];
}

- (void) writeMotionLog:(NSString *)logmsg
{
    if (motionFile == nil)
    {
        return;
    }
    
    NSDate *curDate = [NSDate date];
    NSString *curDateString = [dateFormat stringFromDate:curDate];
    
    NSString *outStr = [curDateString stringByAppendingString:logmsg];
    
//    [motionFileLock lock];
    
    [motionFile writeData:[outStr dataUsingEncoding:NSUTF8StringEncoding]];
    
//    [motionFileLock unlock];
}
@end
