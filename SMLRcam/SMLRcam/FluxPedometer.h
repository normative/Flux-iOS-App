//
//  FluxPedometer.h
//  Flux
//
//  Created by Denis Delorme on 10/18/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#include <Accelerate/Accelerate.h>
#import "FluxLocationServicesSingleton.h"
#define MAXSAMPLES  512

extern NSString* const FluxPedometerDidTakeStep;
extern NSString* const FluxPedometerDidTakeStepCountKey;

typedef enum _walkdir {
    BACKWARDS = -1,
    UNKNOWN = 0,
    FORWARDS = 1
} walkDir;

@class FluxMotionManagerSingleton;
@class FluxLocationServicesSingleton;

@interface FluxPedometer : NSObject<CLLocationManagerDelegate>
{
    NSTimer* motionUpdateTimer;
    FluxLocationServicesSingleton *flocation;
    int loopcount;
    bool readyToProcessMotion;
    
    int stepCount;
    BOOL isWalking;
    walkDir walkingDirection;
    
    double samples[3][MAXSAMPLES];
    int samplecount;
    double lpf[3][MAXSAMPLES];
    double delta[3][MAXSAMPLES];
    
    double result_y[MAXSAMPLES];
    double result_z[MAXSAMPLES];
    bool walking_temp[MAXSAMPLES];
    bool walking[MAXSAMPLES];
    
    NSDateFormatter *dateFormat;
    
    NSString *motionFilename;
    NSFileHandle *motionFile;
    NSFileHandle *fftFile;
    NSFileHandle *walkFile;
    
    NSMutableArray *motionData;
    int nextDataIdx;
    
    bool firstStep;
    
    // FFT support:
    DSPDoubleSplitComplex tempSplitComplexY, tempSplitComplexZ, splitComplexRecon;
    FFTSetupD fftSetup;
    double *y, *z, *y_recon;

    double magnitudeY[64];
    double magnitudeZ[64];
    
    NSString *logStr;
    
    // Basic window size parameters
    
    int window_size;        // Size of moving window over which analysis is conducted
    int step_size;          // Number of sample points window is advanced forward each period
    double delta_t;         // Time period sample acquisition
    
    // Sustained threshold filter parameters (frequency domain)
    
    double sustained_threshold_y;   // Threshold of comparison on "result function" for y
    double sustained_threshold_z;   // Threshold of comparison on "result function" for z
    // Number of "result function" samples exceeding above threshold in last half of window
    int sustained_count;
    
    // Filter parameters (frequency to time conversion)
    
    int num_frequencies_ifft_keep;
    
    // Acceleration-based step detection parameters (time domain)
    
    double accel_y_step_threshold_pos;  // Minimum positive acceleration threshold for step
    double accel_y_step_threshold_neg;  // Minimum negative acceleration threshold for step
    double accel_y_step_max_threshold_pos;  // Maximum positive acceleration threshold for step
    double accel_y_step_max_threshold_neg;  // Maximum negative acceleration threshold for step
    double peak_valley_time_tolerance;  // Time delta surrounding detected extrema to establish uniqueness
    double min_peak_to_valley_time;     // Minimum time between extrema for valid step
    double max_peak_to_valley_time;     // Maximum time between extrema for valid step
    int direction_window_width;         // Number of samples before current window to use for direction detection
    
    // Peak/Valley state variables
    // (these can be pruned as values age)
    NSMutableArray *global_peak_times;      // Stores time (in s since start) of each peak
    NSMutableArray *global_valley_times;    // Stores time (in s since start) of each valley
    NSMutableArray *global_blacklist_times; // Stores time (in s since start) of blacklisted periods (exceeds accel threshold)
    
    bool previous_walking_state;
    
    double global_step_counter;
    
    double start_time_of_current_window;
}

@property (nonatomic, setter = setIsPaused:) bool isPaused;

- (void) startPedometer;
- (void) stopPedometer;
- (void) processMotion:(CMDeviceMotion *)devMotion;
- (void) resetCount;

@end
