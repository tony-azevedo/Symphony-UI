% Returns a function handle for the named function at the given path (convenient for bypassing the MATLAB global path).

function handle = funcAtPath(functionName, path)

    file = fullfile(path, functionName);
    if exist(file, 'file') ~= 2
        error([file ' does not exist']);
    end

    currentDir = pwd;
    cd(path);
    handle = str2func(functionName);
    cd(currentDir);
end

