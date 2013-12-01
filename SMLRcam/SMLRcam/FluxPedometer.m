//
//  FluxPedometer.m
//  Flux
//
//  Created by Denis Delorme on 10/18/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

//#define PED_APP

#include <stdio.h>


#import "FluxPedometer.h"
#ifdef PED_APP
#import "ViewController.h"
#endif

const int BLOCK_SIZE_AVG     = 10;       // setup the block size for the (averaging) low pass filter

const int POLL_FREQUENCY     = 60;
const int SAMPLE_POLL_FREQUENCY = 60;
const double MOTION_POLL_INTERVAL = (1.0 / POLL_FREQUENCY);

const int LOG_N              = 6; // Typically this would be at least 10 (i.e. 1024pt FFTs)
const int N                  = (1 << LOG_N);

const int FFT_FREQ_COUNT     = (N/2);
const int HI_FREQ_HIGH       = (FFT_FREQ_COUNT - (FFT_FREQ_COUNT>>3));
const int HI_FREQ_LOW        = ((FFT_FREQ_COUNT >> 1) + (FFT_FREQ_COUNT>>3));


NSString* const FluxPedometerDidTakeStep = @"FluxPedometerDidTakeStep";


@interface FluxPedometer()

@end

#ifdef PED_APP
ViewController *viewcontroller = nil;
#endif

@implementation FluxPedometer

- (FluxPedometer *)init
{
    if (self = [super init])
    {
        [self setupFilterStateVars];
        [self configureFilterParameters];
        [self init_FFT];
        [self setupMotionManager];
        [self setupLogging];
    }
    
    return self;
}

- (void) setupFilterStateVars
{
    stepCount = 0;
    loopcount = 0;
    samplecount = 0;
    fftWalking = FFT_NOT_WALKING;
    fftLastWalking = FFT_NOT_WALKING;
    fftLastKnownWalking = FFT_NOT_WALKING;
    
    for (int x = 0; x < MAXSAMPLES; x++)
    {
        samples[0][x] = 0.0;
        samples[1][x] = 0.0;
        samples[2][x] = 0.0;
        lpf[0][x] = 0.0;
        lpf[1][x] = 0.0;
        lpf[2][x] = 0.0;
        delta[0][x] = 0.0;
        delta[1][x] = 0.0;
        delta[2][x] = 0.0;
        
        result_y[x] = 0.0;
        result_z[x] = 0.0;
        walking_temp[x] = NO;
        walking[x] = NO;
    }
    
    global_peak_times = [[NSMutableArray alloc] init];
    global_valley_times = [[NSMutableArray alloc] init];
    global_blacklist_times = [[NSMutableArray alloc] init];
    
    global_step_counter = 0.0;
    
    start_time_of_current_window = 0.0;
    
    previous_walking_state = NO;
}

- (void) configureFilterParameters
{
    // Basic window size parameters

    window_size = 64;
    step_size = 8;
    delta_t = 1.0/60.0;
    
    // Sustained threshold filter parameters (frequency domain)

    sustained_threshold_y = 0.8;
    sustained_threshold_z = 1.0;
    sustained_count = 20;
    
    // Filter parameters (frequency to time conversion)

    num_frequencies_ifft_keep = 4;
    
    // Acceleration-based step detection parameters (time domain)

    accel_y_step_threshold_pos = 0.05;
    accel_y_step_threshold_neg = -0.05;
    accel_y_step_max_threshold_pos = 0.25;
    accel_y_step_max_threshold_neg = -0.25;
    peak_valley_time_tolerance = 0.2;
    min_peak_to_valley_time = 0.3;
    max_peak_to_valley_time = 1.0;
    direction_window_width = 16;
}

- (void) setIsPaused:(bool)ip
{
    _isPaused = ip;
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
    motionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:MOTION_POLL_INTERVAL target:self selector:@selector(UpdateDeviceMotion:) userInfo:nil repeats:YES];
}

- (CMAcceleration *)fetchNextAccelsInto:(CMAcceleration *)outaccels
{
    if ((motionData != nil) && (motionData.count > 0))
    {
        // pull them from the trace file
        if (nextDataIdx < motionData.count)
        {
            NSArray *cols = motionData[nextDataIdx++];
            outaccels->x = [(NSNumber *)(cols[0]) doubleValue];
            outaccels->y = [(NSNumber *)(cols[1]) doubleValue];
            outaccels->z = [(NSNumber *)(cols[2]) doubleValue];
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
            // clear out existing samples...
            loopcount = 0;
            samplecount = 0;
            
            for (int x = 0; x < MAXSAMPLES; x++)
            {
                samples[0][x] = 0.0;
                samples[1][x] = 0.0;
                samples[2][x] = 0.0;
            }
        }
    }
    else
    {
        // get them from motionManager
        outaccels->x = motionManager.deviceMotion.userAcceleration.x;
        outaccels->y = motionManager.deviceMotion.userAcceleration.y;
        outaccels->z = motionManager.deviceMotion.userAcceleration.z;
    }
    return outaccels;
}


