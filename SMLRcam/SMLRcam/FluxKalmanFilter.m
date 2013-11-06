//
//  FluxKalmanFilter.m
//  Flux
//
//  Created by Arjun Chopra on 10/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxKalmanFilter.h"
#import <Accelerate/Accelerate.h>

#define STATEV_SIZE 4
#define MEASUREMENTV_SIZE 2
@implementation FluxKalmanFilter


-(void)zeroMatWithMat:(double*)mat numElements:(int)nel
{
    int i;
    
    for(i =0;i<nel;i++)
    {
        mat[i] = 0.0;
    }
}

//set dt
-(void) testReinitialize
{
}

-(FluxKalmanFilter*) init
{
    
    //alloc
    X = malloc(STATEV_SIZE * sizeof(double));
    F = malloc(STATEV_SIZE * STATEV_SIZE * sizeof(double));
    u = malloc(STATEV_SIZE *sizeof(double));
    X_p = malloc(STATEV_SIZE * sizeof(double));
    P = malloc(STATEV_SIZE * STATEV_SIZE * sizeof(double));
    P_p = malloc(STATEV_SIZE * STATEV_SIZE * sizeof(double));
    X_pp = malloc(STATEV_SIZE * sizeof(double));
    P_pp = malloc(STATEV_SIZE * STATEV_SIZE * sizeof(double));
    
    Z = malloc(MEASUREMENTV_SIZE * sizeof(double));
    
    H = malloc(MEASUREMENTV_SIZE * STATEV_SIZE * sizeof(double));
    Q = malloc(STATEV_SIZE * STATEV_SIZE * sizeof(double));
    I = malloc(STATEV_SIZE * STATEV_SIZE * sizeof(double));
    
    y = malloc(MEASUREMENTV_SIZE * sizeof(double));
    S = malloc(MEASUREMENTV_SIZE * MEASUREMENTV_SIZE * sizeof (double));
    K = malloc(STATEV_SIZE * MEASUREMENTV_SIZE * sizeof(double));
    Sinv = malloc(MEASUREMENTV_SIZE * MEASUREMENTV_SIZE * sizeof (double));
    
    //T Variables
    T44 = malloc(4 * 4 * sizeof (double));
    T21 = malloc(2 * 1 * sizeof (double));
    T24 = malloc(2 * 4 * sizeof (double));
    T22 = malloc(2 * 2 * sizeof (double));
    T42 = malloc(4 * 2 * sizeof (double));
    T41 = malloc(4 * 1 * sizeof (double));
    
    //matrix inversion
    ipiv = malloc((MEASUREMENTV_SIZE +1) *sizeof (long));
    work = malloc(MEASUREMENTV_SIZE *MEASUREMENTV_SIZE *sizeof(double));
    
    
    //zero stuff
    [self zeroMatWithMat:X numElements:STATEV_SIZE];
    [self zeroMatWithMat:F numElements:STATEV_SIZE * STATEV_SIZE];
    [self zeroMatWithMat:u numElements:STATEV_SIZE];
    [self zeroMatWithMat:P numElements:STATEV_SIZE * STATEV_SIZE];
    [self zeroMatWithMat:X_p numElements:STATEV_SIZE];
    [self zeroMatWithMat:P_p numElements:STATEV_SIZE * STATEV_SIZE];
    [self zeroMatWithMat:X_pp numElements:STATEV_SIZE];
    [self zeroMatWithMat:P_pp numElements:STATEV_SIZE * STATEV_SIZE];
    
    [self zeroMatWithMat:Z numElements:MEASUREMENTV_SIZE];
    [self zeroMatWithMat:H numElements:MEASUREMENTV_SIZE * STATEV_SIZE];
    [self zeroMatWithMat:Q numElements:MEASUREMENTV_SIZE * MEASUREMENTV_SIZE];
    [self zeroMatWithMat:I numElements:STATEV_SIZE * STATEV_SIZE];
    
    [self zeroMatWithMat:y numElements:MEASUREMENTV_SIZE];
    [self zeroMatWithMat:S numElements:MEASUREMENTV_SIZE * MEASUREMENTV_SIZE];
    [self zeroMatWithMat:K numElements:STATEV_SIZE * MEASUREMENTV_SIZE];
    
    
    
    
    //initialize everything
    F[0] = F[5] =F[10]=F[15] = 1.0;
    F[2] =1.0;
    F[7] =1.0;
    I[0] = I[5] =I[10] =I[15] = 1.0;
    
    //uncertainity in noise????
    //tune
    
    P[0] = P[5] =5.0;
    P[10] = P[15] = 1000.0;
    H[0] = H[5] = 1.0;
    Q[0] = Q[3] = 10.0;
    
    [self testReinitialize];
    
    return self;
}

