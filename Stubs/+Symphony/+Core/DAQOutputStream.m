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
    
    properties
        lastDataPulled
    end
    
    methods
        
        function obj = DAQOutputStream(name)            
            obj.Name = name;
            
            obj.lastDataPulled = false;
        end
        
        
        function d = PullOutputData(obj, duration)
            d = obj.Device.PullOutputData(obj, duration);
            
            if d.IsLast
                obj.lastDataPulled = true;
            end
        end
        
        
        function b = get.HasMoreData(obj)
            b = obj.Active && ~obj.lastDataPulled;
        end
        
        
        function b = get.Active(obj)
            b = ~isempty(obj.Device);
        end
        
    end
    
end