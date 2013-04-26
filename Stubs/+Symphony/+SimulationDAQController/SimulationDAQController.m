classdef SimulationDAQController < Symphony.Core.DAQControllerBase
   
    properties
        SampleRate
        SimulationRunner
    end
    
    methods
        
        function obj = SimulationDAQController(simulationTimeStep)
            obj = obj@Symphony.Core.DAQControllerBase();
            
            obj.ProcessInterval = simulationTimeStep;
        end
        
        
        function now = Now(obj) %#ok<MANU>
            now = System.DateTimeOffset.Now;
        end
        
        
        
    end
end