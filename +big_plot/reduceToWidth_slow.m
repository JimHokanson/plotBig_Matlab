function output = reduceToWidth_slow(data,samples_per_chunk,start_I,end_I)
%
%  
%   This code implements the same logic as the mex code but is about 10x
%   slower.
%
%
%   Example
%   -------
%   s = big_plot_tests.examples.e001_interestingInput('get_data_only',true);
%   y = s.y;
%   r1 = big_plot.reduceToWidth_slow(y,round(size(y,1)/10000),100,size(y,1)-10000);
%   
%   See Also
%   --------
%   big_plot.reduceToWidth
%   big_plot.reduceToWidth_mex


%{
%TODO: Make this a test ...
s = big_plot_tests.examples.e001_interestingInput('get_data_only',true);
y = s.y;
tic;
for i = 1:10
r1 = big_plot.reduceToWidth_slow(y,round(size(y,1)/10000),100,size(y,1)-10000);
end
toc/10
tic;
for i = 1:10
r2 = big_plot.reduceToWidth_mex(y,round(size(y,1)/10000),100,size(y,1)-10000);
end
toc/10

isequaln(r1,r2)
%}

use_subset = nargin == 4;
if ~use_subset
    cur_start_I = 1;
    end_I = size(data,1);
end

n_samples = end_I - start_I + 1;
n_chans = size(data,2);
n_chunks = floor(n_samples/samples_per_chunk);
extra_samples = n_samples - n_chunks*samples_per_chunk;
n_samples_out = 2*n_chunks;
if extra_samples
    n_samples_out = n_samples_out + 2;
end
if use_subset
    n_samples_out = n_samples_out + 4;
end

output = zeros(n_samples_out,n_chans,'like',data);

cur_end_I = start_I-1;

%Add hardcoded edge values ...
%--------------------------------------------------------
if use_subset
    out_I = 2;
    if isa(data,'double') || isa(data,'single')
        output(1,:) = 0;
        output(2,:) = NaN;
        output(end-1,:) = NaN;
        output(end,:) = 0;
    else
        output(1,:) = 0;
        output(2,:) = 0;
        output(end-1,:) = 0;
        output(end,:) = 0;
    end
else
    out_I = 0;
end

for i = 1:n_chunks
    cur_start_I = cur_end_I + 1;
    cur_end_I = cur_start_I + samples_per_chunk - 1;
    min_val = min(data(cur_start_I:cur_end_I,:),[],1);
    max_val = max(data(cur_start_I:cur_end_I,:),[],1);
    out_I = out_I + 1;
    output(out_I,:) = min_val;
    out_I = out_I + 1;
    output(out_I,:) = max_val;
end

if extra_samples
    cur_start_I = start_I + n_chunks*samples_per_chunk;
    cur_end_I = end_I;
    min_val = min(data(cur_start_I:cur_end_I,:),[],1);
    max_val = max(data(cur_start_I:cur_end_I,:),[],1);
    out_I = out_I + 1;
    output(out_I,:) = min_val;
    out_I = out_I + 1;
    output(out_I,:) = max_val;
end


end