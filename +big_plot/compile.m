function compile()

LIB_FILENAME = 'libgomp.a';

LIB_PATH = 'C:\TDM-GCC-64\lib\gcc\x86_64-w64-mingw32\5.1.0\libgomp.a';
CURRENT_FUNCTION_NAME = 'big_plot.compile';

package_path = fileparts(which(CURRENT_FUNCTION_NAME));
mex_path = fullfile(package_path, 'private');

mex_lib_path = fullfile(mex_path, LIB_FILENAME);
copyfile(LIB_PATH, mex_path);

cd(mex_path);

mex -O LDFLAGS="$LDFLAGS -fopenmp" CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx" reduce_to_width_mex.c -v libgomp.a

delete(mex_lib_path);



end

