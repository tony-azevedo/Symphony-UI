classdef DAQOutputStream < Symphony.Core.IDAQOutputStream
    
    properties
        Device
        Configuration
        SampleRate
        MeasurementConversionTarget
        Clock
    end
    
    properties (SetAccess = private)
        HasMoreData
        Background
        Name
        Active
    end
    
    properties (Access = private)
        LastDataPulled
    end
    
    methods
        
        function obj = DAQOutputStream(name)            
            obj.Name = name;
            
            obj.LastDataPulled = false;
        end
        
        
        function outData = PullOutputData(obj, duration)
            outData = obj.Device.PullOutputData(obj, duration);
            
            if outData.IsLast
                obj.LastDataPulled = true;
            end
        end
        
        
        function h = get.HasMoreData(obj)
            h = obj.Active && ~obj.LastDataPulled;
        end
        
        
        function a = get.Active(obj)
            a = ~isempty(obj.Device);
        end
        
    end
    
end