% Makes the given Symphony assembly visible to MATLAB. Assembly name should not include full path or extension.

function addSymphonyAssembly(assembly)
    if isDotNetSupported()
        addSymphonyNETAssembly(assembly);      
    else
        addSymphonyStubAssembly(assembly);
    end
end


function addSymphonyStubAssembly(assembly)
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    
    stubsDir = fullfile(parentDir, 'Stubs');
    
    assemblyDir = fullfile(stubsDir, ['+' strrep(assembly, '.', [filesep '+'])]);
    if ~exist(assemblyDir, 'dir')
        error(['''' assembly ''' could not be found as a Stub.']);
    end
    
    addpath(stubsDir);
end


function addSymphonyNETAssembly(assembly)
    isWin64bit = strcmpi(getenv('PROCESSOR_ARCHITEW6432'), 'amd64') || strcmpi(getenv('PROCESSOR_ARCHITECTURE'), 'amd64');

    if isWin64bit
        symphonyPath = fullfile(getenv('PROGRAMFILES(x86)'), 'Physion\Symphony\bin');
    else
        symphonyPath = fullfile(getenv('PROGRAMFILES'), 'Physion\Symphony\bin');
    end
    
    NET.addAssembly(fullfile(symphonyPath, [assembly '.dll']));
end