function [min_max_data,x] = reduceMex(varargin)
%
%   big_plot.reduceMex
%
%   min_max_data = big_plot.reduceMex(data,samples_per_chunk);
%
%   min_max_data = big_plot.reduceMex(data,samples_per_chunk,*start_sample,*end_sample);
%
%   TODO: Describe inputs

%TODO: We need more error checking and corner cases testing

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