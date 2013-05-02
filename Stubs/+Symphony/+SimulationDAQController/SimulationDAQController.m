classdef SimulationDAQController < Symphony.Core.DAQControllerBase
   
    properties
        SampleRate
        SimulationRunner
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
        
        
        function now = Now(obj) %#ok<MANU>
            now = System.DateTimeOffset.Now;
        end
        
        
        function incomingData = ProcessLoopIteration(obj, outputData)
            incomingData = obj.SimulationRunner(outputData, obj.ProcessInterval);
        end        
        
        
        function AddStream(obj, stream)
            obj.Streams.Add(stream);
        end
        
    end
end