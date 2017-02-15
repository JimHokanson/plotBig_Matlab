function pb005_singleData()
%
%   big_plot_tests.previous_bugs.pb005_singleData
%

try
plotBig(1:1e7,single(1:1e7))
catch ME
    if ~strcmp(ME.identifier,'SL:reduce_to_width:input_class_type')
       error('An error was thrown, but it wasn''t the expected error'); 
    end
end

end