function flag = anyNANs(x_data,option)
%
%   flag = big_plot.anyNANs(x_data)
%      

%{
d = zeros(1e8,1);
d(1) = NaN;
d(1,:) = NaN;
d(2,:) = NaN;
d(3,:) = NaN;
d(4,:) = NaN;

d(20,:) = NaN;

d(100,:) = NaN;

d(1e7,:) = NaN;

N1 = 20;
N2 = 10;
tic;
for i = 1:N1
    wtf1 = big_plot.anyNANs(d,1);
end
s1 = toc/N1

tic;
for i = 1:N1
    wtf7 = big_plot.anyNANs(d,7);
end
s7 = toc/N1


tic;
for i = 1:N1
    wtf8 = big_plot.anyNANs(d,8);
end
s8 = toc/N1

%0.16
tic;
for i = 1:N1
    wtf4 = big_plot.anyNANs(d,4);
end
s4 = toc/N1

tic;
for i = 1:N1
    wtf6 = big_plot.anyNANs(d,6);
end
s6 = toc/N1 
  
tic;
for i = 1:N1
    wtf5 = big_plot.anyNANs(d,5);
end
s5 = toc/N1 


tic;
for i = 1:N1
    wtf9 = big_plot.reduceToWidth_mex(d,1e8);
end
s9 = toc/N1 




tic;
for i = 1:N2
    wtf2 = any(isnan(d));
end
s0 = toc/N2

s0/min([s1 s2 s3])

tic;
for i = 1:N2
min_max_data = big_plot.reduceToWidth_mex(d,10000,1,size(d,1));
end
s6 = toc/N2


%}

    
    if isa(x_data,'double')
        if nargin == 1
            flag = nan_check_mex(x_data);
        else
            flag = nan_check_mex(x_data,option);
        end
    elseif isa(x_data,'single')
        %TODO: We could mex this as wells
        flag = any(isnan(x_data));
    else
        flag = false(1,size(x_data,2));
    end

end