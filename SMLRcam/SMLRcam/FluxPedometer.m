//
//  FluxPedometer.m
//  Flux
//
//  Created by Denis Delorme on 10/18/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

//#define PED_APP

#import "FluxPedometer.h"
#ifdef PED_APP
#import "ViewController.h"
#endif

const int THRESHOLD_WINDOW_SIZE  = 40;              // sliding window size (1/60's second) for back-checking for horizontal accel peaks after vert threshold reached
const int SPEED_CALC_WINDOW_SIZE = 75;              // sliding window size (1/60's second) for back-checking for approx speed calc after vert threshold reached

const double ACCEL_VERT_LOW_THRESHOLD = -0.075;     // vert accel < threshold is required (but not sufficient) for (first) step trigger
const double ACCEL_VERT_RETURN_THRESHOLD = 0.0;     // vert accel > threshold "resets" step state to look for next step valley
const double ACCEL_HORIZ_THRESHOLD = 0.08;          // horiz accel > threshold is required (but not sufficient) for (first) step trigger
const double ACCEL_HORIZ_MAX_THRESHOLD = 0.2;       // horiz accel < threshold is required (but not sufficient) for (first) step trigger
const double ACCEL_DHORIZ_THRESHOLD = 0.0075;       // d(horiz accel) > threshold is required (but not sufficient) for (first) step trigger
const double VELOCITY_THRESHOLD = 0.175;            // minimum velocity in m/s

const double MAX_HORIZ_ACCEL =  0.3;
const double MIN_HORIZ_ACCEL = -0.3;
const double MAX_VERT_ACCEL  =  0.4;
const double MIN_VERT_ACCEL  = -0.4;
const double MAX_DELTA      =  0.03;
const double MIN_DELTA      = -0.04;

const double MAX_STRIDE_TIME = 1.3;
const double MIN_STRIDE_TIME = 0.4;

const int BLOCK_SIZE_AVG  = 10;       // setup the block size for the (averaging) low pass filter

const double G_IN_M_PER_SEC2 = 9.81;

const double MOTION_POLL_INTERVAL = (1.0 / 60.0);

NSString* const FluxPedometerDidTakeStep = @"FluxPedometerDidTakeStep";


@interface FluxPedometer ()


@end

#ifdef PED_APP
ViewController *viewcontroller = nil;
#endif

@implementation FluxPedometer

- (FluxPedometer *)init
{
    countState = stepCount = 0;
    
    samplecount = 0;
    vertAccelTrend = FLAT;
    
//    [self setupMotionManager];
//    
//    if ((motionData == nil) || (motionData.count == 0))
//    {
//        [self setupLogging];
//    }

//    isPaused = NO;
    
	// Do any additional setup after loading the view, typically from a nib.
    
    return self;
}

- (void) setIsPaused:(bool)ip
{
    _isPaused = ip;
//    stepCount = 0;
    
}

#ifdef PED_APP
- (void) setViewController:(UIViewController *)vc
{
    viewcontroller = (ViewController *)vc;
}
#endif

#pragma mark - motion manager

- (void)UpdateDeviceMotion:(NSTimer*)timer
{
//  REFACTOR
//    if ((motionManager) && ([motionManager isDeviceMotionActive]))
//    {
    
    if ((((motionManager) && ([motionManager isDeviceMotionActive])) ||
         (motionData.count > 0))  && !_isPaused)
    {
        [self processMotion:motionManager.deviceMotion];
    }
}

// this code needs to be executed/set up from whatever creates the Pedometer
- (void)setupMotionManager
{
    [self readMotionLog];
    
    if ((motionData == nil) || (motionData.count == 0))
    {
        motionManager = [[CMMotionManager alloc] init];
        motionManager.deviceMotionUpdateInterval = MOTION_POLL_INTERVAL;
        if (!motionManager.isDeviceMotionAvailable) {
        }
    }
    
    [self startDeviceMotion];
}

- (void)startDeviceMotion
{
    // New in iOS 5.0: Attitude that is referenced to true north
    if (((motionData == nil) || (motionData.count == 0)) && motionManager)
    {
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
    }
    
    // give motion manager 2s to settle a little before tracking...
    motionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(StartUpdateDeviceMotion:) userInfo:nil repeats:NO];
    
}

