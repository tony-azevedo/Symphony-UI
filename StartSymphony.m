% Wrapper script (NOT a function) to load the Symphony .NET assemblies correctly.

% Copyright (c) 2012 Howard Hughes Medical Institute.
% All rights reserved.
% Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
% http://license.janelia.org/license/jfrc_copyright_1_1.html
function StartSymphony( varargin )
narginchk(0,1);
    
    if nargin == 1 && islogical(varargin{1}) && varargin{1}
        close all
        clear all classes *
        clearvars -global
        clc
    end
    
    if verLessThan('matlab', '7.12')
        error('Symphony requires MATLAB 7.12.0 (R2011a) or later');
    end

    % Add base directories to the path.
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    addpath(fullfile(parentDir, 'Utility'));
    addpath(fullfile(parentDir, 'StimGL'));
    clear symphonyPath parentDir

    % Load the Symphony .NET framework
    addSymphonyFramework();
    
    SymphonyUI.getInstance;
end