- (CMAcceleration *)reorientAccels:(CMAcceleration *)outaccels
{
    // do whatever needs to be done to transform existing device motion / accels
    // to compensate for device orientation
    
    CMDeviceMotion *devM = motionManager.deviceMotion;
    
    if ((outaccels != nil) && (devM != nil))
    {
        double accelerationY = devM.gravity.x * outaccels->x + devM.gravity.y * outaccels->y + devM.gravity.z * outaccels->z;
        CMAcceleration accelZ, tmpvec;
        double accelerationZ;
        tmpvec.x = accelerationY * devM.gravity.x;
        tmpvec.y = accelerationY * devM.gravity.y;
        tmpvec.z = accelerationY * devM.gravity.z;
        
        // need to pass this too, averaged across a step
        accelZ.x = (devM.userAcceleration.x - tmpvec.x);
        accelZ.y = (devM.userAcceleration.y - tmpvec.y);
        accelZ.z = (devM.userAcceleration.z - tmpvec.z);
        
//        accelerationZ = sqrt(accelZ.x * accelZ.x + accelZ.y * accelZ.y + accelZ.z * accelZ.z);
        accelerationZ = accelZ.z;
        
        outaccels->x = sqrt(accelZ.x * accelZ.x + accelZ.y * accelZ.y + accelZ.z * accelZ.z) * ((devM.userAcceleration.z > 0.0) ? 1.0 : -1.0);
        outaccels->y = -accelerationY;
//        outaccels->z = accelerationZ * ((devM.userAcceleration.z > 0.0) ? 1.0 : -1.0);
        outaccels->z = accelerationZ;
    }
    
    NSString *logStr2 = [NSString stringWithFormat:@"%d,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
                         loopcount,
                         devM.userAcceleration.x,
                         devM.userAcceleration.y,
                         devM.userAcceleration.z,
                         devM.gravity.x,
                         devM.gravity.y,
                         devM.gravity.z,
                         outaccels->x,
                         outaccels->y,
                         outaccels->z
                         ];
    
    [self writeMotionLog:logStr2];
    
    return outaccels;
    
}

# pragma mark - Pedometer Helper Routines (Time Domain Analysis)

- (void) windowedStepDetection:(double[])f withNumElems:(NSUInteger)n
{
    NSDictionary *addedExtrema = [self addValidGlobalExtrema:f withNumElems:n];
    
    NSUInteger peaks_added = [addedExtrema[@"peaks_added"] integerValue];
    NSUInteger valleys_added = [addedExtrema[@"valleys_added"] integerValue];
    
    if ((peaks_added > 0) || (valleys_added > 0))
    {
        // Default to 0.0 for previous value (will result in large delta that won't be valid)
        NSArray *sub_peaks = @[@0.0];
        NSArray *sub_valleys = @[@0.0];
        
        NSUInteger peak_count = [global_peak_times count];
        if (peak_count > peaks_added)
        {
            // Replace with last old peak + all new
            sub_peaks = [global_peak_times subarrayWithRange:
                         (NSRange){peak_count-peaks_added-1, peaks_added+1}];
        }
        else
        {
            // Add all new to end of existing 0.0 element
            sub_peaks = [sub_peaks arrayByAddingObjectsFromArray:
                         [global_peak_times subarrayWithRange:
                          (NSRange){peak_count-peaks_added, peaks_added}]];
        }
        
        NSUInteger valley_count = [global_valley_times count];
        if (valley_count > valleys_added)
        {
            // Replace with last old valley + all new
            sub_valleys = [global_valley_times subarrayWithRange:
                           (NSRange){valley_count-valleys_added-1, valleys_added+1}];
        }
        else
        {
            // Add all new to end of existing 0.0 element
            sub_valleys = [sub_valleys arrayByAddingObjectsFromArray:
                         [global_valley_times subarrayWithRange:
                          (NSRange){valley_count-valleys_added, valleys_added}]];
        }
        
        bool stepsTaken = [self calculateValidStepsWithPeaks:sub_peaks andValleys:sub_valleys];
    }
}

- (bool) calculateValidStepsWithPeaks:(NSArray *)new_peaks andValleys:(NSArray *)new_valleys
{
    bool stepsTaken = NO;
    
    NSUInteger peak_idx = 0;
    NSUInteger valley_idx = 0;
    
    double t_step = 0.0;
    
    if ([new_peaks count] == 1)
    {
        valley_idx = 1;
    }
    else if ([new_valleys count] == 1)
    {
        peak_idx = 1;
    }
    else
    {
        if ([new_peaks[1] doubleValue] < [new_valleys[1] doubleValue])
        {
            peak_idx = 1;
        }
        else
        {
            valley_idx = 1;
        }
    }
    
    while ((peak_idx < [new_peaks count]) && (valley_idx < [new_valleys count]))
    {
        if ([new_peaks[peak_idx] doubleValue] >= [new_valleys[valley_idx] doubleValue])
        {
            // New peak
            t_step = [new_peaks[peak_idx] doubleValue] - [new_valleys[valley_idx] doubleValue];
            if ((t_step > min_peak_to_valley_time) && (t_step < max_peak_to_valley_time))
            {
                global_step_counter = global_step_counter + 0.5;
//                NSLog(@"Step peak at time: %f Delta t: %f Steps: %f",
//                      [new_peaks[peak_idx] doubleValue], t_step, global_step_counter);
                stepsTaken = YES;
                if (global_step_counter <= floor(global_step_counter))
                {
                    [self didTakeStep];
                }
            }
            valley_idx = valley_idx + 1;
        }
        else if ([new_peaks[peak_idx] doubleValue] < [new_valleys[valley_idx] doubleValue])
        {
            // New valley
            t_step = [new_valleys[valley_idx] doubleValue] - [new_peaks[peak_idx] doubleValue];
            if ((t_step > min_peak_to_valley_time) && (t_step < max_peak_to_valley_time))
            {
                global_step_counter = global_step_counter + 0.5;
//                NSLog(@"Step valley at time: %f Delta t: %f Steps: %f",
//                      [new_valleys[valley_idx] doubleValue], t_step, global_step_counter);
                stepsTaken = YES;
                if (global_step_counter <= floor(global_step_counter))
                {
                    [self didTakeStep];
                }
            }
            peak_idx = peak_idx + 1;
        }
    }
    
    return stepsTaken;
}

