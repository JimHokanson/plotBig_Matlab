function e004_blog_post()

%{
    big_plot_tests.examples.e004_blog_post();
%}

%Time testing
%----------------
n_samples = 5e7;
data = rand(3e7,1);
start_sample = 1;
n_chunks = 10000;
samples_per_chunk = length(data)/n_chunks;


tic
min_max_data = zeros(n_chunks*2+2,1);
% min_max_data(1) = data(1);
% min_max_data(end) = data(end);
I = 0;
end_I = start_sample-1;

for i = 1:n_chunks
    start_I = end_I + 1;
    end_I = start_I + samples_per_chunk - 1;
    min_max_data(I+1) = max(data(start_I:end_I));
    min_max_data(I+2) = min(data(start_I:end_I));
    I = I + 2;
end
toc

tic
min_max_data2 = big_plot.reduceMex(data,samples_per_chunk);
toc

% %Generall
% tic
% for i = 1:10
% wtf = big_plot.reduceMex(data,7500);
% end
% toc 

figure(1)
cla
profile on
tic
n_plots = 20;
for i = 1:n_plots
cla
plotBig(data);
drawnow;
end
fprintf('Average elapsed time: %g\n',toc/n_plots);
profile off
profile viewer

keyboard

%% Figure 1
y = [1 2 3 4 5 6 7 8 9 8 7 6 7 6 5 4 3 2 4 8 9 7 4 5 6 7 7 7 7 7];
subplot(1,2,1)
plot(y,'Linewidth',2)
set(gca,'FontSize',16)
subplot(1,2,2)
plot(y,'Linewidth',2)
set(gca,'xlim',[-1e6 1e6],'FontSize',16)
set(gcf,'position',[1,1,800,400]);

%% Figure 2
%Jim
figure(1)
s1 = big_plot_tests.examples.e001_interestingInput('type',0);

%Matlab
figure(2)
s2 = big_plot_tests.examples.e001_interestingInput('type',2,'y',s1.y,'t',s1.t);

h_fig = figure(3);
clf;
ax1 = copyobj(s1.ax(1),h_fig);
ax2 = copyobj(s2.ax(2),h_fig);

ax1.Position = s1.ax(1).Position;
ax2.Position = s2.ax(2).Position;
set(gcf,'position',[1,1,800,400]);

%% Figure 3
y = [1 2 3 4 5 6 7 8 9 8 7 6 7 6 5 4 3 2 4 8 9 7 4 5 6 7 7 7 7 7];
subplot(1,2,1)
plot(y,'-o','Linewidth',2)
set(gca,'FontSize',16)
subplot(1,2,2)
plot(y,'-o','Linewidth',2)
set(gca,'xlim',[-1e6 1e6],'FontSize',16)
set(gcf,'position',[1,1,800,400]);

end