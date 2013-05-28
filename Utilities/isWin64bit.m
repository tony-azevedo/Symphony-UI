function tf = isWin64bit()
    tf = strcmpi(getenv('PROCESSOR_ARCHITEW6432'), 'amd64') || strcmpi(getenv('PROCESSOR_ARCHITECTURE'), 'amd64');
end

