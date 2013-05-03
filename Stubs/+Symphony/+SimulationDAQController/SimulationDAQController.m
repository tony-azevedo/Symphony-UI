classdef SimulationDAQController < Symphony.Core.DAQControllerBase & Symphony.Core.IClock
   
    properties
        SampleRate
        SimulationRunner
    end
    
    properties (SetAccess = private)
        Now
    end
    
    methods
        
        function obj = SimulationDAQController(simulationTimeStep)
            obj = obj@Symphony.Core.DAQControllerBase();
            
            if nargin < 1
                simulationTimeStep = System.TimeSpan.FromSeconds(0.5);
            end
            
            obj.ProcessInterval = simulationTimeStep;
            obj.Clock = obj;
        end
        
        
        function n = get.Now(obj) %#ok<MANU>
            n = System.DateTimeOffset.Now;
        end
        
        
        function incomingData = ProcessLoopIteration(obj, outputData)
            incomingData = obj.SimulationRunner(outputData, obj.ProcessInterval);
        end        
        
        
        function AddStream(obj, stream)
            obj.Streams.Add(stream);
        end
        
    end
end