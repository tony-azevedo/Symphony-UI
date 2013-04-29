classdef DAQOutputStream < Symphony.Core.IDAQOutputStream
    
    properties
        Device
        HasMoreData
        Background
        Configuration
        Name
        SampleRate
        Active
        MeasurementConversionTarget
        Clock
    end
    
    methods
        
        function obj = DAQOutputStream(name)            
            obj.Name = name;
        end
        
        
        function d = PullOutputData(obj, duration)
            error('Needs to be implemented');            
        end
        
    end
    
end