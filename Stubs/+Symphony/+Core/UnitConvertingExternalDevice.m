classdef UnitConvertingExternalDevice < Symphony.Core.ExternalDeviceBase
   
    properties
        MeasurementConversionTarget
    end
    
    methods
        
        function obj = UnitConvertingExternalDevice(name, manufacturer, controller, background)
            obj = obj@Symphony.Core.ExternalDeviceBase(name, manufacturer, controller, background);
        end
               
        
        function d = PullOutputData(obj, stream, duration)
            d = obj.Controller.PullOutputData(obj, duration);
        end
        
        
        function PushInputData(obj, stream, inData)
            obj.Controller.PushInputData(obj, inData);
        end
        
    end
end