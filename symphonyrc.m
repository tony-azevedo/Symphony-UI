% Place a copy of this file in your MATLAB user path. Edit the copied file to change your personal Symphony configuration.
% Run the userpath command at the MATLAB command line to determine your user path directory.

function config = symphonyrc(config)
    
    % Directory containing rig configurations.
    % Rig configuration .m files must be at the top level of this directory.
    config.rigConfigsDir = fullfile(fileparts(mfilename('fullpath')), 'Example Rig Configurations');
    
    % Directory containing protocols.
    % Each protocol .m file must be contained within a directory of the same name as the protocol class itself.
    config.protocolsDir = fullfile(fileparts(mfilename('fullpath')), 'Example Protocols');
    
    % Directory containing figure handlers (built-in figure handlers are always available).
    % Figure handler .m files must be at the top level of this directory.
    config.figureHandlersDir = '';
    
    % Text file specifying the source hierarchy.
    config.sourcesFile = fullfile(fileparts(mfilename('fullpath')), 'ExampleSourceHierarchy.txt');
        
    
    % Factories to define which DAQ controller and epoch persistor Symphony should use.
    % HekaDAQControllerFactory and EpochHDF5PersistorFactory are only supported on Windows.
    if ispc
        config.daqControllerFactory = HekaDAQControllerFactory();
        config.epochPersistorFactory = EpochHDF5PersistorFactory();
    else
        config.daqControllerFactory = SimulationDAQControllerFactory(@loopbackSimulation);
        config.epochPersistorFactory = EpochXMLPersistorFactory();
    end
end