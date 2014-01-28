//
//  FluxKalmanFilter.h
//  Flux
//
//  Created by Arjun Chopra on 11/5/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluxKalmanFilter : NSObject{
    double *X; //state
    double *F; //state transition matrix
    double *u; //motion vector
    double *P; //uncertainity covariance
    double *X_p;
    double *P_p;
    double *X_pp;
    double *P_pp;

    double *Z; //measurement
    double *H; //measurement function
    double *Q; //measurement noise
    double *I; //Identity matrix

    double *y;
    double *S;
    double *K;
    double *Sinv;

    double *T44;
    double *T21;
    double *T24;
    double *T22;
    double *T42;
    double *T41;
    
// matrix inversion variables, allocating them once to save malloc/free calls
    long *ipiv;
    double *work;
}

@property (readonly) double positionX;
@property (readonly) double positionY;
-(void) predictWithXDisp:(double)xdisp YDisp:(double)ydisp dT:(double) dt;
-(void) measurementUpdateWithZX:(double)zx ZY:(double)zy Rx:(double)rx Ry:(double)ry;
-(void) resetKalmanFilter;
@end
