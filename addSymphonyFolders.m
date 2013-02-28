function addSymphonyFolders()
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);

    addpath(parentDir);
    addpath(fullfile(parentDir, 'Utility'));
    addpath(fullfile(parentDir, 'Figure Handlers'));
    addpath(fullfile(parentDir, 'StimGL'));
    clear symphonyPath parentDir
end