-(int) invertS
{
    long lWork = MEASUREMENTV_SIZE * MEASUREMENTV_SIZE;
    long info = -1;
    long n = MEASUREMENTV_SIZE;
    double temp;
    //row major to column major
    Sinv[0] = S[0];
    Sinv[1] = S[2];
    Sinv[2] = S[1];
    Sinv[3] = S[3];
    dgetrf_(&n, &n,Sinv, &n, ipiv, &info);
    dgetri_(&n, Sinv, &n, ipiv, work, &lWork,&info );
    
    //convert back to row major
    temp = Sinv[2];
    Sinv[1] = Sinv[2];
    Sinv[2] = temp;
    
    return info;
}


-(void) predictWithXDisp:(double)xdisp YDisp:(double)ydisp dT:(double) dt
{
    
    u[0] = xdisp;
    u[1] = ydisp;
    //log dt initially
    F[2] = F[7] = dt;
    //1
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 4, 1 , 4, 1.0, F, 4, X, 4, 1.0, X_p, 4);
    
    X_p[0] = X_p[0] + u[0];
    X_p[1] = X_p[1] + u[1];
    
    //2
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 4, 4 , 4, 1.0, F, 4, P, 4, 1.0, T44, 4);
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasTrans, 4, 4 , 4, 1.0, T44, 4, F, 4, 1.0, P_p, 4);
}


//-(void) measurementUpdate(double *gpsDisplacement, double*gpsPrecision, double* newPosition)

-(void) measurementUpdateWithZX:(double)zx ZY:(double)zy Rx:(double)rx Ry:(double)ry
{
    int invert=-1.0;
    //3
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 2, 1 , 4, 1.0, H, 2, X_p, 4, 1.0, T21, 2);
    
    y[0] = zx - T21[0];
    y[1] = zy - T21[1];
    
    //4
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 2, 4 , 4, 1.0, H, 2, P, 4, 1.0, T24, 2);
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasTrans, 2, 2 , 4, 1.0, T24, 2, H, 4, 1.0, T22, 2);
    
    S[0] = T22[0] + Q[0];
    S[1] = T22[1] + Q[1];
    S[2] = T22[2] + Q[2];
    S[3] = T22[3] + Q[3];
    //5
    invert = [self invertS];
    if(invert !=0)
    {
        NSLog(@"KalmanFilter: Matrix inversion failed! Handle this!!");
        return;
    }
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasTrans, 4, 2 , 4, 1.0, P, 4, H, 4, 1.0, T42, 4);
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 4, 2 , 2, 1.0, T42, 4, Sinv, 2, 1.0, K, 4);
    
    //6
    
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 4, 1 , 2, 1.0, K, 4, y, 2, 1.0, T41, 4);
    X[0] = X_p[0] + T41[0];
    X[1] = X_p[1] + T41[1];
    X[2] = X_p[2] + T41[2];
    X[3] = X_p[3] + T41[3];
    //7
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 4, 4 , 2, 1.0, K, 4, H, 2, -1.0, T44, 4);
    cblas_daxpy(16, 1.0,I, 1, T44,1 );
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 4, 4 , 4, 1.0, T44, 4, P, 4, 1.0, P_pp, 4);
    cblas_dcopy(16, P_pp, 1, P, 1);
    NSLog(@"X[%f %f %f %f",X[0],X[1],X[2],X[3]);
}

@end
