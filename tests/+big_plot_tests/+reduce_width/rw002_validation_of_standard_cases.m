function rw002_validation_of_standard_cases()
%
%   big_plot_tests.reduce_width.rw002_validation_of_standard_cases
%
%   Tests
%   -----
%   - full array parsing only (not subsets)
%   - all data types
%   - reasonable lengths to encounter edge cases in the code
%   - still need to cover:
%       - the non-mex code
%       - subsets
%
%   TODO: Add multi-channel testing ...

data_types = {'double','single','uint32','uint16','uint8','int32','int16','int8'};

data_lengths = [0:100 200 400 800 1200];


for i = 1:length(data_types)
    cur_data_type = data_types{i};
    fprintf('Processing %s\n',cur_data_type);
    fh = str2func(cur_data_type);
    for j = 1:length(data_lengths)
        cur_length = data_lengths(j);
        for c = 1:cur_length+1
            for k = 1:7
                if k == 1 || k == 5
                    y = 1:cur_length;
                elseif k == 2 || k == 6
                    y = cur_length:-1:1;
                elseif k == 3 || k == 7
                    y = [1:cur_length-1 cur_length:-1:1];
                elseif k == 4 || k == 8
                    y = [cur_length:-1:2 1:cur_length];
                end
                
                if k > 4
                    y(k-3:4:end) = NaN; 
                end
                
                y = fh(y');
                %fprintf('c = %d, y = :',c);
                %disp(y);
                [min_max_data,type] = big_plot.reduceToWidth_mex(y,c);
                h__manualVerification(y,min_max_data,c,false)
                
                if length(y) > 3
                [min_max_data,type] = big_plot.reduceToWidth_mex(y,c,2,length(y)-1);
                h__manualVerification(y,min_max_data,c,true,2,length(y)-1)
                end
                
            end
        end
    end
end

end

function h__manualVerification(y1,y2,c,add_edges,s1,s2)
%
%   y1 - input
%   y2 - output

%TODO: replace parts with big_plot.reduceToWidth_slow

if isempty(y1)
    if isempty(y2)
        %good
    else
        error('Output empty for empty input')
    end
    return
end

if add_edges
    y1 = y1(s1:s2);
end

n_chunks = floor(length(y1)/c);
extra_samples = length(y1) - n_chunks*c;
n_samples_out = 2*n_chunks;
if extra_samples
    n_samples_out = n_samples_out + 2;
end

if add_edges
    n_samples_out = n_samples_out + 4;
end
y3 = zeros(n_samples_out,1);


end_I = 0;

if add_edges
    I = 2;
    if isa(y1,'double') || isa(y1,'single')
        y3(1:2) = [0 NaN];
        y3(end-1:end) = [NaN 0];
    else
        y3(1:2) = [0 0];
        y3(end-1:end) = [0 0];
    end
else
    I = 0;
end

for i = 1:n_chunks
    start_I = end_I + 1;
    end_I = start_I + c - 1;
    min_val = min(y1(start_I:end_I));
    max_val = max(y1(start_I:end_I));
    I = I + 1;
    y3(I) = min_val;
    I = I + 1;
    y3(I) = max_val;
end

if extra_samples
    start_I = length(y1) - extra_samples + 1;
    end_I = length(y1);
    min_val = min(y1(start_I:end_I));
    max_val = max(y1(start_I:end_I));
    I = I + 1;
    y3(I) = min_val;
    I = I + 1;
    y3(I) = max_val;
end

if ~isequaln(y2,y3)
    error('Mismatch in values')
end


end