- (NSDictionary *) addValidGlobalExtrema:(double[])f withNumElems:(NSUInteger)n
{
    NSDictionary *extrema = [self detectLocalMinMaxFromFunction:f withNumElems:n];

    // Apply threshold to f values (y acceleration max/min)
    
    NSMutableArray *threshold_peaks = [[NSMutableArray alloc] init];
    NSMutableArray *threshold_valleys = [[NSMutableArray alloc] init];
    
    for (NSNumber *cur_idx in extrema[@"peak_idx"])
    {
        if (f[[cur_idx intValue]] > accel_y_step_max_threshold_pos)
        {
            // Add to blacklist - don't care if there is overlap in this list, as it will just short-circuit other additions
            double new_blacklist_time = start_time_of_current_window - delta_t*window_size + delta_t*[cur_idx intValue];
            [global_blacklist_times addObject:[NSNumber numberWithDouble:new_blacklist_time]];
            
        }
        else if (f[[cur_idx intValue]] > accel_y_step_threshold_pos)
        {
            [threshold_peaks addObject:cur_idx];
        }
    }

    for (NSNumber *cur_idx in extrema[@"valley_idx"])
    {
        if (f[[cur_idx intValue]] < accel_y_step_max_threshold_neg)
        {
            // Add to blacklist - don't care if there is overlap in this list, as it will just short-circuit other additions
            double new_blacklist_time = start_time_of_current_window - delta_t*window_size + delta_t*[cur_idx intValue];
            [global_blacklist_times addObject:[NSNumber numberWithDouble:new_blacklist_time]];
            
        }
        else if (f[[cur_idx intValue]] < accel_y_step_threshold_neg)
        {
            [threshold_valleys addObject:cur_idx];
        }
    }
    
    // Verify no nearby peaks/valleys in global lists
    // Need to calculate "absolute" time values for each possible index for comparison
    
    NSUInteger peaks_added = [self addUniqueExtrema:threshold_peaks withGlobalList:global_peak_times];
    NSUInteger valleys_added = [self addUniqueExtrema:threshold_valleys withGlobalList:global_valley_times];
    
    // Assemble return values
    
    NSDictionary *returnValues = @{
                                   @"peaks_added": [NSNumber numberWithUnsignedInteger:peaks_added],
                                   @"valleys_added": [NSNumber numberWithUnsignedInteger:valleys_added]
                                   };
    
    return returnValues;
}

- (NSUInteger) addUniqueExtrema:(NSMutableArray *)possible_extrema withGlobalList:(NSMutableArray *)global_extrema
{
    NSUInteger numAdded = 0;
    
    for (NSNumber *cur_idx in possible_extrema)
    {
        double possible_extrema_time = start_time_of_current_window - delta_t*window_size + delta_t*[cur_idx intValue];
        double cur_max_time = possible_extrema_time + peak_valley_time_tolerance;
        double cur_min_time = possible_extrema_time - peak_valley_time_tolerance;
        
        bool uniqueExtrema = YES;
        
        NSArray *all_valid_extrema = [[global_peak_times arrayByAddingObjectsFromArray:global_valley_times] arrayByAddingObjectsFromArray:global_blacklist_times];
        
        for (NSNumber *curGlobalExtrema in all_valid_extrema)
        {
            double curGlobalExtremaTime = [curGlobalExtrema doubleValue];
            if ((curGlobalExtremaTime < cur_max_time) && (curGlobalExtremaTime > cur_min_time))
            {
                // Duplicate extrema - ignore it
                uniqueExtrema = NO;
                break;
            }
        }
        
        // Add if the extrema is unique, and it is not earlier in time than last extrema in list
        if (([global_extrema count] == 0) ||
            (uniqueExtrema && (possible_extrema_time > [[global_extrema lastObject] doubleValue])))
        {
            [global_extrema addObject:[NSNumber numberWithDouble:possible_extrema_time]];
            numAdded++;
        }
    }
    
    return numAdded;
}

