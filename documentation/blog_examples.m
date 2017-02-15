function blog_examples()

t = linspace(0,5,1e8);
y = sin(2*pi*0.5*t);
y = y + sin(2*pi*100*t);

%-------------------------------------------------------------
figure(1)
subplot(1,2,1)
tic
plot(t,y)
drawnow;
t1 = toc;
subplot(1,2,2)
tic;
plotBig(t,y)
drawnow;
t2 = toc;
fprintf('%0.3f, %0.3f, %0.3f\n',t1,t2,t1/t2)

%-------------------------------------------------------------
figure(2)
x_range = [1 1.05];
x_range = [0 0.05];
subplot(1,3,1)
tic;
plot(t,y)
drawnow;
set(gca,'xlim',x_range);
drawnow;
t1 = toc;
subplot(1,3,2)
[xr,yr] = big_plot.reduceToWidth(t',y',1000,[0 5]);
plot(xr,yr);
set(gca,'xlim',x_range);
drawnow;
subplot(1,3,3)
tic;
reduce_plot(t,y);
drawnow;
set(gca,'xlim',x_range);
drawnow;
t3 = toc;

tic;
plotBig(y','dt',t(2)-t(1),'t0',t(1));
drawnow;
set(gca,'xlim',x_range);
drawnow;
t2 = toc;
fprintf('%0.3f, %0.3f, %0.3f, %0.3f %0.3f\n',t1,t2,t3,t1/t2,t3/t2)

%---------------------------

fhs = {@plot @reduce_plot @plotBig};
tocs = zeros(1,3);
ax = zeros(1,4);
figure(3)
clf
for i = 1:3
    fh = fhs{i};
    for j = 1:4
    ax(j) = subplot(4,1,j);
    fh(t,y);
    end

    linkaxes(ax,'x')
    
    %I think what I want is not a setting of the limits
    %but rather a fake "user zoom" since this causes the
    %oscillating behavior ...
    
tic;
set(ax(2),'xlim',[0 2]);
drawnow;
set(ax(2),'xlim',[2 4]);
drawnow;
set(ax(2),'xlim',[4 5]);
drawnow;
tocs(i) = toc;
end

fprintf('%0.3f, %0.3f, %0.3f, %0.3f %0.3f\n',tocs(1),tocs(2),tocs(3),tocs(1)/tocs(3),tocs(2)/tocs(3))


end