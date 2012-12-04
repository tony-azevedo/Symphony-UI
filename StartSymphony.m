%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

% Clear the memory of all the variables and clear the command window
% NOTE: clear all and clear classes will remove breakpoints. Therefore
% comment out if debugging
close all
clear all classes *
clc

Application = 'Symphony UI'  %#ok<NOPTS,NASGU>
clear Application

if verLessThan('matlab', '7.12')
    error('Symphony requires MATLAB 7.12.0 (R2011a) or later');
end

% Add our utility and figure handler folders to the search path.
symphonyPath = mfilename('fullpath');
parentDir = fileparts(symphonyPath);

addpath(fullfile(parentDir, 'Utility'));
addpath(fullfile(parentDir, 'Rig_Configurations'));
addpath(fullfile(parentDir, 'Figure Handlers'));
addpath(fullfile(parentDir, 'StimGL'));

if isempty(which('NET.convertArray'))
    addpath(fullfile(parentDir, filesep, 'Stubs'));
else
    symphonyPath = 'C:\Program Files\Physion\Symphony\bin';

    % Add Symphony.Core assemblies
    NET.addAssembly(fullfile(symphonyPath, 'Symphony.Core.dll'));
    NET.addAssembly(fullfile(symphonyPath, 'Symphony.ExternalDevices.dll'));
    NET.addAssembly(fullfile(symphonyPath, 'HekaDAQInterface.dll'));
    NET.addAssembly(fullfile(symphonyPath, 'Symphony.SimulationDAQController.dll'));
    NET.addAssembly('System.Windows.Forms');
end

%clean up variables used in the StartSymphony script
clear symphonyPath parentDir

%Instantiate the Symphony Instance
symphonyInstance = Symphony.getInstance;  