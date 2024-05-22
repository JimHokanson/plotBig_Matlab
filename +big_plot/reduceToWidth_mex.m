function [a,b] = reduceToWidth_mex(varargin)
%
%   In general this function should not be called directly. It is just for
%   testing.
%
%   min_max_data = big_plot.reduceToWidth_mex(data,samples_per_chunk,*start_sample,*end_sample);
%
%   This function provides public access to the underlying mex code that 
%   lives in the private folder.
%
%   This code bypasses some functionality that is provided by the main 
%   public function big_plot.reduceToWidth
%
%   Outputs
%   -------
%   a :
%       
%   b : 
%       Type of SIMD instruction used for the reduction. Depends on
%       computer processor AND the data type of the input data
%       - 0 - nothing
%       - 1 - SSE2
%       - 2 - SSE41
%       - 3 - AVX
%       - 4 - AVX2
%
%
%   See Also
%   --------
%   big_plot.reduceToWidth()

[a,b] = reduce_to_width_mex(varargin{:});

end