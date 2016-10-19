#include "mex.h"
#include <immintrin.h>
//
//  setenv('MW_MINGW64_LOC','C:\TDM-GCC-64')
//
//  mex -O LDFLAGS="$LDFLAGS -fopenmp"  CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx"  reduce_to_width_mex.c  
//
/*
    //Compiling on my mac
    //requires gcc setup, see turtle-json compiling notes
    //TODO: Move a copy of those notes here ...
    mex CC='/usr/local/Cellar/gcc6/6.1.0/bin/gcc-6' CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx" LDFLAGS="$LDFLAGS -fopenmp" COPTIMFLAGS="-O3 -DNDEBUG" -O reduce_to_width_mex.c  
 */

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
n_channels = 1; %I varied this to confirm that the parallelization works on
%different levels than the # of cores
data = [1 2 3 4 7    1 8 1 8 9   2 9 8 3 9    2 4 5 6 2    9 3 4 8 9    3 9 4 2 3   4 9 0 2 9]';
%data = repmat(data,[1 n_channels]);
samples_per_chunk = 5;
%reduced from 5e6 due to memory issues on laptop
data = repmat(data,[1000000 n_channels]);
data(23,1:n_channels) = -1:-1:-1*n_channels;
len_data_p1 = size(data,1)+1;
 N = 10;
 tic
 for i = 1:N
 min_max_data = reduce_to_width_mex(data,samples_per_chunk);
 %[min_data,max_data] = sl.plot.reduce_to_width_mex(data,samples_per_chunk);
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
    
    double *temp = mxGetData(rhs);
    return (mwSize) *temp;
    
}

void min_max_32(double *data, __m256d *min4, __m256d *max4){
    
    __m256d d9, d10, d11, d12, d13, d14, d15, d16;
    __m256d d1 = _mm256_loadu_pd(&data[0]);
    __m256d d2 = _mm256_loadu_pd(&data[4]);
    __m256d d3 = _mm256_loadu_pd(&data[8]);
    __m256d d4 = _mm256_loadu_pd(&data[12]);
    __m256d d5 = _mm256_loadu_pd(&data[16]);
    __m256d d6 = _mm256_loadu_pd(&data[20]);
    __m256d d7 = _mm256_loadu_pd(&data[24]);
    __m256d d8 = _mm256_loadu_pd(&data[28]);    

    d9  = _mm256_max_pd(d1,d2);
    d10 = _mm256_min_pd(d1,d2);
    d11 = _mm256_max_pd(d3,d4);
    d12 = _mm256_min_pd(d3,d4);
    d13 = _mm256_max_pd(d5,d6);
    d14 = _mm256_min_pd(d5,d6);
    d15 = _mm256_max_pd(d7,d8);
    d16 = _mm256_min_pd(d7,d8);
    
    d9 = _mm256_max_pd(d9,d11);
    d13 = _mm256_max_pd(d13,d15);
    d10 = _mm256_min_pd(d10,d12);
    d14 = _mm256_min_pd(d14,d16);
    
    *max4 = _mm256_max_pd(d9,d13);
    *min4 = _mm256_min_pd(d10,d14);
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
    }
    
    //This will change when we merge the results
    if (!(nlhs == 1)){
        mexErrMsgIdAndTxt("jsmn_mex:n_inputs","Invalid # of outputs, 1 expected");
    }

    double *p_data_absolute = mxGetData(prhs[0]);
    double *p_start_data = mxGetData(prhs[0]);

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
    
//     mexPrintf("n_samples_process: %d\n",n_samples_process);
//     mexPrintf("n_samples_data: %d\n",n_samples_data);
//     mexPrintf("n_outputs: %d\n",n_outputs);
//     mexPrintf("n_samples_extra: %d\n",n_samples_extra);
    
    //TODO: Let's merge these
    double *p_output_data = mxMalloc(8*n_chans*n_outputs);
    double *p_output_data_absolute = p_output_data;
    
    mwSize pad_offset = pad_with_endpoints ? 1:0;
    if (pad_with_endpoints){
        double *pad_output_data = p_output_data;
        double *current_data_point = p_data_absolute;
        for (mwSize iChan = 0; iChan < n_chans; iChan++){
            *pad_output_data = *current_data_point;
            pad_output_data += (n_outputs-1);
            current_data_point += (n_samples_data-1);
            *pad_output_data = *current_data_point;
            ++current_data_point;
            ++pad_output_data;
        }
        //Move beyond the first padded data ooint
        ++p_output_data;
    }

    #pragma omp parallel for simd collapse(2)
    for (mwSize iChan = 0; iChan < n_chans; iChan++){
        for (mwSize iChunk = 0; iChunk < n_chunks; iChunk++){
            
            double *current_data_point = p_start_data + n_samples_data*iChan + iChunk*samples_per_chunk;
            
            //Pointer => start + column wrapping + offset (row into column) - 1
            //-1 is from the ++ we do before the assignment
            double *local_output_data = p_output_data + n_outputs*iChan + 2*iChunk - 1;
            //double *local_max_data = max_data + n_outputs*iChan + iChunk - 1;
            
            //             __m256d max4, min4, temp_max4, temp_min4;
//             
//             min_max_32(current_data_point,&min4,&max4);
//             
//             for (mwSize i32 = 1; i32 < n_32s; i32++){
//                 current_data_point+=32;
//                 min_max_32(current_data_point,&temp_min4,&temp_max4);
//                 max4 = _mm256_max_pd(max4,temp_max4);
//                 min4 = _mm256_min_pd(min4,temp_min4);
//             }
//             
//             double *temp_max = (double *)&max4;
//             double *temp_min = (double *)&min4;
//             
//             *(++local_min_data) = temp_min[0];
//             *(++local_max_data) = temp_max[0];
            
            
            double min = *current_data_point;
            double max = *current_data_point;
            
            for (mwSize iSample = 1; iSample < samples_per_chunk; iSample++){
                if (*(++current_data_point) > max){
                    max = *current_data_point;
                }else if (*current_data_point < min){
                    min = *current_data_point;
                }
            }
            ++current_data_point;
            *(++local_output_data) = min;
            *(++local_output_data) = max;
        }
    }
    
    if (n_samples_extra){
        #pragma omp parallel for simd
        for (mwSize iChan = 0; iChan < n_chans; iChan++){
            //TODO: This needs to be implemented
            
            double *current_data_point = p_start_data + n_samples_data*iChan + n_chunks*samples_per_chunk;
            
            double *local_output_data = p_output_data + n_outputs*iChan + 2*n_chunks - 1;
            //double *local_max_data = max_data + n_outputs*iChan + n_chunks - 1;
            double min = *current_data_point;
            double max = *current_data_point;
            //TODO: We may only have 1
            
            for (mwSize iSample = 1; iSample < n_samples_extra; iSample++){
                if (*(++current_data_point) > max){
                    max = *current_data_point;
                }else if (*current_data_point < min){
                    min = *current_data_point;
                }
            }
            *(++local_output_data) = min;
            *(++local_output_data) = max;
        }
    }
            //TODO: We might have one trailing bit of data to handle that didn't
        //fit evenly into the search ...
    
    plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
    
    mxSetData(plhs[0],p_output_data_absolute);
    mxSetM(plhs[0],n_outputs);
    mxSetN(plhs[0],n_chans);

}