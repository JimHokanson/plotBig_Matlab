#include "mex.h"
#include <immintrin.h>
#include "simd_guard.h"

//
//  For compiling instructions, see big_plot.compile()
//

//Status
//-----------
//1) Parallel min and max across threads
//2) Starts at an arbitrary index into the data (for processing subsets)
//3) All classes supported
//4) Most of SIMD is implemented ...





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

//=========================================================================

//=========================================================================

#define INIT_POINTERS(TYPE) \
  	TYPE *p_input_data_fixed = (TYPE *)mxGetData(prhs[0]); \
    TYPE *p_input_data = p_input_data_fixed; \
 	TYPE *p_output_data_fixed = (TYPE *)mxMalloc(sizeof(TYPE)*n_chans*n_outputs_per_chan); \
    TYPE *p_output_data = p_output_data_fixed;
    
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
    
#define INIT_MAIN_LOOP(type)                            \
    /*#pragma omp parallel for simd collapse(2)*/       \
    _Pragma("omp parallel for simd collapse(2)")        \
    for (mwSize iChan = 0; iChan < n_chans; iChan++){   \
        /*Note, we can't initialize anything before this loop, since we*/           \
        /*are collapsing the first two loops. This allows us to parallelize*/       \
        /*both of the first two loops, which is good when the # of channels*/       \
        /*does not equal the # of threads.*/                                        \
        for (mwSize iChunk = 0; iChunk < n_chunks; iChunk++){                       \
            type *current_input_data_point = p_input_data + n_samples_data*iChan + iChunk*samples_per_chunk; \
            /*Pointer => start + column wrapping + offset (row into column) - 1*/   \
            /*  *2 since we store min and max in each chunk*/                       \
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
    
#define LOG_MIN_MAX             \
    *local_output_data = min;   \
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

#define POPULATE_OUTPUT \
    plhs[0] = mxCreateNumericMatrix(0, 0, data_class_id, mxREAL); \
    mxSetData(plhs[0],p_output_data_fixed);     \
    mxSetM(plhs[0],n_outputs_per_chan);         \
    mxSetN(plhs[0],n_chans);                    \
    if (nlhs == 2){                             \
        plhs[1] = mxCreateDoubleScalar(p_type); \
    }

#define STD_INPUT_CALL local_output_data, local_output_data+1, samples_per_chunk, current_input_data_point
#define STD_INPUT_DEFINE(type) type *min_out, type *max_out, mwSize samples_per_chunk, type *current_input_data_point    

//==================================================================
//                          MIN MAX STANDARD
//==================================================================    
#define GET_MIN_MAX_STANDARD(TYPE)              \
	TYPE min = *current_input_data_point;       \
 	TYPE max = *current_input_data_point;       \
                                                \
    for (mwSize iSample = 1; iSample < samples_per_chunk; iSample++){    \
        if (*(++current_input_data_point) > max){   \
            max = *current_input_data_point;        \
        }else if (*current_input_data_point < min){ \
            min = *current_input_data_point;        \
        }                                           \
    }                                               \
                                                    \
    *min_out = min;                                 \
    *max_out = max;    
    
//==================================================================    
    
void getMinMaxDouble_Standard(STD_INPUT_DEFINE(double)){
    GET_MIN_MAX_STANDARD(double) 
    //mexPrintf("max %g\n",*min_out);
    //mexPrintf("min %g\n",*max_out);
}

void getMinMaxFloat_Standard(STD_INPUT_DEFINE(float)){
    GET_MIN_MAX_STANDARD(float) 
}

void getMinMaxUint64_Standard(STD_INPUT_DEFINE(uint64_t)){
    GET_MIN_MAX_STANDARD(uint64_t) 
}

void getMinMaxUint32_Standard(STD_INPUT_DEFINE(uint32_t)){
    GET_MIN_MAX_STANDARD(uint32_t) 
}

void getMinMaxUint16_Standard(STD_INPUT_DEFINE(uint16_t)){
    GET_MIN_MAX_STANDARD(uint16_t) 
}

void getMinMaxUint8_Standard(STD_INPUT_DEFINE(uint8_t)){
    GET_MIN_MAX_STANDARD(uint8_t) 
}

void getMinMaxInt64_Standard(STD_INPUT_DEFINE(int64_t)){
    GET_MIN_MAX_STANDARD(int64_t) 
}

void getMinMaxInt32_Standard(STD_INPUT_DEFINE(int32_t)){
    GET_MIN_MAX_STANDARD(int32_t) 
}

void getMinMaxInt16_Standard(STD_INPUT_DEFINE(int16_t)){
    GET_MIN_MAX_STANDARD(int16_t) 
}

void getMinMaxInt8_Standard(STD_INPUT_DEFINE(int8_t)){
    GET_MIN_MAX_STANDARD(int8_t) 
}

//==================================================================
    
//GET_MIN_MAX_SIMD(double,,4,__m256d,_mm256_loadu_pd,_mm256_max_pd,_mm256_min_pd,_mm256_storeu_pd)
//                next = _mm256_loadu_si256((__m256i *)(data+j));

//==================================================================
//                          MIN MAX SIMD
//==================================================================    
#define GET_MIN_MAX_SIMD(TYPE,CAST,N_SIMD,SIMD_TYPE,LOAD,MAX,MIN,STORE) \
    SIMD_TYPE next;                         \
    SIMD_TYPE max_result;                   \
    SIMD_TYPE min_result;                   \
    TYPE max_output[N_SIMD];                \
	TYPE min_output[N_SIMD];                \
    TYPE min;                               \
    TYPE max;                               \
                                            \
    max_result = LOAD(CAST current_input_data_point); \
    min_result = max_result;                \
                                            \
    for (mwSize j = N_SIMD; j < (samples_per_chunk/N_SIMD)*N_SIMD; j+=N_SIMD){ \
        next = LOAD(CAST (current_input_data_point+j)); \
        max_result = MAX(max_result, next);             \
        min_result = MIN(min_result, next);             \
    }                                       \
                                            \
    /*Extract max values and reduce ...*/   \
    STORE(CAST max_output, max_result);     \
    STORE(CAST min_output, min_result);     \
                                            \
    max = max_output[0];                    \
    for (int i = 1; i < N_SIMD; i++){       \
        if (max_output[i] > max){           \
            max = max_output[i];            \
        }                                   \
    }                                       \
    min = min_output[0];                    \
    for (int i = 1; i < N_SIMD; i++){       \
        if (min_output[i] < min){           \
            min = min_output[i];            \
        }                                   \
    }                                       \
                                            \
    for (mwSize j = (samples_per_chunk/N_SIMD)*N_SIMD; j < samples_per_chunk; j++){ \
        if (*(current_input_data_point + j) > max){             \
            max = *(current_input_data_point + j);              \
        }else if (*(current_input_data_point + j) < min){       \
            min = *(current_input_data_point + j);              \
        }                                                       \
    }                                                           \
                                                                \
    *min_out = min;                                             \
    *max_out = max;

//=========================================================================
void getMinMaxDouble_SIMD_256(STD_INPUT_DEFINE(double)){
    GET_MIN_MAX_SIMD(double,,4,__m256d,_mm256_loadu_pd,_mm256_max_pd,_mm256_min_pd,_mm256_storeu_pd)
}
void getMinMaxFloat_SIMD_256(STD_INPUT_DEFINE(float)){
    GET_MIN_MAX_SIMD(float,,8,__m256,_mm256_loadu_ps,_mm256_max_ps,_mm256_min_ps,_mm256_storeu_ps)    
}
//--------------------
void getMinMaxUint32_SIMD_256(STD_INPUT_DEFINE(uint32_t)){
    GET_MIN_MAX_SIMD(uint32_t,(__m256i *),8,__m256i,_mm256_loadu_si256,_mm256_max_epu32,_mm256_min_epu32,_mm256_storeu_si256)    
}
void getMinMaxUint32_SIMD_128(STD_INPUT_DEFINE(uint32_t)){
    GET_MIN_MAX_SIMD(uint32_t,(__m128i *),4,__m128i,_mm_loadu_si128,_mm_max_epu32,_mm_min_epu32,_mm_storeu_si128)    
}
//--------------------
void getMinMaxUint16_SIMD_256(STD_INPUT_DEFINE(uint16_t)){
    GET_MIN_MAX_SIMD(uint16_t,(__m256i *),16,__m256i,_mm256_loadu_si256,_mm256_max_epu16,_mm256_min_epu16,_mm256_storeu_si256)    
}
void getMinMaxUint16_SIMD_128(STD_INPUT_DEFINE(uint16_t)){
    GET_MIN_MAX_SIMD(uint16_t,(__m128i *),8,__m128i,_mm_loadu_si128,_mm_max_epu16,_mm_min_epu16,_mm_storeu_si128)    
}
//--------------------
void getMinMaxUint8_SIMD_256(STD_INPUT_DEFINE(uint8_t)){
    GET_MIN_MAX_SIMD(uint8_t,(__m256i *),32,__m256i,_mm256_loadu_si256,_mm256_max_epu8,_mm256_min_epu8,_mm256_storeu_si256)    
}
void getMinMaxUint8_SIMD_128(STD_INPUT_DEFINE(uint8_t)){
    GET_MIN_MAX_SIMD(uint8_t,(__m128i *),16,__m128i,_mm_loadu_si128,_mm_max_epu8,_mm_min_epu8,_mm_storeu_si128)    
}
//--------------------
void getMinMaxInt32_SIMD_256(STD_INPUT_DEFINE(int32_t)){
    GET_MIN_MAX_SIMD(int32_t,(__m256i *),8,__m256i,_mm256_loadu_si256,_mm256_max_epi32,_mm256_min_epi32,_mm256_storeu_si256)    
}
void getMinMaxInt32_SIMD_128(STD_INPUT_DEFINE(int32_t)){
    GET_MIN_MAX_SIMD(int32_t,(__m128i *),4,__m128i,_mm_loadu_si128,_mm_max_epi32,_mm_min_epi32,_mm_storeu_si128)    
}
//--------------------
void getMinMaxInt16_SIMD_256(STD_INPUT_DEFINE(int16_t)){
    GET_MIN_MAX_SIMD(int16_t,(__m256i *),16,__m256i,_mm256_loadu_si256,_mm256_max_epi16,_mm256_min_epi16,_mm256_storeu_si256)    
}
void getMinMaxInt16_SIMD_128(STD_INPUT_DEFINE(int16_t)){
    GET_MIN_MAX_SIMD(int16_t,(__m128i *),8,__m128i,_mm_loadu_si128,_mm_max_epi16,_mm_min_epi16,_mm_storeu_si128)    
}
//--------------------
void getMinMaxInt8_SIMD_256(STD_INPUT_DEFINE(int8_t)){
    GET_MIN_MAX_SIMD(int8_t,(__m256i *),32,__m256i,_mm256_loadu_si256,_mm256_max_epi8,_mm256_min_epi8,_mm256_storeu_si256)    
}
void getMinMaxInt8_SIMD_128(STD_INPUT_DEFINE(int8_t)){
    GET_MIN_MAX_SIMD(int8_t,(__m128i *),16,__m128i,_mm_loadu_si128,_mm_max_epi8,_mm_min_epi8,_mm_storeu_si128)    
}
//=========================================================================

static int hw_struct_initialized = 0;
static struct cpu_x86 s;

//=========================================================================
//                          MEX ENTRY POINT
//=========================================================================
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
    //  Outputs
    //  -------
    //  min_max_data :
    //  p_type :
    //      - 0 - nothing
    //      - 1 - SSE2
    //      - 2 - SSE41
    //      - 3 - AVX
    //      - 4 - AVX2
        
    if (!hw_struct_initialized){
        cpu_x86__detect_host(&s);
        hw_struct_initialized = 1;
    }
    
    bool process_subset;
    double p_type = 0;
    
    //---------------------------------------------------------------------
    //                          Input Checking
    //---------------------------------------------------------------------
    if (!(nrhs == 2 || nrhs == 4)){
        mexErrMsgIdAndTxt("SL:reduce_to_width:n_inputs",
                "Invalid # of inputs, 2 or 4 expected");
    }else if (!mxIsClass(prhs[1],"double")){
        //samples_per_chunk should be double
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
    
    if (!(nlhs == 1 || nlhs == 2)){
        mexErrMsgIdAndTxt("jsmn_mex:n_inputs",
                "Invalid # of outputs, 1 or 2 expected");
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
        //Add on one extra pair when the # of samples per chunk doesn't 
        //evenly dividie the input data
        n_outputs_per_chan += 2; 
    }
    
    //Note, we might get some replication with the first and last
    //data points if only one of those is cropped. This should be fine
    //for rendering.
    if (pad_with_endpoints){
        n_outputs_per_chan += 2;
    }
    
    
    //Dispatch based on data type
    //---------------------------------------------------------------------
    mxClassID data_class_id = mxGetClassID(prhs[0]);
    switch (data_class_id){
        case mxDOUBLE_CLASS:
            goto S_PROCESS_DOUBLE;
            break;
        case mxSINGLE_CLASS:
            goto S_PROCESS_SINGLE;
         	break;
        case mxINT64_CLASS:
            goto S_PROCESS_INT64;
            break;
        case mxUINT64_CLASS:
            goto S_PROCESS_UINT64;
            break;
        case mxINT32_CLASS:
            goto S_PROCESS_INT32;
            break;
        case mxUINT32_CLASS:
            goto S_PROCESS_UINT32;
            break;
        case mxINT16_CLASS:
            goto S_PROCESS_INT16;
            break;
        case mxUINT16_CLASS:
            goto S_PROCESS_UINT16;
            break;
        case mxINT8_CLASS:
            goto S_PROCESS_INT8;
            break;
        case mxUINT8_CLASS:
            goto S_PROCESS_UINT8;
            break;
        default:
            mexErrMsgIdAndTxt("JAH:reduce_to_width_mex",
                    "Class is not supported");
    }   
//=========================================================================
//                      Processing based on type    
//=========================================================================
S_PROCESS_DOUBLE:;
    {
        //Design Notes
        //-----------------------------------------------------------------
        //- Given the high # of variables in play I am using goto
        //  instead of passing the variables into a function. Presumably
        //  a variable struct would work as well, but I found this slightly 
        //  easier.
        //- Due to differing definitions of variable types, all states are 
        //  enclosed in brackets
        //- The if-statements are outside the loops. Presumably the compiler
        //  could optimize this away if inside the loops but I wasn't sure.
        
        INIT_POINTERS(double);    

        GRAB_OUTSIDE_POINTS;

        //Note I'm skipping the old SSE version since I expect
        //everyone to have AVX
        //- the OS_AVX is to be technically correct but I expect
        //all current OSs to have it enabled
        if (s.HW_AVX && s.OS_AVX && samples_per_chunk > 4){
            INIT_MAIN_LOOP(double)
                getMinMaxDouble_SIMD_256(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 3;
        }else{
            INIT_MAIN_LOOP(double)
                getMinMaxDouble_Standard(STD_INPUT_CALL);
            END_MAIN_LOOP
        }

        PROCESS_EXTRA_NON_CHUNK_SAMPLES(double)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_SINGLE:;
    {
        INIT_POINTERS(float);    

        GRAB_OUTSIDE_POINTS;

        if (s.HW_AVX && s.OS_AVX && samples_per_chunk > 8){
            INIT_MAIN_LOOP(float)
                getMinMaxFloat_SIMD_256(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 3;
        }else{
            INIT_MAIN_LOOP(float)
                getMinMaxFloat_Standard(STD_INPUT_CALL);
            END_MAIN_LOOP
        }

        PROCESS_EXTRA_NON_CHUNK_SAMPLES(float)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_UINT64:;
    {
        //SIMD not available until AVX512. We could code this up but 
        //I can't test it
        INIT_POINTERS(uint64_t);    

        GRAB_OUTSIDE_POINTS;

        INIT_MAIN_LOOP(uint64_t)
            getMinMaxUint64_Standard(STD_INPUT_CALL);
        END_MAIN_LOOP
       
        PROCESS_EXTRA_NON_CHUNK_SAMPLES(uint64_t)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_UINT32:;
    {
        INIT_POINTERS(uint32_t);    

        GRAB_OUTSIDE_POINTS;
                    
        if (s.HW_AVX2 && s.OS_AVX && samples_per_chunk > 8){
            INIT_MAIN_LOOP(uint32_t)
                getMinMaxUint32_SIMD_256(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 4;
        }else if (s.HW_SSE41 && samples_per_chunk > 4){
            INIT_MAIN_LOOP(uint32_t)
                getMinMaxUint32_SIMD_128(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 2;
        }else{
            INIT_MAIN_LOOP(uint32_t)
                getMinMaxUint32_Standard(STD_INPUT_CALL);
            END_MAIN_LOOP
        }

        PROCESS_EXTRA_NON_CHUNK_SAMPLES(uint32_t)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_UINT16:;
    {
        INIT_POINTERS(uint16_t);    

        GRAB_OUTSIDE_POINTS;

        if (s.HW_AVX2 && s.OS_AVX && samples_per_chunk > 16){
            INIT_MAIN_LOOP(uint16_t)
                getMinMaxUint16_SIMD_256(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 4;
        }else if (s.HW_SSE41 && samples_per_chunk > 8){
            INIT_MAIN_LOOP(uint16_t)
                getMinMaxUint16_SIMD_128(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 2;
        }else{
            INIT_MAIN_LOOP(uint16_t)
                getMinMaxUint16_Standard(STD_INPUT_CALL);
            END_MAIN_LOOP 
        }

        PROCESS_EXTRA_NON_CHUNK_SAMPLES(uint16_t)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_UINT8:;
    {
        INIT_POINTERS(uint8_t);    

        GRAB_OUTSIDE_POINTS;

        if (s.HW_AVX2 && s.OS_AVX && samples_per_chunk > 32){
            INIT_MAIN_LOOP(uint8_t)
                getMinMaxUint8_SIMD_256(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 4;
        }else if(s.HW_SSE2 && samples_per_chunk > 16){
            INIT_MAIN_LOOP(uint8_t)
                getMinMaxUint8_SIMD_128(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 1;
        }else{
            INIT_MAIN_LOOP(uint8_t)
                getMinMaxUint8_Standard(STD_INPUT_CALL);
            END_MAIN_LOOP
        }

        PROCESS_EXTRA_NON_CHUNK_SAMPLES(uint8_t)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_INT64:;
    {
        INIT_POINTERS(int64_t);    

        GRAB_OUTSIDE_POINTS;

        INIT_MAIN_LOOP(int64_t)
            getMinMaxInt64_Standard(STD_INPUT_CALL);
        END_MAIN_LOOP
       
        PROCESS_EXTRA_NON_CHUNK_SAMPLES(int64_t)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_INT32:;
    {
        INIT_POINTERS(int32_t);    

        GRAB_OUTSIDE_POINTS;

        if (s.HW_AVX2 && s.OS_AVX && samples_per_chunk > 8){
            INIT_MAIN_LOOP(int32_t)
                getMinMaxInt32_SIMD_256(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 4;
        }else if (s.HW_SSE41 && samples_per_chunk > 4){
            INIT_MAIN_LOOP(int32_t)
                getMinMaxInt32_SIMD_128(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 2;
        }else{
            INIT_MAIN_LOOP(int32_t)
                getMinMaxInt32_Standard(STD_INPUT_CALL);
            END_MAIN_LOOP 
        }

        PROCESS_EXTRA_NON_CHUNK_SAMPLES(int32_t)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_INT16:;
    {
        INIT_POINTERS(int16_t);    

        GRAB_OUTSIDE_POINTS;

        if (s.HW_AVX2 && s.OS_AVX && samples_per_chunk > 16){
            INIT_MAIN_LOOP(int16_t)
                getMinMaxInt16_SIMD_256(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 4;
        }else if (s.HW_SSE2 && samples_per_chunk > 8){
            INIT_MAIN_LOOP(int16_t)
                getMinMaxInt16_SIMD_128(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 1;
        }else{
            INIT_MAIN_LOOP(int16_t)
                getMinMaxInt16_Standard(STD_INPUT_CALL);
            END_MAIN_LOOP
        }

        PROCESS_EXTRA_NON_CHUNK_SAMPLES(int16_t)

        POPULATE_OUTPUT
        return;
    }

S_PROCESS_INT8:;
    {
        INIT_POINTERS(int8_t);    

        GRAB_OUTSIDE_POINTS;

        if (s.HW_AVX2 && s.OS_AVX  && samples_per_chunk > 32){
            INIT_MAIN_LOOP(int8_t)
                getMinMaxInt8_SIMD_256(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 4;
        }else if (s.HW_SSE41 && samples_per_chunk > 16){
            INIT_MAIN_LOOP(int8_t)
                getMinMaxInt8_SIMD_128(STD_INPUT_CALL);
            END_MAIN_LOOP
            p_type = 2;
        }else{
            INIT_MAIN_LOOP(int8_t)
                getMinMaxInt8_Standard(STD_INPUT_CALL);
            END_MAIN_LOOP
        }

        PROCESS_EXTRA_NON_CHUNK_SAMPLES(int8_t)

        POPULATE_OUTPUT
        return;
    }


}