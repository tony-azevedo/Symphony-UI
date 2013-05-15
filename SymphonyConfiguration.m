% This class can be configured in your symphonyrc function. Do not modify this file directly.

classdef SymphonyConfiguration < handle
    
    properties
        % Directory containing rig configurations.
        % Rig configuration .m files must be at the top level of this directory.
        rigConfigsDir
        
        % Directory containing protocols.
        % Each protocol .m file must be contained within a directory of the same name as the protocol class itself.
        protocolsDir
        
        % Directory containing figure handlers (built-in figure handlers are always available).
        % Figure handler .m files must be at the top level of this directory.
        figureHandlersDir
        
        % Text file specifying the source hierarchy.
        sourcesFile
        
        % Factory that defines the creation of the DAQController used by Symphony.
        daqControllerFactory
        
        % Factory that defines the creation of the EpochPersistor used by Symphony.
        epochPersistorFactory
    end
    
end

