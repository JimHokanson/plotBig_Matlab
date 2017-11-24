#include "mex.h"
#include <immintrin.h>

//
//  For compiling instructions, see big_plot.compile()
//


//Status
//-----------
//1) Parallel min and max across threads
//2) Starts at an arbitrary index into the data (for processing subsets)
//
//TODO
//------------------------------
//3) Implement class support
//4) Implement the min/max avx instructions - _mm256_min/max_pd
    

/*
//TODO: Degenerate cases:

//I need to move all of this to test cases
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

mwSize getScalarInput(const mxArray *input, int input_number){
    //
    //  Inputs
    //  -------
    //  input_number : 1 based
    //      Used for error reporting
    
    if (!mxIsClass(input,"double")){
        mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type",
                "Input #%d type needs to be double",input_number);
    }
    
    double temp = mxGetScalar(input);
    return (mwSize) temp;
    
}

#define INIT_POINTERS(type) \
  	type *p_input_data_fixed = (type*)mxGetData(prhs[0]); \
    type *p_input_data = p_input_data_fixed; \
 	type *p_output_data_fixed = (type*)mxMalloc(sizeof(type)*n_chans*n_outputs_per_chan); \
    type *p_output_data = p_output_data_fixed;
    
#define GRAB_OUTSIDE_POINTS \
    /*Initialize the first and last values of the output - not class specific*/ \
    /*---------------------------------------------------------------------*/   \
    /*We keep the first and last values if we are not plotting everything*/     \
    /*We need to loop through each channel and assign:*/                        \
    /*  1) The first data point in each channel to the first output value*/     \
    /*  2) The last data point in each channel to the last output value*/       \
    /* */                                                       \
    /*  - This is not class specific*/                          \
    /*  - Ideally we could make this optional for streaming*/   \
    if (pad_with_endpoints){                                    \
        for (mwSize iChan = 0; iChan < n_chans; iChan++){       \
            /*Store first data point to output*/                \
            *p_output_data = *p_input_data;                     \
                                                                \
            /*Advance input and output pointers to end of column*/ \
            p_output_data += (n_outputs_per_chan-1);            \
            p_input_data += (n_samples_data-1);                 \
                                                                \
            /*Store last data point*/                           \
            *p_output_data = *p_input_data;                     \
                                                                \
            /*Roll over to the next channel*/                   \
            /*1st sample of next is 1 more than last sample of current*/ \
            ++p_input_data;                                     \
            ++p_output_data;                                    \
        }                                                       \
                                                                \
        /*Adjust pointers for next section*/                    \
        /*------------------------------------------------*/    \
        /*Resetting to initial position*/                       \
        p_output_data = p_output_data_fixed;                    \
        p_input_data = p_input_data_fixed;                      \
                                                                \
        /*Move output beyond first point (logged above)*/       \
        ++p_output_data;                                        \
                                                                \
        if (process_subset){                                    \
            p_input_data = p_input_data + start_index;          \
        }                                                       \
    }
    
    

    
    
#define INIT_MAIN_LOOP(type) \
    /*#pragma omp parallel for simd collapse(2)*/       \
    _Pragma("omp parallel for simd collapse(2)")        \
    for (mwSize iChan = 0; iChan < n_chans; iChan++){   \
        /*Note, we can't initialize anything before this loop, since we*/       \
        /*are collapsing the first two loops. This allows us to parallelize*/   \
        /*both of the first two loops, which is good when the # of channels*/   \
        /*does not equal the # of threads.*/                                    \
        for (mwSize iChunk = 0; iChunk < n_chunks; iChunk++){   \
            type *current_input_data_point = p_input_data + n_samples_data*iChan + iChunk*samples_per_chunk; \
            /*Pointer => start + column wrapping + offset (row into column) - 1*/ \
            /*  *2 since we store min and max in each chunk*/   \
            type *local_output_data = p_output_data + n_outputs_per_chan*iChan + 2*iChunk;

#define END_MAIN_LOOP \
        } \
    }
    
#define RUN_STD_MIN_MAX \
    for (mwSize iSample = 1; iSample < samples_per_chunk; iSample++){   \
        if (*(++current_input_data_point) > max){                   	\
            max = *current_input_data_point;                            \
        }else if (*current_input_data_point < min){                     \
            min = *current_input_data_point;                            \
        }                                                               \
    }
    
#define LOG_MIN_MAX \
    *local_output_data = min; \
	*(++local_output_data) = max;
    
    
