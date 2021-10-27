#include "mex.h"
#include <math.h> 
#include "float.h"
#include <immintrin.h>


//  M-file gateway is:
//  big_plot.anyNANs


//  d = zeros(1e8,3);
//  d(1) = NaN;
//  tic; wtf = big_plot.anyNANs(d); toc;    
//  tic; any(isnan(d)); toc;

//  Compile via:
//  mex CFLAGS='$CFLAGS -O2 -funsafe-math-optimizations -march=native' nan_check_mex.c -v

static inline
int any_nan_block(double *p) {
    __m256d a = _mm256_loadu_pd(p+0);
    __m256d abnan = _mm256_cmp_pd(a, _mm256_loadu_pd(p+ 4), _CMP_UNORD_Q);
    __m256d c = _mm256_loadu_pd(p+8);
    __m256d cdnan = _mm256_cmp_pd(c, _mm256_loadu_pd(p+12), _CMP_UNORD_Q);
    __m256d abcdnan = _mm256_or_pd(abnan, cdnan);
    return _mm256_movemask_pd(abcdnan);
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{
    //
    //      Calling forms
    //      -----
    //      flag = nan_check_mex(data)
    //
    //      
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
        
    if (!(nrhs == 1 || nrhs ==2)){
        mexErrMsgIdAndTxt("big_plot:nan_check:call_error","Invalid # of inputs, 1 or 2 expected");
    }
    
    int option = 1;
    if (nrhs == 2){
        option = (int)mxGetScalar(prhs[1]);
    }
    
    if (!mxIsClass(prhs[0],"double")){
        mexErrMsgIdAndTxt("big_plot:nan_check:call_error","The input array must be of type double");
    }    
    
    if (!(nlhs == 1)){
        mexErrMsgIdAndTxt("big_plot:nan_check:call_error","Invalid # of outputs, 1 expected");
    }
    
    mwSize n_rows = mxGetM(prhs[0]);
    mwSize n_cols = mxGetN(prhs[0]);
    
    plhs[0] = mxCreateLogicalMatrix(1,n_cols); //default is false
    //which is what we want ...
    mxLogical *pl = mxGetLogicals(plhs[0]);
    
    //Hold onto the end ...
    
    
    double *data = mxGetData(prhs[0]);
    double *data2;
    
    __m256d a, b, c, d, e, f;
    
    int temp = 0;
    int n_runs;
    double *data3;
    double *data4;
    double old_value;
    double output[4];
    
    //Design strategy
    //------------------------------------------------------
    //- I think we should optimize for NaNs not being present
    //which is my most common use case ...
    
    
    //Simple approach, nothing fancy ...
    //--------------------------------------------
    if (option == 1){
       for (mwSize i = 0; i < n_cols; i++){
            data2 = data + i*n_rows;
            for (mwSize j = 0; j < n_rows; j++){
                if (*data2 != *data2){
                    pl[i] = true;
                    break;   
                }
                ++data2;
            }
        }    
        return;
    }
    
    //Dummy variable at the end
    //--------------------------------------------
    if (option == 2){
       for (mwSize i = 0; i < n_cols; i++){
            data2 = data + i*n_rows;
            data3 = data2 + n_rows - 1;
            old_value = *data3;
            *data3 = 0.0/0.0;
            while (*data2 == *data2){
                ++data2;
            }
            *data3 = old_value;
            if (data2 == data3){
                pl[i] = old_value != old_value;
            }else{
               pl[i] = true; 
            }
        } 
        return;
    }
    
    //Simple approach when small - SIMD when large
    //-------------------------------------------------
    if (option == 3){
        if (n_rows < 100){  
            for (mwSize i = 0; i < n_cols; i++){
                data2 = data + i*n_rows;
                data3 = data2 + n_rows - 1;
                old_value = *data3;
                *data3 = 0.0/0.0;
                while (*data2 != *data2){
                    ++data2;
                }
                *data3 = old_value;
                if (data2 == data3){
                    pl[i] = old_value != old_value;
                }else{
                   pl[i] = true; 
                }
            }
        }else{
            n_runs = n_rows/8;
            for (mwSize i = 0; i < n_cols; i++){
                data2 = data + i*n_rows;
                data4 = data2 + n_runs*8;

                //Set sentinel
                old_value = *(data4-1);
                *(data4-1) = 0.0/0.0;
                temp = 0;

                while (temp == 0){
                    a = _mm256_loadu_pd(data2);
                    b = _mm256_loadu_pd(data2+4);
                    c = _mm256_cmp_pd(a, b, _CMP_UNORD_Q);
                    temp = _mm256_movemask_pd(c);
                    data2+=8;
                }

                //reset value
                *(data4-1) = old_value;
                if (data4 == data2){
                    //mexPrintf("-------%d\n",i);
                    //mexPrintf("%g\n",old_value);
                    //mexPrintf("%g\n",*(data4-1));
                    //TODO: process the remainder ...
                    a = _mm256_loadu_pd(data2-8);
                    b = _mm256_loadu_pd(data2-4);
                    c = _mm256_cmp_pd(a, b, _CMP_UNORD_Q);
                    temp = _mm256_movemask_pd(c);
                    //mexPrintf("%d\n",temp);
                    pl[i] = temp > 0; 
                }else{
                   pl[i] = true; 
                }
            }
        }
        return;
    }
    
    
    if (option == 4){
       for (mwSize i = 0; i < n_cols; i++){
            data2 = data + i*n_rows;
            temp = 0;
            for (mwSize j = 0; j < n_rows; j++){
                temp += (*data2 != *data2);
                ++data2;
            }
            pl[i] = temp != 0;
        }    
        
        return;
    }
    
    if (option == 6){
       for (mwSize i = 0; i < n_cols; i++){
            data2 = data + i*n_rows;
            temp = 0;
            for (mwSize j = 0; j < n_rows; j++){
                temp |= (*data2 != *data2);
                ++data2;
            }
            pl[i] = temp != 0;
        }    
        return;
    }
    
    if (option == 7){
        
       a = _mm256_set1_pd(0);
       for (mwSize i = 0; i < n_rows; i+=4){
            b = _mm256_loadu_pd(data+i);
            a = _mm256_add_pd(a,b);
       }
       _mm256_store_pd(output,a);
       for (int i = 0; i < 4; i++){
          if (output[i] != output[i]){
              pl[0] = true;
              break;
          }
       }
       return;
    }
    
    if (option == 8){
        temp = 0;
       for (mwSize i = 0; i < n_rows; i+=16){
            temp |= any_nan_block(data+i);  
       }
        pl[0] = temp > 0;
        return;
    }
    
    if (option == 5){
        if (n_rows < 100){  
            for (mwSize i = 0; i < n_cols; i++){
                data2 = data + i*n_rows;
                data3 = data2 + n_rows - 1;
                old_value = *data3;
                *data3 = 0.0/0.0;
                while (*data2 != *data2){
                    ++data2;
                }
                *data3 = old_value;
                if (data2 == data3){
                    pl[i] = old_value != old_value;
                }else{
                   pl[i] = true; 
                }
            }
        }else{
            n_runs = n_rows/8;
            for (mwSize i = 0; i < n_cols; i++){
                data2 = data + i*n_rows;  //1
                data4 = data2 + n_runs*8; //9

                //Set sentinel
                old_value = *(data4-1);
                *(data4-1) = 0.0/0.0;
                temp = 0;

                for (data2; data2 <= data4; data2+=8){
                    a = _mm256_loadu_pd(data2);
                    b = _mm256_loadu_pd(data2+4);
                    c = _mm256_cmp_pd(a, b, _CMP_UNORD_Q);
                    //temp = temp | _mm256_movemask_pd(c);
                    temp += _mm256_movemask_pd(c);
                }

                
                
                //reset value
                *(data4-1) = old_value;
                if (data4 == data2){
                    mexPrintf("-------%d\n",i);
                    mexPrintf("%g\n",old_value);
                    mexPrintf("%g\n",*(data4-1));
                    //TODO: process the remainder ...
                    a = _mm256_loadu_pd(data2-8);
                    b = _mm256_loadu_pd(data2-4);
                    c = _mm256_cmp_pd(a, b, _CMP_UNORD_Q);
                    temp = _mm256_movemask_pd(c);
                    mexPrintf("%d\n",temp);
                    pl[i] = temp > 0; 
                }else{
                   pl[i] = temp > 0; 
                }
            }
        }
        return;
    }

    
       //#1 - j as an iterator
       //--------------------------------------
//     for (mwSize i = 0; i < n_cols; i++){
//         data2 = data + + i*n_rows;
//         for (mwSize j = 0; j < n_rows-8; j+=8){
//                 a = _mm256_loadu_pd(data2);
//                 b = _mm256_loadu_pd(data2+4);
//                 c = _mm256_cmp_pd(a, b, _CMP_UNORD_Q);
//                 temp = temp | _mm256_movemask_pd(c);
//                         
//             data2+=8;
//         }
//         pl[i] = temp != 0;
//     }

     //#2 - iterating over a pointer
            //--------------------------------------
//     for (mwSize i = 0; i < n_cols; i++){
//         data3 = data + i*n_rows;
//         for (data2 = data3; data2 < data3 + n_rows-8; data2+=8){ 
//                 a = _mm256_loadu_pd(data2);
//                 b = _mm256_loadu_pd(data2+4);
//                 c = _mm256_cmp_pd(a, b, _CMP_UNORD_Q);
//                 temp = temp | _mm256_movemask_pd(c);
//         }
//         pl[i] = temp != 0;
//     }
    
    //TODO: Need to handle small rows ...
    

//     //#3 - stop at match ...
//     for (mwSize i = 0; i < n_cols; i++){
//         data2 = data + i*n_rows;
//         data4 = data2 + n_runs*8;
//         
//         //Set sentinel
//         old_value = *(data4-1);
//         *(data4-1) = 0.0/0.0;
//         temp = 0;
//         
//         while (temp == 0){
//             a = _mm256_loadu_pd(data2);
//             b = _mm256_loadu_pd(data2+4);
//             c = _mm256_cmp_pd(a, b, _CMP_UNORD_Q);
//             temp = _mm256_movemask_pd(c);
//             data2+=8;
//         }
//         
//         //reset value
//         *(data4-1) = old_value;
//         if (data4 == data2){
//             //mexPrintf("-------%d\n",i);
//             //mexPrintf("%g\n",old_value);
//             //mexPrintf("%g\n",*(data4-1));
//             //TODO: process the remainder ...
//             a = _mm256_loadu_pd(data2-8);
//             b = _mm256_loadu_pd(data2-4);
//             c = _mm256_cmp_pd(a, b, _CMP_UNORD_Q);
//             temp = _mm256_movemask_pd(c);
//             //mexPrintf("%d\n",temp);
//             pl[i] = temp > 0; 
//         }else{
//            pl[i] = true; 
//         }
//     }
    
    
    
    
    
    
    //mexPrintf("Testing\n");
    
    //TODO: Handle the end ...
    
    
    
    
    //_CMP_NEQ_UQ //not-equal
    
    //__m256d _mm256_loadu_pd
    
    //__m256d c = _mm256_and_pd(b, _mm256_cmp_pd(zero, a, _CMP_EQ_UQ));
    
    // _CMP_EQ_UQ    0x08 /* Equal (unordered, non-signaling)
    //
    //https://stackoverflow.com/questions/8627331/what-does-ordered-unordered-comparison-mean
    //
    //  unordered will fine NaNs - either could be NaN

    //_mm256_cmp_pd(__m256d m1, __m256d m2, const int predicate);
        
}