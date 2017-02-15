#include "mex.h"

//
//  For compiling instructions, see big_plot.compile()
//


//Status
//-----------
//1) Parallel min and max across threads
//2) Starts at an arbitrary index into the data (for processing subsets)
//
//TODO
//-----------
//3) Merge min and max into one output (for plotting)
//4) Allow padding with the first and last values of the data 
//  so that the auto axes limits doesn't cause problems
//5) Implement the min/max avx instructions - _mm256_min/max_pd
    

/*
//TODO: Degenerate cases:

data = ones(1,4);

data = ones(0,4);

%chunk size of 1

%dimensions of data not being 2 ...

% min and max over a subset;
%-----------------------------------------
data = reshape(1:40,10,4);
for iStart = 1:10
    min_max_data = reduce_to_width_mex(data,5,iStart,10);
end

%SPEED TEST
%-------------------------------------------------------------------------
n_channels = 3; %I varied this to confirm that the parallelization works on
%different levels than the # of cores
data = [1 2 3 4 7    1 8 1 8 9   2 9 8 3 9    2 4 5 6 2    9 3 4 8 9    3 9 4 2 3   4 9 0 2 9]';
%data = repmat(data,[1 n_channels]);
samples_per_chunk = 1000;
%reduced from 5e6 due to memory issues on laptop
data = repmat(data,[5e6 n_channels]);
data(999,1:n_channels) = 1000:(1000+n_channels-1);
data(998:1000,1:n_channels) = 1000;
data(23,1:n_channels) = -1:-1:-1*n_channels;
len_data_p1 = size(data,1)+1;
 N = 20;
 tic
 for i = 1:N
 min_max_data = reduce_to_width_mex(data,samples_per_chunk);
 end
 t1 = toc/N
 
 tic
 for i = 1:N
 [min_data2,I] = min(reshape(data,[samples_per_chunk size(data,1)/samples_per_chunk n_channels]),[],1);
 [max_data,I] = max(reshape(data,[samples_per_chunk size(data,1)/samples_per_chunk n_channels]),[],1);
 end
 t2 = toc/N
 pct_time = t1/t2;
 
 fprintf('mine/theirs = %0.3f\n',pct_time);
 //This fails for 1 channel due to squeeze behavior
 //TODO: min and max have been merged, so this no longer works ...
 fprintf('Same min answers: %d\n',isequal(min_data,squeeze(min_data2)));
 %------------------------------------------------------------------------
*/