#define PROCESS_EXTRA_NON_CHUNK_SAMPLES(type) \
    /*---------------------------------------------------------------------*/ \
    /*           Processing last part that didn't fit into a chunk         */ \
    /*---------------------------------------------------------------------*/ \
    if (n_samples_not_in_chunk){                            \
        _Pragma("omp parallel for simd")                    \
        for (mwSize iChan = 0; iChan < n_chans; iChan++){   \
                                                            \
            type *current_input_data_point = p_input_data + n_samples_data*iChan + n_chunks*samples_per_chunk; \
                                                            \
            type *local_output_data = p_output_data + n_outputs_per_chan*iChan + 2*n_chunks; \
                                                            \
            type min = *current_input_data_point;           \
            type max = *current_input_data_point;           \
                                                            \
            for (mwSize iSample = 1; iSample < n_samples_not_in_chunk; iSample++){ \
                if (*(++current_input_data_point) > max){   \
                    max = *current_input_data_point;        \
                }else if (*current_input_data_point < min){ \
                    min = *current_input_data_point;        \
                }                                           \
            }                                               \
            *local_output_data = min;                       \
            *(++local_output_data) = max;                   \
        }                                                   \
    }

    
    
void getMinMaxDoubleStandard(double *min_out, double *max_out, 
        mwSize samples_per_chunk, double *current_input_data_point){
    
	double min = *current_input_data_point;
 	double max = *current_input_data_point;
    
    for (mwSize iSample = 1; iSample < samples_per_chunk; iSample++){   
        if (*(++current_input_data_point) > max){                   	
            max = *current_input_data_point;                            
        }else if (*current_input_data_point < min){                     
            min = *current_input_data_point;                            
        }                                                               
    }
    
    *min_out = min;
    *max_out = max;
    
}