// Remove extrema older than specified time
- (void) purgeOldExtrema:(double)purgeTime
{
    // Since extrema are added in order, start at beginning and find all values up until
    // specified time, making a new array out of everything after
    NSRange blacklist_remove = [self findRangeBeforeSpecifiedTime:purgeTime forOrderedArray:global_blacklist_times];
    NSRange peak_remove = [self findRangeBeforeSpecifiedTime:purgeTime forOrderedArray:global_peak_times];
    NSRange valley_remove = [self findRangeBeforeSpecifiedTime:purgeTime forOrderedArray:global_valley_times];
    if (blacklist_remove.location != NSNotFound)
    {
        [global_blacklist_times removeObjectsInRange:blacklist_remove];
    }
    if (peak_remove.location != NSNotFound)
    {
        [global_peak_times removeObjectsInRange:peak_remove];
    }
    if (valley_remove.location != NSNotFound)
    {
        [global_valley_times removeObjectsInRange:valley_remove];
    }
}

- (NSRange) findRangeBeforeSpecifiedTime:(double)purgeTime forOrderedArray:(NSMutableArray *)orderedList
{
    NSUInteger numToRemove = 0;
    for (NSNumber *curTime in orderedList)
    {
        if ([curTime doubleValue] < purgeTime)
        {
            numToRemove++;
        }
        else
        {
            break;
        }
    }
    NSRange validRange = NSMakeRange(NSNotFound, 0);
    
    if (numToRemove > 0)
    {
        validRange = NSMakeRange(0, numToRemove);
    }
    
    return validRange;
}

# pragma mark - Math Helper Routines

- (NSDictionary *) detectLocalMinMaxFromFunction:(double[])f withNumElems:(NSUInteger)n
{
    double firstDiffOut[64];
    int signOut[64];
    int secondDiffOut[64];
    
    if (n>64)
    {
        // Error. Input array too big for temporary variables.
        NSLog(@"%s: Input dimension of f too large.", __func__);
        return nil;
    }
    
    [self diff_double:f into:firstDiffOut withSize:n];
    [self sign:firstDiffOut into:signOut withSize:(n-1)];
    [self diff_int:signOut into:secondDiffOut withSize:(n-1)];
    
    NSArray *valleys = [self find_positive_idx:secondDiffOut withSize:(n-2) addIntToIdx:1];
    NSArray *peaks = [self find_negative_idx:secondDiffOut withSize:(n-2) addIntToIdx:1];
    
    NSDictionary *returnValues = @{
                                @"peak_idx": peaks,
                                @"valley_idx": valleys
                    };
    
    return returnValues;
}

// find_positive_idx and find_negative_idx return the indices of all positive values
// addIntToIdx:(int)idx_shift is used if a constant value needs to be added to the indices
- (NSMutableArray *) find_positive_idx:(int[])x_in withSize:(NSUInteger)n addIntToIdx:(int)idx_shift
{
    NSMutableArray *found_idx = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < n; i++)
    {
        if (x_in[i] > 0)
        {
            [found_idx addObject:[NSNumber numberWithInt:(i+idx_shift)]];
        }
    }
    
    return found_idx;
}

- (NSMutableArray *) find_negative_idx:(int[])x_in withSize:(NSUInteger)n addIntToIdx:(int)idx_shift
{
    NSMutableArray *found_idx = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < n; i++)
    {
        if (x_in[i] < 0)
        {
            [found_idx addObject:[NSNumber numberWithInt:(i+idx_shift)]];
        }
    }
    
    return found_idx;
}

- (void) diff_int:(int[])x_in into:(int[])x_out withSize:(NSUInteger)n
{
    if (n < 2)
    {
        return;
    }
    
    for (int i = 1; i < n; i++)
    {
        x_out[i-1] = x_in[i] - x_in[i-1];
    }
    
    // Pad last element with a zero
    x_out[n-1] = 0;
}

- (void) diff_double:(double[])x_in into:(double[])x_out withSize:(NSUInteger)n
{
    if (n < 2)
    {
        return;
    }
    
    for (int i = 1; i < n; i++)
    {
        x_out[i-1] = x_in[i] - x_in[i-1];
    }
    
    // Pad last element with a zero
    x_out[n-1] = 0;
}

- (void) sign:(double[])x_in into:(int[])x_out withSize:(NSUInteger)n
{
    for (int i = 0; i < n; i++)
    {
        if (x_in[i])
        {
            x_out[i] = x_in[i] > 0 ? 1 : -1;
        }
        else
        {
            x_out[i] = 0;
        }
    }
}

# pragma mark - Main Algorithm

