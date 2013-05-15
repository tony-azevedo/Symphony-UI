classdef SimulationDAQControllerFactory < DAQControllerFactory
    
    properties
        SimulationRunner
    end
    
    
    methods
        
        function obj = SimulationDAQControllerFactory(simulationRunner)
            obj.SimulationRunner = simulationRunner;
        end
        
        
        function daq = createDAQ(obj)
            import Symphony.SimulationDAQController.*;
            import Symphony.Core.*;
            
            Converters.Register(Measurement.UNITLESS, 'V', @(m) m);
            
            daq = SimulationDAQController();
            daq.SimulationRunner = obj.SimulationRunner;
        end
            
    end
    
end

