function e004_blog_post()

%{
    big_plot_tests.examples.e004_blog_post();
%}

%Time Notes - for my macbook
%--------------------------
%1) ML Loop         - 0.243
%2) OpenMP and SIMD - 0.011  - Ratio 21.4
%3) SIMD Only       - 0.0197 - Ratio 12.3
%4) OpenMP Only     - 0.0351 - Ratio 6.86
%5) C Only          - 0.0635 - Ratio 3.84

%Time Notes - for my desktop
%----------------------------
%1) ML Loop         - 0.111
%2) OpenMP and SIMD - 0.0133 - Ratio 8.4
%3) SIMD Only       - 0.0156 - Ratio 6.9
%4) OpenMP Only     - 0.0147 - Ratio 7.54
%5) C Only          - 0.0279 - Ratio 3.92

%Time Notes - for my other desktop
%-----------------------------------
%1) ML Loop         - 0.100
%2) OpenMP and SIMD - 0.0140 - Ratio 7.19
%3) SIMD Only       - 0.0220 - Ratio 4.54
%4) OpenMP Only     - 0.0142 - Ratio 6.95
%5) C Only          - 0.0295 - Ratio 3.37


%Single other desktop
%- 0.076
%- 0.0076 - 10.093
%- 0.0080 - 9.35 SIMD only

%Time testing
%----------------
n_samples = 3e7;
data = rand(n_samples,1);
start_sample = 1;
n_chunks = 10000;
samples_per_chunk = length(data)/n_chunks;
n_loops = 40;

tic
for j = 1:n_loops
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
end
t1 = toc;
fprintf('Average elapsed time (Matlab std): %g\n',t1/n_loops);


tic
for j = 1:n_loops
min_max_data2 = big_plot.reduceMex(data,samples_per_chunk);
end
t2 = toc;
fprintf('Average elapsed time (mex): %g\n',t2/n_loops);

fprintf('Speed ratio %g\n',t1/t2);

% %Generall
% tic
% for i = 1:10
% wtf = big_plot.reduceMex(data,7500);
% end
% toc 

% figure(1)
% cla
% profile on
% tic
% n_plots = 20;
% for i = 1:n_plots
% cla
% plotBig(data);
% drawnow;
% end
% t3 = toc;
% fprintf('Average elapsed time: %g\n',t3/n_plots);
% profile off
% profile viewer

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