%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

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