- (void)stopDeviceMotion{
    if (motionManager)
    {
        [motionManager stopDeviceMotionUpdates];
    }

    [motionUpdateTimer invalidate];
}

- (void)StartUpdateDeviceMotion:(NSTimer*)timer
{
//    nextDataIdx = 120;
    motionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:MOTION_POLL_INTERVAL target:self selector:@selector(UpdateDeviceMotion:) userInfo:nil repeats:YES];
//    timeSinceLastCheck = [NSDate date];
//    velocity[0] = 0.0;
//    velocity[1] = 0.0;
//    velocity[2] = 0.0;
    accelAccumZ.x = 0.0;
    accelAccumZ.y = 0.0;
    accelAccumZ.z = 0.0;
    accelCount = 0;
}

- (CMAcceleration *)fetchNextAccelsInto:(CMAcceleration *)outaccels
{
    if (nextDataIdx < motionData.count)
    {
        NSArray *cols = motionData[nextDataIdx++];
        outaccels->x = [(NSNumber *)(cols[0]) doubleValue];
        outaccels->y = [(NSNumber *)(cols[1]) doubleValue];
        outaccels->z = [(NSNumber *)(cols[2]) doubleValue];
        
        accelAccumZ.x = outaccels->x;
        accelAccumZ.y = outaccels->y;
        accelAccumZ.z = outaccels->z;
        accelCount++;
    }
    else
    {
#ifdef PED_APP
        [viewcontroller pauseButtonTaped:nil];
#endif

        outaccels->x = 0.0;
        outaccels->y = 0.0;
        outaccels->z = 0.0;
        nextDataIdx = 0;        // restart at beginning
    }
    
    return outaccels;
}


- (CMAcceleration *)reorientAccels:(CMDeviceMotion *)devM withOutAccels:(CMAcceleration *)outaccels
{
    // do whatever needs to be done to transform existing device motion / accels
    // to compensate for device orientation
    
    if ((outaccels != nil) && (devM != nil))
    {
        double accelerationY = devM.gravity.x * devM.userAcceleration.x + devM.gravity.y * devM.userAcceleration.y + devM.gravity.z * devM.userAcceleration.z;
        CMAcceleration accelZ, tmpvec;
        double accelerationZ;
        tmpvec.x = accelerationY * devM.gravity.x;
        tmpvec.y = accelerationY * devM.gravity.y;
        tmpvec.z = accelerationY * devM.gravity.z;
        
        // need to pass this too, averaged across a step
        accelZ.x = (devM.userAcceleration.x - tmpvec.x);
        accelZ.y = (devM.userAcceleration.y - tmpvec.y);
        accelZ.z = (devM.userAcceleration.z - tmpvec.z);
        
        accelerationZ = sqrt(accelZ.x * accelZ.x + accelZ.y * accelZ.y + accelZ.z * accelZ.z);
        
        accelAccumZ.x = accelZ.x;
        accelAccumZ.y = accelZ.y;
        accelAccumZ.z = accelZ.z;
        accelCount++;
        
        outaccels->x = 0.0;
        outaccels->y = -accelerationY;
        outaccels->z = accelerationZ * ((devM.userAcceleration.z > 0.0) ? 1.0 : -1.0);
    }
    
    return outaccels;
    
}

//#define SUBSAMPLE   1
//static int loopcount = 0;

