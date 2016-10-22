#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    //
    // flag = same_diff(data,tolerance)
    
    if (!(nrhs == 2){
        mexErrMsgIdAndTxt("SL:same_diff:n_inputs","Invalid # of inputs, 2 expected");
    }
    
    //This will change when we merge the results
    if (!(nlhs == 1)){
        mexErrMsgIdAndTxt("SL:same_diff:n_inputs","Invalid # of outputs, 1 expected");
    }

    
    
    double *data = mxGetData(prhs[0]);
    double *tolerance = mxGetData(prhs[0]);
    
    double *p_data_absolute = mxGetData(prhs[0]);
    double *p_start_data = mxGetData(prhs[0]);
    
    for (mwSize iSample = 0; iChan < n_chans; iChan++){
        //Note, we can't initialize anything before this loop, since we
        //are collapsing the first two loops. This allows us to parallelize
        //both of the first two loops, which is good when the # of channels
        //does not equal the # of threads.
        for (mwSize iChunk = 0; iChunk < n_chunks; iChunk++){
            
            }
            
            }
    
    }
}