mwSize getScalarInput(const mxArray *rhs){
    //
    //
    //  TODO: Validate type
    
    double *temp = (double *)mxGetData(rhs);
    return (mwSize) *temp;
    
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    //
    //  Calling Form
    //  ------------
    //  min_max_data = reduce_to_width_mex(data,samples_per_chunk,*start_sample,*end_sample);
    //
    //  Inputs
    //  ------
    //  data : [samples x channels]
    //  samples_per_chunk : #
    //   
    //  Optional Inputs
    //  -------
    //  start_sample: #, 1 based
    //      If specified, the end sample must also be specified
    //  end_sample: #, 1 based
    //
    
    if (!(nrhs == 2 || nrhs == 4)){
        mexErrMsgIdAndTxt("SL:reduce_to_width:n_inputs","Invalid # of inputs, 2 or 4 expected");
    }else if (!mxIsClass(prhs[0],"double")){
        mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type","First input type needs to be double");
    }else if (!mxIsClass(prhs[1],"double")){
        mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type","Second input type needs to be double");
    }
    
    if (nrhs == 4){
        if (!mxIsClass(prhs[2],"double")){
            mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type","Third input type needs to be double");
        }else if (!mxIsClass(prhs[3],"double")){
            mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type","Fourth input type needs to be double");
        }  
    }
    //This will change when we merge the results
    if (!(nlhs == 1)){
        mexErrMsgIdAndTxt("jsmn_mex:n_inputs","Invalid # of outputs, 1 expected");
    }

    double *p_data_absolute = (double *)mxGetData(prhs[0]);
    double *p_start_data = (double *)mxGetData(prhs[0]);

    //This is used to adjust the data pointer for each column
    //It can't change ...
    mwSize n_samples_data = mxGetM(prhs[0]);
    
    //This is used to indicate how many samples we need to examine
    //for min and max values
    mwSize n_samples_process = n_samples_data;
    mwSize n_chans = mxGetN(prhs[0]);
    
    mwSize samples_per_chunk = getScalarInput(prhs[1]);
    if (nrhs == 4){
        mwSize start_index = getScalarInput(prhs[2]) - 1; //make 0 based
        mwSize stop_index  = getScalarInput(prhs[3]) - 1;
        
        mwSize max_valid_index = n_samples_data - 1;
        
        if (start_index < 0 || start_index > max_valid_index){
            mexErrMsgIdAndTxt("SL:reduce_to_width:start_index","Start index is out of range");
        }else if (stop_index < 0 || stop_index > max_valid_index){
            mexErrMsgIdAndTxt("SL:reduce_to_width:stop_index","Stop index is out of range");
        }else if (stop_index < start_index){
            mexErrMsgIdAndTxt("SL:reduce_to_width:stop_before_start","Start index comes after stop index");
        }
        
        p_start_data = p_start_data + start_index;
        n_samples_process = stop_index - start_index + 1;
    }
    
    bool pad_with_endpoints = n_samples_process != n_samples_data;
    //Integer division, should floor as desired
    mwSize n_chunks = n_samples_process/samples_per_chunk;
    mwSize n_samples_extra = n_samples_process - n_chunks*samples_per_chunk;
    
    //We are going to store min and max together
    mwSize n_outputs = 2*n_chunks;
    
    if (n_samples_extra){
        n_outputs+=2; //Add on one extra when things don't evenly divide
    }
    
    //Note, we might get some replication with the first and last
    //data points if only one of those is cropped
    if (pad_with_endpoints){
        n_outputs+=2;
        //Need to move one past
    }
    
    double *p_output_data = (double *)mxMalloc(8*n_chans*n_outputs);
    double *p_output_data_absolute = p_output_data;
    
    //TODO: I don't think this is used
    mwSize pad_offset = pad_with_endpoints ? 1:0;
    
    //Initialize the first and last values of the output
    //---------------------------------------------------------------------
    //We keep the first and last values if we are not plotting everything
    //We need to loop through each channel and assign:
    //  1) The first data point in each channel to the first output value
    //  2) The last data point in each channel to the last output value
    if (pad_with_endpoints){
        double *pad_output_data = p_output_data;
        double *current_data_point = p_data_absolute;
        for (mwSize iChan = 0; iChan < n_chans; iChan++){
            
            //Storage of first data point
            *pad_output_data = *current_data_point;
            
            
            pad_output_data += (n_outputs-1);
            current_data_point += (n_samples_data-1);
            
            //Storage of last data point
            *pad_output_data = *current_data_point;
            
            //Roll over to the next channel
            ++current_data_point;
            ++pad_output_data;
        }
        
        //Move beyond the first padded data point
        //TODO: Better variable naming may help here
        //When looping over the outputs, we want to start by asssigning
        //data to the 2nd output, since the first has now already been
        //populated
        ++p_output_data;
    }
    

    #pragma omp parallel for simd collapse(2)
    for (mwSize iChan = 0; iChan < n_chans; iChan++){
        //Note, we can't initialize anything before this loop, since we
        //are collapsing the first two loops. This allows us to parallelize
        //both of the first two loops, which is good when the # of channels
        //does not equal the # of threads.
        for (mwSize iChunk = 0; iChunk < n_chunks; iChunk++){
            
            double *current_data_point = p_start_data + n_samples_data*iChan + iChunk*samples_per_chunk;
            
            //Pointer => start + column wrapping + offset (row into column) - 1
            //*2 since we store min and max in each chunk
            double *local_output_data = p_output_data + n_outputs*iChan + 2*iChunk;

            double min = *current_data_point;
            double max = *current_data_point;
            
            //We might get some speedup by looking for a slow trend
            //over the data and adjusting the order that we look
            //at the values accordingly
            
            //This is the slow part :/
            for (mwSize iSample = 1; iSample < samples_per_chunk; iSample++){
                if (*(++current_data_point) > max){
                    max = *current_data_point;
                }else if (*current_data_point < min){
                    min = *current_data_point;
                }
            }

            *local_output_data = min;
            *(++local_output_data) = max;            
        }
    }
    
    if (n_samples_extra){
        #pragma omp parallel for simd
        for (mwSize iChan = 0; iChan < n_chans; iChan++){
            
            double *current_data_point = p_start_data + n_samples_data*iChan + n_chunks*samples_per_chunk;
            
            double *local_output_data = p_output_data + n_outputs*iChan + 2*n_chunks;
            
            double min = *current_data_point;
            double max = *current_data_point;
            
            for (mwSize iSample = 1; iSample < n_samples_extra; iSample++){
                if (*(++current_data_point) > max){
                    max = *current_data_point;
                }else if (*current_data_point < min){
                    min = *current_data_point;
                }
            }
            *local_output_data = min;
            *(++local_output_data) = max;
        }
    }
    
    plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
    
    mxSetData(plhs[0],p_output_data_absolute);
    mxSetM(plhs[0],n_outputs);
    mxSetN(plhs[0],n_chans);

}