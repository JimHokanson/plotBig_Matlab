function mex_makeReduce()


% //  setenv('MW_MINGW64_LOC','C:\TDM-GCC-64')
% //
% //  mex -O LDFLAGS="$LDFLAGS -fopenmp -static-libgcc -static-libstdc++"  CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx -static-libgcc -static-libstdc++" reduce_to_width_mex.c -v
% //
% //  mex -O LDFLAGS="$LDFLAGS -fopenmp"  CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx" reduce_to_width_mex.c -v libgomp.a
% //
% /*
%     //Compiling on my mac
%     //requires gcc setup, see turtle-json compiling notes
%     //TODO: Move a copy of those notes here ...
%     mex CC='/usr/local/Cellar/gcc6/6.1.0/bin/gcc-6' COPTIMFLAGS="-O3 -DNDEBUG"  CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx" LDFLAGS="$LDFLAGS -fopenmp" COPTIMFLAGS="-O3 -DNDEBUG" -O reduce_to_width_mex.c  
%  */




end


