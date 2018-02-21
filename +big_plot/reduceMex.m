function [min_max_data,x] = reduceMex(varargin)
%
%   Calling Forms
%   -------------
%   [min_max_data, x] = big_plot.reduceMex(data,samples_per_chunk);
%
%   [min_max_data, x] = big_plot.reduceMex(data,samples_per_chunk,start_sample,end_sample);
%
%   Normally this should not be called directly, since this functionality
%   is exposed in the plotting library. However, if you only want to find
%   the min and max values over chunks, this exposes the underlying private
%   mex function.
%
%   Inputs
%   ------
%   data : [samples x channels]
%   samples_per_chunk : scalar
%       # of samples per chunk over which to calculate min and max
%   start_sample :
%       If specified, the chunks are computed starting at this sample.
%   end_sample :
%       This must be specified when the start sample is specified. It
%       specifies the last sample to include in min/max processing.
%
%   Outputs
%   -------
%   min_max_data : 
%   x : 


%TODO: We need more error checking and corner cases testing
% Ideally the mex code would be doing this ...

min_max_data = reduce_to_width_mex(varargin{:});

if nargout == 2
    %Ideally this would be in the mex file for ensuring consistency
    if nargin == 4
        %ends and 
    elseif nargin == 2
        n_samples_in = length(varargin{1});
        n_samples_out = length(min_max_data);
        sample_width = varargin{2};
        x = zeros(n_samples_out,1);
        x(1:2:end) = linspace(1+floor(sample_width/2),n_samples_in-floor(sample_width/2),n_samples_out/2);
        x(2:2:end) = x(1:2:end);
    end
end

end