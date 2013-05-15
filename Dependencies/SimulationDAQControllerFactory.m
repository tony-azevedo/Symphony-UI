classdef SimulationDAQControllerFactory < DAQControllerFactory
    
    properties
        simulation
    end
    
    methods
        
        function obj = SimulationDAQControllerFactory(simulation)
            obj.simulation = simulation;
        end
        
        
        function daq = createDAQ(obj)
            import Symphony.SimulationDAQController.*;
            import Symphony.Core.*;
            
            Converters.Register(Measurement.UNITLESS, 'V', @(m) m);
            
            daq = SimulationDAQController();
            
            constructor = str2func(obj.simulation);
            sim = constructor();
            sim.daqController = daq;
            
            daq.SimulationRunner = @(input,timeStep)sim.runner(input, timeStep);
        end
            
    end
    
end

