#include "mex.h"
#include <immintrin.h>
#include "simd_guard.h"

/*
  mex simd_check.c
*/

static int hw_struct_initialized = 0;
static struct cpu_x86 s;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
          
    if (!hw_struct_initialized){
        cpu_x86__detect_host(&s);
        hw_struct_initialized = 1;
    }
    
    if (s.HW_AVX){
        mexPrintf("AVX HW supported\n");
    }else{
        mexPrintf("AVX HW not supported\n");
    }
    
    if (s.OS_AVX){
        mexPrintf("AVX OS supported\n");
    }else{
        mexPrintf("AVX OS not supported\n");
    }
    
 	if (s.HW_AVX2){
        mexPrintf("AVX2 HW supported\n");
    }else{
        mexPrintf("AVX2 HW not supported\n");
    }
    
}