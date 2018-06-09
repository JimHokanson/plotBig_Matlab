# Compiling 

Currently if you want to compile the code the best bet is to use compile2.m located at /+big_plot/private/

Instructions for executing can be found inside the file.

## Options ##

Options apply to reduce\_to\_width_mex.c which computes local min and max values. In many cases the code is memory limited, and maximizing compute options doesn't speed up execution time (your mileage may vary).

The two options are to parallelize within a thread (SIMD) and/or between threads (OPENMP). Both can be enabled if desired.

https://en.wikipedia.org/wiki/SIMD

https://en.wikipedia.org/wiki/OpenMP

