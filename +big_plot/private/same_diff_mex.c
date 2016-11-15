#include "mex.h"
#include <math.h> 
#include "float.h"

//  d = linspace(0,100,1e7);
//  tic; wtf = same_diff(d); toc;    

//
//  mex same_diff_mex.c
//
//  http://www.mathworks.com/matlabcentral/answers/303782-is-xcode-8-compatible-with-matlab

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    //
    //      flag = same_diff(data,tolerance)
    //
    //      - data is assumed to be 1d
    //
    //      Computes whether or not all differences are the same
    //      as the first difference
    //
    //      all(diff(diffs) < 0.00001*diffs(1))
    //
    //      This function was written to verify evenly sampled time data.
    //  
    //      Improvements
    //      ------------
    //      1) Implement a sentinel value - temporarily change
    //      last value to be true, so we can remove loop check ...
    //      2) SIMD
    
    //TODO: Need to do checks for double type data ...
    if (!(nrhs == 1)){
        mexErrMsgIdAndTxt("SL:same_diff:n_inputs","Invalid # of inputs, 1 expected");
    }
    
    //This will change when we merge the results
    if (!(nlhs == 1)){
        mexErrMsgIdAndTxt("SL:same_diff:n_inputs","Invalid # of outputs, 1 expected");
    }

    double *data = mxGetData(prhs[0]);
    mwSize n_samples_data = mxGetNumberOfElements(prhs[0]);
    
    plhs[0] = mxCreateLogicalMatrix(1,1);
    mxLogical *pl = mxGetLogicals(plhs[0]);
    
    *pl = true;
    if (n_samples_data < 3){
        return;
    }
    
    double last_sample    = *data;
    double current_sample = *(++data);
    double last_diff      = current_sample - last_sample;
    double current_diff;
    
    //double MAX_DIFF = 2*DBL_EPSILON;
    double MAX_DIFF = 0.0001*fabs(last_diff);
        
    for (mwSize iSample = 2; iSample < n_samples_data; iSample++){
        last_sample    = current_sample;
        current_sample = *(++data);
        current_diff   = current_sample - last_sample;
                
        if (fabs(current_diff - last_diff) > MAX_DIFF){
            *pl = false;
            return;
        }
        last_diff = current_diff;
    }
}