function data = getSinWithNoise(n_samples,dt,sin_freq,data_type)
%X Generate example data for plot testing
%
%   data = big_plot.example_data.getSinWithNoise(n_samples,dt,sin_freq,data_type)
%
%   %No arguments gives default example
%   data = big_plot.example_data.getSinWithNoise
%
%   Inputs
%   ------
%   n_samples : scalar
%   dt : time between samples (seconds)
%   sin_freq : frequency of the sine wave (Hz)
%   data_type : currently limited to 'double' or 'single'
%   
%   Example
%   -------
%   fs = 1e5;
%   sin_freq = 1/60; %1 minute repeat
%   n_seconds_max = 900; %15 minutes of data
%   n_samples = n_seconds_max*fs + 1;
%   data = big_plot.example_data.getSinWithNoise(n_samples,1/fs,sin_freq,'double');
%
%   plotBig(data,'dt',1/fs)

if nargin == 0
   n_samples = 5e7;
   dt = 0.001;
   sin_freq = 0.0001;
   data_type = 'double';
end

if ~any(strcmp(data_type,{'single','double'}))
   error('Invalid data type, only single or double currently supported') 
end

data = zeros(n_samples,1,data_type);
noise_scale = 1/n_samples;
r = rand(1,1e5,data_type); %Our noise will repeat, this is just 
%to show that the line has dense data points when zooming in as it can
%be tough to see points in a smooth line.
    
%Loops saves memory since Matlab is poor at minimizing intermediate
%memory usage for vectors
c = 2*pi*sin_freq*dt;

%This is extremely slow ...
for i = 1:n_samples
    data(i) = sin(c*i);
end

%Now add noise
%TODO: Rewrite to process in chunks
I = 1e5;
for i = 1:n_samples
    %t = dt*(i-1);
    %noise_scale2 = noise_scale*i;
    if I == 1e5
        I = 1;
    else
        I = I + 1;
    end
    %I = mod(i,1e5) + 1;
    %r2 = r(I);
    data(i) = data(i) + noise_scale*i*r(I);
end

end