void getMinMaxDoubleSIMD(double *min_out, double *max_out, 
        mwSize samples_per_chunk, double *current_input_data_point){
        
    __m256d next;
    __m256d max_result;
    __m256d min_result;
    double max_output[4];
	double min_output[4];
    double min;
    double max;

    max_result = _mm256_loadu_pd(current_input_data_point);
    min_result = max_result;
    
    //0 1 2 3 4 5 6 7 8 9
    //        1 2 3 4
    
    
    for (mwSize j = 4; j < (samples_per_chunk/4)*4; j+=4){
        next = _mm256_loadu_pd((current_input_data_point+j));
        max_result = _mm256_max_pd(max_result, next);
        min_result = _mm256_min_pd(min_result, next);
    }

    //Extract max values and reduce ...
    _mm256_storeu_pd(max_output, max_result);
    _mm256_storeu_pd(min_output, min_result);

    max = max_output[0];
    for (int i = 1; i < 4; i++){
        if (max_output[i] > max){
            max = max_output[i];
        } 
    } 
    min = min_output[0];
    for (int i = 1; i < 4; i++){
        if (min_output[i] < min){
            min = min_output[i];
        } 
    } 
    
    for (mwSize j = (samples_per_chunk/4)*4; j < samples_per_chunk; j++){
        if (*(current_input_data_point + j) > max){
            max = *(current_input_data_point + j);
        }else if (*(current_input_data_point + j) < min){
            min = *(current_input_data_point + j);
        }
    }
                
    *min_out = min;
    *max_out = max;
    
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
    //      The output is a min and max pair per chunk (with possible data
    //      padding)
    //   
    //  Optional Inputs
    //  ---------------
    //  start_sample: #, 1 based
    //      If specified, the end sample must also be specified
    //  end_sample: #, 1 based
    //
    
    

    
    bool process_subset;
    
    //---------------------------------------------------------------------
    //                      Input Checking
    //---------------------------------------------------------------------
    
    //JAH: Once we update
    
    if (!(nrhs == 2 || nrhs == 4)){
        mexErrMsgIdAndTxt("SL:reduce_to_width:n_inputs",
                "Invalid # of inputs, 2 or 4 expected");
    }else if (!mxIsClass(prhs[0],"double")){
        mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type",
                "First input type needs to be double");
    }else if (!mxIsClass(prhs[1],"double")){
        mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type",
                "Second input type needs to be double");
    }
    
    if (nrhs == 4){
        process_subset = true;
        if (!mxIsClass(prhs[2],"double")){
            mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type",
                    "Third input type needs to be double");
        }else if (!mxIsClass(prhs[3],"double")){
            mexErrMsgIdAndTxt("SL:reduce_to_width:input_class_type",
                    "Fourth input type needs to be double");
        }  
    }else{
        process_subset = false; 
    }
    
    if (!(nlhs == 1)){
        mexErrMsgIdAndTxt("jsmn_mex:n_inputs",
                "Invalid # of outputs, 1 expected");
    }
    
    
    //---------------------------------------------------------------------
    //                  Initialization of variables
    //---------------------------------------------------------------------
    //This is used to adjust the data pointer to the start of each column
    mwSize n_samples_data = mxGetM(prhs[0]);
    
    //This is used to indicate how many samples we need to examine
    //for min and max values
    mwSize n_samples_process = n_samples_data;
    mwSize n_chans = mxGetN(prhs[0]);
    
    mwSize samples_per_chunk = getScalarInput(prhs[1],2);
    
    mwSize start_index;
    mwSize stop_index;
    
    //If we process a subset, determine how many samples we need to
    //offset the start and how many less samples are going to process.
    //---------------------------------------------------------------------
    if (process_subset){
      	start_index = getScalarInput(prhs[2],3) - 1; //make 0 based
      	stop_index  = getScalarInput(prhs[3],4) - 1;
        
        mwSize max_valid_index = n_samples_data - 1;
        
        if (start_index < 0 || start_index > max_valid_index){
            mexErrMsgIdAndTxt("SL:reduce_to_width:start_index","Start index is out of range");
        }else if (stop_index < 0 || stop_index > max_valid_index){
            mexErrMsgIdAndTxt("SL:reduce_to_width:stop_index","Stop index is out of range");
        }else if (stop_index < start_index){
            mexErrMsgIdAndTxt("SL:reduce_to_width:stop_before_start","Start index comes after stop index");
        }
        
        n_samples_process = stop_index - start_index + 1;
    }
    
    //In general we pad with the endpoints to prevent axes resizing 
    //(in Matlab). We always pad with the endpoints when a subset 
    //is requested.
    bool pad_with_endpoints = n_samples_process != n_samples_data;
    
    //Integer division, should automatically floor (as desired)
    mwSize n_chunks = n_samples_process/samples_per_chunk;
    mwSize n_samples_not_in_chunk = n_samples_process - n_chunks*samples_per_chunk;
    
    //For each chunk we store a min and max value
    //Even if the same value we duplicate it.
    mwSize n_outputs_per_chan = 2*n_chunks;
    
    if (n_samples_not_in_chunk){
        n_outputs_per_chan += 2; //Add on one extra pair when 
        //the # of samples per chunk doesn't evenly dividie the input data
    }
    
    //Note, we might get some replication with the first and last
    //data points if only one of those is cropped
    if (pad_with_endpoints){
        n_outputs_per_chan += 2;
    }
    
    mxClassID data_class_id = mxGetClassID(prhs[0]);
    switch (data_class_id){
        case mxDOUBLE_CLASS:
            goto S_PROCESS_DOUBLE;
            break;
        case mxSINGLE_CLASS:
            //INIT_POINTERS(float)
         	break;
        case mxINT64_CLASS:
            //INIT_POINTERS(int64_t)
            break;
        case mxUINT64_CLASS:
            //INIT_POINTERS(uint64_t)
            break;
        case mxINT32_CLASS:
            //INIT_POINTERS(int32_t)
            break;
        case mxUINT32_CLASS:
            //INIT_POINTERS(uint32_t)
            break;
        case mxINT16_CLASS:
            //INIT_POINTERS(int16_t)
            break;
        case mxUINT16_CLASS:
            //INIT_POINTERS(uint16_t)
            break;
        case mxINT8_CLASS:
            //INIT_POINTERS(int8_t)
            break;
        case mxUINT8_CLASS:
            //INIT_POINTERS(uint8_t)
            break;
        default:
            mexErrMsgIdAndTxt("JAH:reduce_to_width_mex",
                    "Class is not supported");
    }
    
//================================================================

S_PROCESS_DOUBLE:;
    
    INIT_POINTERS(double);    
    
    GRAB_OUTSIDE_POINTS;
        
    if (samples_per_chunk > 4){
        INIT_MAIN_LOOP(double)
            
            getMinMaxDoubleStandard(local_output_data, local_output_data++, 
                    samples_per_chunk, current_input_data_point);
   
        END_MAIN_LOOP
    }else{
        INIT_MAIN_LOOP(double)
        
            getMinMaxDoubleSIMD(local_output_data, local_output_data++, 
                    samples_per_chunk, current_input_data_point);
           
        END_MAIN_LOOP
    }
    
    PROCESS_EXTRA_NON_CHUNK_SAMPLES(double)
    
    

S_FINALIZE:    
    //Finalize output
    //-------------------------------------------------------
    plhs[0] = mxCreateNumericMatrix(0, 0, data_class_id, mxREAL);
    mxSetData(plhs[0],p_output_data_fixed);
    mxSetM(plhs[0],n_outputs_per_chan);
    mxSetN(plhs[0],n_chans);

}