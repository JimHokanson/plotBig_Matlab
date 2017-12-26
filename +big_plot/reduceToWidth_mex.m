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
%   See Also
%   --------
%   big_plot.reduceToWidth()

[a,b] = reduce_to_width_mex(varargin{:});

end