- (void)processMotion:(CMDeviceMotion *)devMotion
{
    int stepTaken = 0;

//    if (!isPaused)
    {
        // do the filtering prior to drawing...
        CMAcceleration newAccels;
        
        [self fetchNextAccelsInto:&newAccels];
        [self reorientAccels:&newAccels];
        
        // raw sample
        samples[0][samplecount] = newAccels.x;    // lateral (l/r)
        samples[1][samplecount] = newAccels.y;    // vertical (u/d)
        samples[2][samplecount] = newAccels.z;    // line-of-sight (f/b)

        double sum[3] = { 0.0, 0.0, 0.0 };
        
        // average of last BLOCK_SIZE_AVG raw samples (poor-mans low pass filter)
        for (int x = 0; x < BLOCK_SIZE_AVG; x++)
        {
            int idx = ((samplecount - x) + MAXSAMPLES) % MAXSAMPLES;
            sum[1] = sum[1] + samples[1][idx];
            sum[2] = sum[2] + samples[2][idx];
        }
        
        lpf[0][samplecount] = 0.0;      // doesn't matter - will be set in do_fft based on inv-fft(y)
        lpf[1][samplecount] = sum[1] / (double)(BLOCK_SIZE_AVG);
        lpf[2][samplecount] = sum[2] / (double)(BLOCK_SIZE_AVG);

        if (((loopcount + 1) % step_size) == 0)
        {
            [self do_analysis];
            
            // Purge old values from global extrema arrays to keep them small and fast
            // Shouldn't need anything older than 2.0 seconds before step-size window start
            if (start_time_of_current_window > 2.0)
            {
                [self purgeOldExtrema:start_time_of_current_window-2.0];
            }
            
            // Update global time tracker
            start_time_of_current_window = start_time_of_current_window + delta_t*step_size;
        }
        
#ifdef PED_APP
            
            //do stuff with motion.
        [viewcontroller setLabelsForAccelerationWithX:stepTaken andY:samples[1][samplecount] andZ:samples[2][samplecount]];

        [viewcontroller.accelGraph addX:fftWalking + stepTaken y:samples[1][samplecount]*10 z:samples[2][samplecount]*10];
//        [viewcontroller.accelGraph addX:y_recon[N-1]*10 y:samples[1][samplecount]*10 z:samples[2][samplecount]*10];
//        [viewcontroller.accelGraph addX:y_recon[N-1]*10 y:lpf[1][samplecount]*10 z:samples[1][samplecount]*10];

#endif

        logStr = [logStr stringByAppendingFormat:@"%d,%d,%d,%d,%d\n",
                                fftLastKnownWalking,
                                fftLastWalking,
                                fftWalking,
                                (isWalking?1:0),
                                stepTaken
                               ];

        [self writeWalkLog:logStr];

        if ((++samplecount) >= MAXSAMPLES)
            samplecount %= MAXSAMPLES;
        
        ++loopcount;
    }
}

#pragma mark - step count logic

- (bool)didTakeStep
{
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
    
    stepCount += [n intValue];
    
    NSLog(@"Took a step (%d)", stepCount);
    
    NSDictionary *userInfoDict = [[NSDictionary alloc]
                                  initWithObjectsAndKeys:n, @"stepDirection",
                                  nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:FluxPedometerDidTakeStep
                                                        object:self userInfo:userInfoDict];
        
    return true;

}

- (void)turnWalkingOn:(walkDir)movingDirection
{
    isWalking = YES;
    walkingDirection = movingDirection;
    
//    NSLog(@"Walking %@ (%d)", ((movingDirection == FORWARDS)?@"Forwards":@"Backwards"), nextDataIdx);

#ifdef PED_APP
    [viewcontroller.walkLight setBackgroundColor:((movingDirection == FORWARDS) ? [UIColor greenColor] : [UIColor blueColor])];
//    [viewcontroller.countLabel setText:[NSString stringWithFormat:@"%i",stepCount]];
#endif
}

- (void)turnWalkingOff{
    isWalking = NO;
    walkingDirection = UNKNOWN;
    
//    NSLog(@"Walking Cancelled (%d)", nextDataIdx);
    
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
    
    [self createNewLogFiles];
}

