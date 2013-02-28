function addPetriLabFolders()
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);  
    addpath(fullfile(parentDir, 'Rig_Configurations'));
    clear symphonyPath parentDir
end