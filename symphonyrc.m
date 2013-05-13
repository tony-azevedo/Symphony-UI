function config = symphonyrc(config)
    
    config.rigConfigsDir = fullfile(fileparts(mfilename('fullpath')), 'Example Rig Configurations');
    config.protocolsDir = fullfile(fileparts(mfilename('fullpath')), 'Example Protocols');
    config.figureHandlersDir = '';
    config.sourcesFile = fullfile(fileparts(mfilename('fullpath')), 'ExampleSourceHierarchy.txt');
        
    if ispc
        config.daqControllerFactory = HekaDAQControllerFactory();
        config.epochPersistorFactory = EpochHDF5PersistorFactory();
    else
        config.daqControllerFactory = SimulationDAQControllerFactory(@loopbackSimulation);
        config.epochPersistorFactory = EpochXMLPersistorFactory();
    end
end