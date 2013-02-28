function StartSymphony( varargin )
    narginchk(0,1);   
    
    if nargin == 1 && islogical(varargin{1}) && varargin{1}
        close all
        clear all classes *
        clearvars -global
        clc        
    end
    
    Application = 'Symphony UI'  %#ok<NOPTS,NASGU>
    clear Application

    if verLessThan('matlab', '7.12')
        error('Symphony requires MATLAB 7.12.0 (R2011a) or later');
    end

    addPetriLabFolders();
    addSymphonyFolders();
    addSymphonyFramework();

    %Instantiate the Symphony Instance
    symphonyInstance = PetriSymphony.getInstance;   %#ok<NASGU>
end