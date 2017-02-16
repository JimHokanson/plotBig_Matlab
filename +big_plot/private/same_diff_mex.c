#include "mex.h"
#include <math.h> 
#include "float.h"

//  d = linspace(0,100,1e7);
//  tic; wtf = same_diff(d); toc;    

//  Compile via:
//  mex same_diff_mex.c

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    //
    //      Usage
    //      -----
    //      flag = same_diff(data,tolerance_multiplier)
    //
    //      - data is assumed to be 1d (this could be verified ...)
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
    //      1) parallel
    //      2) simd
    
    double tolerance_multiplier = 0.00001;
    
    if (nrhs == 2){
        if (!mxIsClass(prhs[1],"double")){
            mexErrMsgIdAndTxt("SL:same_diff:call_error","The 2nd input must be a double");
        }
        tolerance_multiplier = mxGetScalar(prhs[1]);
    }else if (nrhs != 1){
        mexErrMsgIdAndTxt("SL:same_diff:call_error","Invalid # of inputs, 1 or 2 expected");
    }
    
    if (!mxIsClass(prhs[0],"double")){
        mexErrMsgIdAndTxt("SL:same_diff:call_error","The input array must be of type double");
    }    
    
    if (!(nlhs == 1)){
        mexErrMsgIdAndTxt("SL:same_diff:n_inputs","Invalid # of outputs, 1 expected");
    }

    mwSize n_samples_data = mxGetNumberOfElements(prhs[0]);
    
    plhs[0] = mxCreateLogicalMatrix(1,1);
    mxLogical *pl = mxGetLogicals(plhs[0]);
    
    *pl = true;
    if (n_samples_data < 3){
        return;
    }
    
    double *data = mxGetData(prhs[0]);
    double *p_start = data;
    
    double last_sample    = *data;
    double current_sample = *(++data);
    double current_diff   = current_sample - last_sample;
    double last_diff      = current_diff;
    
    double MAX_DIFF = tolerance_multiplier*fabs(last_diff);
     
    //sentinel block - don't need to worry about running past the end
    //since the last value will always be false
    double end_array_value = *(p_start+n_samples_data-1);
    *(p_start+n_samples_data-1) = mxGetNaN();

    //Newer code, not clear that it is that much faster
    //-------------------------------------------------
    while (fabs(current_diff - last_diff) < MAX_DIFF){
        last_diff      = current_diff;
        last_sample    = current_sample;
        current_sample = *(++data);
        current_diff   = current_sample - last_sample; 
    }
    
    //Reset terminal value
    *(p_start+n_samples_data-1) = end_array_value;
    
    if (data == p_start+n_samples_data-1){
        current_diff = end_array_value - last_sample;
        *pl = (fabs(current_diff - last_diff) < MAX_DIFF);
    }else{
        *pl = false;
    }
    
}