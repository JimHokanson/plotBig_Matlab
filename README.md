# Introduction

Code written to allow plotting large amounts of data quickly in Matlab

# Example Code

```Matlab
n = 1e8;
t = linspace(0,1,n);
y = sin(25*(2*pi).*t) + t.*rand(1,n);

y = y';

%Normal plotting, try resizing ...
plot(t,y)

plotBig(y,'dt',t(2)-t(1));
```

# Approach

JAH TODO