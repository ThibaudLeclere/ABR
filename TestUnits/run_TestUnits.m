% Run test units
[path, currentFile] = fileparts(mfilename('fullpath'));
cd(path)

% List of the test unit scripts
testList = what(path);
for i = 1:length(testList.m)
    testUnit = erase(testList.m{i}, '.m');
    if ~strcmp(testUnit, currentFile)
        testResult = runtests(testList.m{i});
        disp(testResult)
    end    
end