- (void) createNewLogFiles
{
    NSDateFormatter *fileDateFormat = [[NSDateFormatter alloc] init];
    [fileDateFormat setDateFormat:@"yyyyMMdd'_'HHmmss"];
    
    NSDate *curDate = [NSDate date];
    NSString *curDateString = [fileDateFormat stringFromDate:curDate];
 
    if ((motionData == nil) || (motionData.count == 0))
    {

        // motion log file
        NSString *motionName = [NSString stringWithFormat:@"Documents/%@_accel.csv", curDateString];
        
        motionFilename = [NSHomeDirectory() stringByAppendingPathComponent:motionName];
        [[NSFileManager defaultManager] createFileAtPath:motionFilename contents:nil attributes:nil];
        motionFile = [NSFileHandle fileHandleForWritingAtPath:motionFilename];
        
//        NSString *motionFileHeader = @"Date, Time, cycle, X (lr), Y (ud), Z (fb), lpf, delta, delta vert, stepped, peakFound, isWalking, speed\n";
        NSString *motionFileHeader = @"Date, Time, cycle,X (lr),Y (ud),Z (fb),grav x,grav y,grav z,horiz mag,accel y,accel z\n";
        [motionFile writeData:[motionFileHeader dataUsingEncoding:NSUTF8StringEncoding]];
    }

    // FFT log file
    NSString *fftName = [NSString stringWithFormat:@"Documents/%d_%d_%03d_new_fft.csv", (int)SAMPLE_POLL_FREQUENCY, (int)ceil((double)SAMPLE_POLL_FREQUENCY / (double)step_size), (N/2)  ];
    
    NSString *fftFilename = [NSHomeDirectory() stringByAppendingPathComponent:fftName];
    [[NSFileManager defaultManager] createFileAtPath:fftFilename contents:nil attributes:nil];
    fftFile = [NSFileHandle fileHandleForWritingAtPath:fftFilename];
    
    NSString *fftFileHeader = [NSString stringWithFormat:@"Poll Freq, %d, FFT SubSamp, %d, FFT Freq, %d, FFT N, %d, FFT log(N), %d\n",
                               SAMPLE_POLL_FREQUENCY, step_size, (SAMPLE_POLL_FREQUENCY / step_size), N, LOG_N ];
    [fftFile writeData:[fftFileHeader dataUsingEncoding:NSUTF8StringEncoding]];

//    fftFileHeader = @"sample,raw y,raw z,lpf y,lpf z,mag y1,mag y2,mag z1,mag z2,fftLastKnownWalking,fftLastWalking,fftWalking,fft y1,fft y2,fft z1,fft z2,isWalking,stepTaken\n";
    fftFileHeader = @"sample,raw y,raw z,lpf y,lpf z,";
    for (int k = 1; k <= (N >> 2); k++)
    {
        fftFileHeader = [fftFileHeader stringByAppendingFormat:@"mag Y%03d,mag Z%03d,", k, k];
    }
    
    for (int k = 1; k <= (N >> 2); k++)
    {
        
        fftFileHeader = [fftFileHeader stringByAppendingFormat:@"abs Y%03d,abs Z%03d", k, k];
        if (k < (N >> 2))
        {
            // add comma
            fftFileHeader = [fftFileHeader stringByAppendingString:@","];
        }
        else
        {
            // add CR
            fftFileHeader = [fftFileHeader stringByAppendingString:@"\n"];
        }
    }
    
    [fftFile writeData:[fftFileHeader dataUsingEncoding:NSUTF8StringEncoding]];
    
    // walking log file
    NSString *walkName = [NSString stringWithFormat:@"Documents/%d_%d_%03d_new_walk.csv", (int)SAMPLE_POLL_FREQUENCY, (int)ceil((double)SAMPLE_POLL_FREQUENCY / (double)step_size), (N/2)  ];
    
    NSString *walkFilename = [NSHomeDirectory() stringByAppendingPathComponent:walkName];
    [[NSFileManager defaultManager] createFileAtPath:walkFilename contents:nil attributes:nil];
    walkFile = [NSFileHandle fileHandleForWritingAtPath:walkFilename];
    
    NSString *walkFileHeader = @"sample,raw y,raw z,lpf y,lpf z,sum y,sum z,fftLastKnownWalking,fftLastWalking,fftWalking,isWalking,stepTaken\n";
    [walkFile writeData:[walkFileHeader dataUsingEncoding:NSUTF8StringEncoding]];
    
    

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
    
    [motionFile writeData:[outStr dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) writeFftLog:(NSString *)logmsg
{
    if (fftFile == nil)
    {
        return;
    }
    
    [fftFile writeData:[logmsg dataUsingEncoding:NSUTF8StringEncoding]];
    
}

- (void) writeWalkLog:(NSString *)logmsg
{
    if (walkFile == nil)
    {
        return;
    }
    
    [walkFile writeData:[logmsg dataUsingEncoding:NSUTF8StringEncoding]];
    
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
        
        NSMutableArray *columns = [[NSMutableArray alloc]initWithArray:[line componentsSeparatedByString:@","]];
        NSString *col1 = [(NSString *)columns[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([col1 compare:@"Time" options:NSCaseInsensitiveSearch] != NSOrderedSame)
        {
            NSArray *accels = [[NSArray alloc]initWithObjects:[numForm numberFromString:columns[3]], [numForm numberFromString:columns[10]], [numForm numberFromString:columns[11]], nil];
            [motionData addObject:accels];
        }
    }];
}


- (void) resetCount
{
    stepCount =0;
}

#pragma mark - FFT

- (void) init_FFT
{
    // Set up a data structure with pre-calculated values for
    // doing a very fast FFT. The structure is opaque, but presumably
    // includes sin/cos twiddle factors, and a lookup table for converting
    // to/from bit-reversed ordering. Normally you'd create this once
    // in your application, then use it for many (hundreds! thousands!) of
    // forward and inverse FFTs.

    fftSetup = vDSP_create_fftsetupD(LOG_N, kFFTRadix2);
    
    // -------------------------------
    // Set up a bunch of buffers
    
    // Buffers for real (time-domain) input and output signals.
    y = (double *)malloc(sizeof(double) * N);
    z = (double *)malloc(sizeof(double) * N);
    y_recon = (double *)malloc(sizeof(double) * N);
    
    tempSplitComplexY.realp = (double *)malloc(sizeof(double) * (N/2));
    tempSplitComplexY.imagp = (double *)malloc(sizeof(double) * (N/2));
    tempSplitComplexZ.realp = (double *)malloc(sizeof(double) * (N/2));
    tempSplitComplexZ.imagp = (double *)malloc(sizeof(double) * (N/2));
    splitComplexRecon.realp = (double *)malloc(sizeof(double) * (N/2));
    splitComplexRecon.imagp = (double *)malloc(sizeof(double) * (N/2));
}

- (void) do_analysis
{
    // ----------------------------------------------------------------
    // Forward FFT
    
    // Scramble-pack the real data into complex buffer in just the way that's
    // required by the real-to-complex FFT function that follows.
    int sidx = (((samplecount - (N - 1)) + MAXSAMPLES) % MAXSAMPLES);

    // for some reason there was an issue with the original memcpy scheme - use the raw loop for the time-being.
    for (int i = 0; i < N; i++)
    {
        int idx = ((sidx + i) + MAXSAMPLES ) % MAXSAMPLES;
        y[i] = samples[1][idx];
        z[i] = samples[2][idx];
    }
    
    vDSP_ctozD((DSPDoubleComplex*)y, 2, &tempSplitComplexY, 1, N/2);
    vDSP_ctozD((DSPDoubleComplex*)z, 2, &tempSplitComplexZ, 1, N/2);

    // Do real->complex forward FFT
    vDSP_fft_zripD(fftSetup, &tempSplitComplexY, 1, LOG_N, kFFTDirection_Forward);
    vDSP_fft_zripD(fftSetup, &tempSplitComplexZ, 1, LOG_N, kFFTDirection_Forward);

    double forward_scale = 1.0/2.0;
    vDSP_vsmulD(tempSplitComplexY.realp, 1, &forward_scale, tempSplitComplexY.realp, 1, N/2);
    vDSP_vsmulD(tempSplitComplexY.imagp, 1, &forward_scale, tempSplitComplexY.imagp, 1, N/2);
    vDSP_vsmulD(tempSplitComplexZ.realp, 1, &forward_scale, tempSplitComplexZ.realp, 1, N/2);
    vDSP_vsmulD(tempSplitComplexZ.imagp, 1, &forward_scale, tempSplitComplexZ.imagp, 1, N/2);

    // copy key low frequencies from fft, zero out the rest
    // copy [0] to include DC and nyquist.
    
    for (int i = 0; i < (N/2); i++)
    {
        if (i <= num_frequencies_ifft_keep)
        {
            splitComplexRecon.realp[i] = tempSplitComplexY.realp[i];
            splitComplexRecon.imagp[i] = tempSplitComplexY.imagp[i];
        }
        else
        {
            splitComplexRecon.realp[i] = 0.0;
            splitComplexRecon.imagp[i] = 0.0;
        }
    }
    
    vDSP_fft_zripD(fftSetup, &splitComplexRecon, 1, LOG_N, kFFTDirection_Inverse);
    
    double inv_scale = 1.0 / (N);
    vDSP_vsmulD(splitComplexRecon.realp, 1, &inv_scale, splitComplexRecon.realp, 1, N/2);
    vDSP_vsmulD(splitComplexRecon.imagp, 1, &inv_scale, splitComplexRecon.imagp, 1, N/2);
    
    vDSP_ztocD(&splitComplexRecon, 1, (DSPDoubleComplex*)y_recon, 2, N/2);
    
    // grab "most recent" value from reconstruction and add it to ongoing trace
    lpf[0][samplecount] = y_recon[N-1]; // set up for step counting - hijack lpf[0] since not being used currently
    
    // Calculate frequency function to threshold for results analysis
    double magnitude_y[2];
    double magnitude_z[2];
    magnitude_y[0] = sqrt((tempSplitComplexY.realp[1]*tempSplitComplexY.realp[1]) +
                          (tempSplitComplexY.imagp[1]*tempSplitComplexY.imagp[1]));
    magnitude_y[1] = sqrt((tempSplitComplexY.realp[2]*tempSplitComplexY.realp[2]) +
                          (tempSplitComplexY.imagp[2]*tempSplitComplexY.imagp[2]));
    magnitude_z[0] = sqrt((tempSplitComplexZ.realp[1]*tempSplitComplexZ.realp[1]) +
                          (tempSplitComplexZ.imagp[1]*tempSplitComplexZ.imagp[1]));
    magnitude_z[1] = sqrt((tempSplitComplexZ.realp[2]*tempSplitComplexZ.realp[2]) +
                          (tempSplitComplexZ.imagp[2]*tempSplitComplexZ.imagp[2]));
    double analyze_y = (magnitude_y[0] + magnitude_y[1])/2.0;
    double analyze_z = (magnitude_z[0] + magnitude_z[1])/2.0;
    
    // Populate "result" arrays used for walking state detection
    int start_step_idx = (((samplecount - (step_size - 1)) + MAXSAMPLES) % MAXSAMPLES);
    int start_window_idx = (((samplecount - (window_size - 1)) + MAXSAMPLES) % MAXSAMPLES);

    for (int i = 0; i < step_size; i++)
    {
        int idx = ((start_step_idx + i) + MAXSAMPLES ) % MAXSAMPLES;
        result_y[idx] = analyze_y;
        result_z[idx] = analyze_z;
    }
    
    // Default to false until proven otherwise
    bool current_walking_state = NO;

    // Calculate if walking in the current window and assign to temporary (suspected walking)
    bool walking_now = NO;

    int result_y_count = 0;
    int result_z_count = 0;
    
    for (int i = window_size/2; i < window_size; i++)
    {
        int idx = ((start_window_idx + i) + MAXSAMPLES ) % MAXSAMPLES;
        if (result_y[idx] > sustained_threshold_y)
        {
            result_y_count++;
        }
        if (result_z[idx] > sustained_threshold_z)
        {
            result_z_count++;
        }
    }
    
    if ((result_y_count > sustained_count) && (result_z_count > sustained_count))
    {
        walking_now = YES;
    }
    
    for (int i = 0; i < step_size; i++)
    {
        int idx = ((start_step_idx + i) + MAXSAMPLES ) % MAXSAMPLES;
        walking_temp[idx] = walking_now;
    }
    
    // Filter the walking flag to ensure short bursts don't trigger false positives
    if (walking_now)
    {
        NSUInteger walking_idx_count = 0;
        
        for (int i = window_size/2; i < window_size; i++)
        {
            int idx = ((start_window_idx + i) + MAXSAMPLES ) % MAXSAMPLES;
            if (walking_temp[idx])
            {
                walking_idx_count++;
            }
        }
        
        if (walking_idx_count == window_size/2)
        {
            for (int i = 0; i < window_size; i++)
            {
                int idx = ((start_window_idx + i) + MAXSAMPLES ) % MAXSAMPLES;
                walking[idx] = walking_now;
            }
            current_walking_state = YES;
        }
    }
    
    // If not walking, be sure to zero out walking vector for this window
    if (!current_walking_state)
    {
        for (int i = 0; i < window_size; i++)
        {
            int idx = ((start_window_idx + i) + MAXSAMPLES ) % MAXSAMPLES;
            walking[idx] = NO;
        }
    }
    
    if (current_walking_state == YES && previous_walking_state == NO)
    {
        walkDir direction = UNKNOWN;
        
        double start_time = start_time_of_current_window - window_size*delta_t;
        NSLog(@"Walking started in window beginning at time %f", start_time);
        
        // Started walking
        
        // Detect direction
        int pos_count = 0;
        int neg_count = 0;
        
        int direction_window_start = (((samplecount - direction_window_width - (N - 1)) + MAXSAMPLES) % MAXSAMPLES);
        for (int i = 0; i < direction_window_width; i++)
        {
            int idx = ((direction_window_start + i) + MAXSAMPLES ) % MAXSAMPLES;
            if (samples[2][idx] > 0) pos_count++;
            else if (samples[2][idx] < 0) neg_count++;
        }
        
        if (neg_count > pos_count)
        {
            direction = BACKWARDS;
        }
        else if (pos_count > neg_count)
        {
            direction = FORWARDS;
        }

        [self turnWalkingOn:direction];
    }

    // Perform time-domain analysis on filtered signal for step-counting
    
    double masked_y_accel[N];
    for (int i = 0; i < window_size; i++)
    {
        int idx = ((start_window_idx + i) + MAXSAMPLES ) % MAXSAMPLES;
        masked_y_accel[i] = y_recon[i] * walking[idx];
    }
    
    [self windowedStepDetection:masked_y_accel withNumElems:N];
    
    if (current_walking_state == NO && previous_walking_state == YES)
    {
        double end_time = start_time_of_current_window + step_size*delta_t;
        NSLog(@"Walking stopped in window ending at time %f", end_time);

        if (global_step_counter > floor(global_step_counter))
        {
            // We have a half-step in progress. Close it out.
            global_step_counter = ceil(global_step_counter);
            [self didTakeStep];
        }
        [self turnWalkingOff];
    }
    
    previous_walking_state = current_walking_state;

#ifdef PED_APP
    // dump out logs and data traces
    
    NSString *fftLogStr = [NSString stringWithFormat:@"%d,%f,%f,%f,%f,",
                                        loopcount,
                                        samples[1][samplecount],
                                        samples[2][samplecount],
                                        lpf[1][samplecount],
                                        lpf[2][samplecount]
                                        ];

    for (int k = 1; k < N/2; k++)
    {
        if (k <= (N >> 2))
        {
            // add y & z real component
            fftLogStr = [fftLogStr stringByAppendingFormat:@"%f,%f,", magnitudeY[k], magnitudeZ[k]];
        }
        
        if ((k == HI_FREQ_HIGH) || (k == HI_FREQ_LOW))
        [viewcontroller.motionGraph addX:5.0 y:-3.0 z:-3.0];
        
        [viewcontroller.motionGraph addX:-3.0 y:(magnitudeY[k]) - 3.0 z:(magnitudeZ[k]) - 3.0];
    }
    [viewcontroller.motionGraph addX:5.0 y:-3.0 z:-3.0];
    
    for (int k = 1; k < N/2; k++)
    {
        if (k <= (N >> 2))
        {
            // add y & z real component
            fftLogStr = [fftLogStr stringByAppendingFormat:@"%f,%f", fabs(tempSplitComplexY.realp[k]), fabs(tempSplitComplexZ.realp[k])];
            
            if (k < (N >> 2))
            {
                // add comma
                fftLogStr = [fftLogStr stringByAppendingString:@","];
            }
            else
            {
                // add CR
                fftLogStr = [fftLogStr stringByAppendingString:@"\n"];
            }
        }
        
        if ((k == HI_FREQ_HIGH) || (k == HI_FREQ_LOW))
            [viewcontroller.motionGraph addX:5.0 y:-3.0 z:-3.0];
        
        [viewcontroller.motionGraph addX:-3.0 y:fabs(tempSplitComplexY.realp[k]) - 3.0 z:fabs(tempSplitComplexZ.realp[k]) - 3.0];
    }
    [self writeFftLog:fftLogStr];

    
    logStr = [NSString stringWithFormat:@"%d,%f,%f,%f,%f,%f,%f,",
                loopcount,
                samples[1][samplecount],
                samples[2][samplecount],
                lpf[1][samplecount],
                lpf[2][samplecount],
                analyze_y,
                analyze_z
              ];

    
#endif

}

@end