- (void)processMotion:(CMDeviceMotion *)devMotion
{
    NSDate *now = [NSDate date];

//    if (!isPaused)
    {
        // do the filtering prior to drawing...
        CMAcceleration newAccels;
        int stepped = 0;
        
        if ((motionData != nil) && (motionData.count > 0))
        {
            [self fetchNextAccelsInto:&newAccels];
        }
        else
        {
            [self reorientAccels:motionManager.deviceMotion withOutAccels:&newAccels];
        }

        // accumulate velocity...
//        if (isWalking)
//        {
//            double multiplier = G_IN_M_PER_SEC2 * [now timeIntervalSinceDate:timeSinceLastCheck];
//            velocity[0] += (newAccels.x * multiplier);
//            velocity[1] += (newAccels.y * multiplier);
//            velocity[2] += (newAccels.z * multiplier);
//        }

//        if ((loopcount % SUBSAMPLE) == 0)
        {
            
            double currsample = 0.0;
            double speed = 0.0;
            
            // raw sample
            samples[0][samplecount] = newAccels.x;    // lateral (l/r)
            samples[1][samplecount] = newAccels.y;    // vertical (u/d)
            samples[2][samplecount] = newAccels.z;    // line-of-sight (f/b)
            
            double sum[3] = { 0.0, 0.0, 0.0 };
            
            // average of last BLOCK_SIZE_AVG raw samples (poor-mans low pass filter)
            for (int x = 0; x < BLOCK_SIZE_AVG; x++)
            {
                int idx = ((samplecount - x) + MAXSAMPLES) % MAXSAMPLES;
//                sum[0] = sum[0] + samples[0][idx];
                sum[1] = sum[1] + samples[1][idx];
                sum[2] = sum[2] + samples[2][idx];
            }
            
//            lpf[0][samplecount] = sum[0] / (double)(BLOCK_SIZE_AVG);
            lpf[1][samplecount] = sum[1] / (double)(BLOCK_SIZE_AVG);
            lpf[2][samplecount] = sum[2] / (double)(BLOCK_SIZE_AVG);
            currsample = lpf[2][samplecount];
            
            sum[0] = sum[1] = sum[2] = 0.0;
            
            // unaveraged delta of current raw vertical accel value with previous value
            int lastsampleidx = (samplecount - 1 + MAXSAMPLES) % MAXSAMPLES;
            
//            delta[1][samplecount] = samples[1][samplecount] - samples[1][lastsampleidx];
            delta[1][samplecount] = lpf[1][samplecount] - lpf[1][lastsampleidx];
            
            // determine accel line direction trend
            trendDir currAccelTrend = (delta[1][samplecount] < 0.0) ? FALLING : RISING;
            trendDir prevAccelTrend = (delta[1][lastsampleidx] < 0.0) ? FALLING : RISING;
            currAccelTrend = (currAccelTrend == prevAccelTrend) ? currAccelTrend : FLAT;
            
            bool peakFound = ((vertAccelTrend != currAccelTrend) && (currAccelTrend != FLAT));
            
            if ((isWalking) && (!horizAccelThresholdReached))
            {
                switch (countState) {
                    case 0:
                        // waiting for foot fall - horiz accel must hit below a threshold (< 0.0)
                        horizAccelThresholdReached = (samples[2][samplecount] < 0.0);
                        break;
                    case 1:
                        // waiting for leg swing - horiz accel must hit above a threshold (>0.0)
                        horizAccelThresholdReached = (samples[2][samplecount] > 0.0);  // works reasonably with lpf
                    default:
                        break;
                }
            }
            
            if (peakFound)
            {
                vertAccelTrend = currAccelTrend;
                
                // go backwards looking for the actual peak
                int idx;
                int idxmin = 0;
                int idxmax = 0;
                double maxa = -2.0;
                double mina = 2.0;
                for (int x = 1; x < BLOCK_SIZE_AVG; x++)
                {
                    idx = (samplecount - x + MAXSAMPLES) % MAXSAMPLES;
                    if (samples[1][idx] < mina)
                    {
                        mina = samples[1][idx];
                        idxmin = idx;
                    }
                    if (samples[1][idx] > maxa)
                    {
                        maxa = samples[1][idx];
                        idxmax = idx;
                    }
                }

//                int peakIdx = (samplecount - 2 + MAXSAMPLES) % MAXSAMPLES;
                int peakIdx;
                
                if (currAccelTrend == RISING)
                {
                    peakIdx = idxmin;
                }
                else
                {
                    peakIdx = idxmax;
                }
                
                // now figure out if we have started walking...
                if (!isWalking)
                {
                    if ((samples[1][peakIdx] < ACCEL_VERT_LOW_THRESHOLD) && (samples[1][peakIdx] > MIN_VERT_ACCEL) && (vertAccelTrend == RISING))        // vert accel threshold ~ -0.1
//                    if ((lpf[1][peakIdx] < ACCEL_VERT_LOW_THRESHOLD) && (lpf[1][peakIdx] > MIN_VERT_ACCEL) && (vertAccelTrend == RISING))        // vert accel threshold ~ -0.1
                    {
                        // have a valley point in vertical accel - look for thresholded horiz accels and calc speed in sliding window
                        bool foundHorizAccel = false;
                        
                        double lastSample = 0;
                        bool foundFirstZero = false;
                        bool foundSecondZero = false;
                        int segmentCount = 0;
                        walkDir movingDirection = UNKNOWN;
                        double maxHAccel = 0.0;
                        double minHAccel = 0.0;
                        
                        lastSample = -lpf[2][peakIdx];      // force a transition right out of the gate

                        for (int x = 0; ((x < SPEED_CALC_WINDOW_SIZE) && !(foundHorizAccel && foundSecondZero)); x++)
                        {
                            int idx = ((peakIdx - x) + MAXSAMPLES) % MAXSAMPLES;
                            
                            if ((lastSample <= 0.0) && (lpf[2][idx] > 0.0))
                            {
                                // crossed 0 from - to + (traversing backwards through samples)
                                if (!foundFirstZero)
                                {
                                    // moving forwards??
                                    movingDirection = FORWARDS;
                                    foundFirstZero = true;
                                }
                                else if ((movingDirection == BACKWARDS) && (segmentCount < 10))
                                {
                                    // wrong side of 0 - change direction and reset
                                    movingDirection = FORWARDS;
                                    segmentCount = 0;
                                    speed = 0.0;
                                    foundHorizAccel = false;
                                }
                                else
                                {
                                    foundSecondZero = true;
                                }
                            }
                            else if ((lastSample >= 0.0) && (lpf[2][idx] < 0.0))
                            {
                                // crossed 0 from + to - (traversing backwards through samples)
                                if (!foundFirstZero)
                                {
                                    // moving backwards??
                                    movingDirection = BACKWARDS;
                                    foundFirstZero = true;
                                }
                                else if ((movingDirection == FORWARDS) && (segmentCount < 10))
                                {
                                    // wrong side of 0 - change direction and reset
                                    movingDirection = BACKWARDS;
                                    segmentCount = 0;
                                    speed = 0.0;
                                    foundHorizAccel = false;
                                }
                                else
                                {
                                    // end of speed calc
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
                                    if (movingDirection == FORWARDS)
                                    {
                                        foundHorizAccel = (maxHAccel >= ACCEL_HORIZ_THRESHOLD);
                                    }
                                    else if (movingDirection == BACKWARDS)
                                    {
                                        foundHorizAccel = (minHAccel <= -ACCEL_HORIZ_THRESHOLD);
                                    }
                                }
                            }
                            
// accels regularly reach this point
//                            if (foundHorizAccel && ((maxHAccel > ACCEL_HORIZ_MAX_THRESHOLD) || (minHAccel > -ACCEL_HORIZ_MAX_THRESHOLD)))
//                            {
//                                // horiz accels out of spec (too high) - not a proper step
//                                foundHorizAccel = false;
//                                break;
//                            }
                            
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
                            [self turnWalkingOn:movingDirection];
                            countState = 1;
                            timeOfLastFootFall = [[NSDate alloc]init];
                            timeOfLastStep = [[NSDate alloc]initWithTimeIntervalSinceNow:-MIN_STRIDE_TIME];
                            currentSpeed = speed;
                            horizAccelThresholdReached = false;
                            vertAccelThresholdReached = false;
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
                        NSLog(@"accel out of range");
                        countState = 0;
                    }
                    else
                    {
                        if (countState == 1)
                        {
                            if ((vertAccelTrend == FALLING) && (samples[1][peakIdx] > ACCEL_VERT_RETURN_THRESHOLD))
                            {
                                // apex of leg swing
                                vertAccelThresholdReached = true;
                            }
                        }
                        else
                        {
                            if ((vertAccelTrend == RISING) && (samples[1][peakIdx] < ACCEL_VERT_LOW_THRESHOLD))
                            {
                                // foot-fall
                                vertAccelThresholdReached = true;
                            }
                        }
                    }
                }
            }

            if (isWalking)
            {
                switch (countState)
                {
                    case 0:
                        // waiting for foot-fall
                        if (horizAccelThresholdReached && vertAccelThresholdReached)
                        {
                            countState = 1;
                            timeOfLastFootFall = now;
                            horizAccelThresholdReached = false;
                            vertAccelThresholdReached = false;
                        }
                        break;
                    case 1:
                        if (horizAccelThresholdReached && vertAccelThresholdReached)
                        {
                            if ([self didTakeStep])
                            {
                                stepped = 2;
                                countState = 0;
                                timeOfLastStep = now;
                                horizAccelThresholdReached = false;
                                vertAccelThresholdReached = false;
                            }
                            else
                            {
                                stepped = -2;
                                if (stepCount == 0)
                                {
                                    [self turnWalkingOff];
                                    countState = 0;
                                    NSLog(@"First Step too short - turning off walking");
                                }
                            }
                        }
                    default:
                        break;
                }
            }
            
            NSString *logStr = [NSString stringWithFormat:@"%f, %f, %f, %f, %f, %f, %d, %d, %f, %f\n",
                                samples[0][samplecount],
                                samples[1][samplecount],
                                samples[2][samplecount],
                                lpf[2][samplecount],
                                delta[2][samplecount],
                                delta[1][samplecount],
                                stepped,
                                (peakFound ? 1 : 0),
                                (walkingDirection * 0.2),
                                speed
                                ];
                
            [self writeMotionLog:logStr];
            
            
#ifdef PED_APP
            
            //do stuff with motion.
//            [viewcontroller.motionGraph addX:motionManager.deviceMotion.userAcceleration.x*10 y:motionManager.deviceMotion.userAcceleration.y*10 z:motionManager.deviceMotion.userAcceleration.z*10];
            [viewcontroller.accelGraph addX:stepped y:samples[1][samplecount]*10 z:lpf[2][samplecount]*10];
//            [viewcontroller.motionGraph addX:walkingDirection * 0.2 y:stepCount z:currentSpeed];
//            [viewcontroller.motionGraph addX:newAccels.x * 10.0 y:newAccels.y * 10.0 z:newAccels.z * 10.0];
            
            [viewcontroller.motionGraph addX:stepped y: lpf[1][samplecount]*10.0 z:(walkingDirection * 2.0)];
            
            [viewcontroller setLabelsForMotion:motionManager.deviceMotion];
            [viewcontroller setLabelsForAcceleration:motionManager.deviceMotion.userAcceleration];
#endif
            
            if ((++samplecount) >= MAXSAMPLES)
                samplecount %= MAXSAMPLES;
            
        }
    }
    
    timeSinceLastCheck = now;
}

#pragma mark - step count logic

- (bool)didTakeStep
{
    NSLog(@"Stepping...");
    
    NSTimeInterval timeSinceLastStep = [[NSDate date] timeIntervalSinceDate:timeOfLastStep];

    //error check, in this time a person could not take a step
    if (timeSinceLastStep < MIN_STRIDE_TIME)
    {
        NSLog(@"Time since last step too short : %f", timeSinceLastStep);
        return false;
    }

    if ((walkingTimer) && (accelCount < (MIN_STRIDE_TIME * 60)))
    {
        NSLog(@"Step too short: (%d)", accelCount);
        return false;
    }
    
    if (walkingTimer)
    {
        [walkingTimer invalidate];
        walkingTimer = nil;
    }
    
    NSNumber *n;
    switch (walkingDirection) {
        case FORWARDS:
            n = [NSNumber numberWithInt:1];
            break;
        case BACKWARDS:
            n = [NSNumber numberWithInt:-1];
            break;
        default:
            n = [NSNumber numberWithInt:0];
            break;
    }

    walkingTimer = [NSTimer scheduledTimerWithTimeInterval:MAX_STRIDE_TIME
                                                    target:self
                                                  selector:@selector(turnWalkingOff)
                                                  userInfo:nil
                                                   repeats:NO];
    
    
    // calc average acceleration over step...
    NSNumber *stepavgx = [NSNumber numberWithDouble:(accelAccumZ.x / accelCount)];
    NSNumber *stepavgy = [NSNumber numberWithDouble:(accelAccumZ.y / accelCount)];
    NSNumber *stepavgz = [NSNumber numberWithDouble:(accelAccumZ.z / accelCount)];
    
    stepCount += [n intValue];
    
    NSLog(@"Took a step (%d), [%d: %@, %@, %@]", stepCount, accelCount, stepavgx, stepavgy, stepavgz);
    
    NSDictionary *userInfoDict = [[NSDictionary alloc]
                                  initWithObjectsAndKeys:n, @"stepDirection",
                                  stepavgx, @"stepAvgAccelX",
                                  stepavgy, @"stepAvgAccelY",
                                  stepavgz, @"stepAvgAccelZ",
                                  nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxPedometerDidTakeStep
                                                        object:self userInfo:userInfoDict];
    
    accelAccumZ.x = 0.0;
    accelAccumZ.y = 0.0;
    accelAccumZ.z = 0.0;
    accelCount = 0;
    
#ifdef PED_APP
    [viewcontroller turnAccelOn:stepCount];
#endif
    
    return true;

}

- (void)turnWalkingOn:(walkDir)movingDirection
{
    isWalking = YES;
    accelAccumZ.x = 0.0;
    accelAccumZ.y = 0.0;
    accelAccumZ.z = 0.0;
    accelCount = 0;
    
    walkingDirection = movingDirection;
    
    NSLog(@"Walking %@ (%d)", ((movingDirection == FORWARDS)?@"Forwards":@"Backwards"), nextDataIdx);

#ifdef PED_APP
    [viewcontroller.walkLight setBackgroundColor:((movingDirection == FORWARDS) ? [UIColor greenColor] : [UIColor blueColor])];
    [viewcontroller.countLabel setText:[NSString stringWithFormat:@"%i",stepCount]];
#endif
}

- (void)turnWalkingOff{
    isWalking = NO;
    walkingDirection = UNKNOWN;
    if (walkingTimer)
    {
        [walkingTimer invalidate];
        walkingTimer = nil;
    }
    
    NSLog(@"Walking Cancelled (%d)", nextDataIdx);
    
#ifdef PED_APP
    [viewcontroller.walkLight setBackgroundColor:[UIColor redColor]];
    [viewcontroller.firstStepLight setBackgroundColor:[UIColor redColor]];
    [viewcontroller.walkingLight setBackgroundColor:[UIColor redColor]];
#endif
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
    
    NSString *motionFileHeader = @"Date, Time, X (lr), Y (ud), Z (fb), lpf, delta, delta vert, stepped, peakFound, isWalking, speed\n";
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


#pragma mark - Log Reading

- (void) readMotionLog
{
    NSString *motionName = @"Documents/source_accel.csv";
    
    motionFilename = [NSHomeDirectory() stringByAppendingPathComponent:motionName];
    
    NSStringEncoding encoding;
    NSError *error = nil;
    
    NSString *file=[[NSString alloc]initWithContentsOfFile:motionFilename usedEncoding:&encoding error:&error];
    NSNumberFormatter *numForm = [[NSNumberFormatter alloc]init];
    [numForm setNumberStyle:NSNumberFormatterDecimalStyle];
    
    motionData = [[NSMutableArray alloc]initWithCapacity:3000];
    nextDataIdx = 0;
    
    [file enumerateLinesUsingBlock:^(NSString *line, BOOL *stop){
        // set *stop = YES; if want to break processing, leave alone otherwise.
        
        NSMutableArray *columns = [[NSMutableArray alloc]initWithArray:[line componentsSeparatedByString:@", "]];
        if ([(NSString *)columns[1] compare:@"Time" options:NSCaseInsensitiveSearch] != NSOrderedSame)
        {
            NSArray *accels = [[NSArray alloc]initWithObjects:[numForm numberFromString:columns[2]], [numForm numberFromString:columns[3]], [numForm numberFromString:columns[4]], nil];
            [motionData addObject:accels];
        }
    }];
}


- (void) resetCount
{
    stepCount =0;
}
@end

//
//// Add the following code to your module to receive the notification:
//// You can see this code in place in FluxDisplayManager.m - uncomment the registration and it will work
//
//// include what is necessary
//#import "FluxPedometer.h"
//
//
//// register the observer - put this in an initialization routine somewhere
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTakeStep:) name:FluxPedometerDidTakeStep object:nil];
//
//
//// implement the notification handler in the body of your code...
//
//- (void)didTakeStep:(NSNotification *)notification{
//    NSNumber *n = [notification.userInfo objectForKey:@"stepDirection"];
//    
//    if (n != nil)
//    {
//        walkDir stepDirection = n.intValue;
//        switch (stepDirection) {
//            case FORWARDS:
//                // add your logic for a single forward step...
//                break;
//            case BACKWARDS:
//                // add your logic for a single backward step...
//                break;
//                
//            default:
//                break;
//        }
//    }
//}

 
