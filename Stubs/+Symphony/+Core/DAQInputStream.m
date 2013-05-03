classdef DAQInputStream < Symphony.Core.IDAQInputStream
   
    properties
        Configuration
        SampleRate
        MeasurementConversionTarget
        Clock
    end
    
    properties (SetAccess = private)
        Name
        Active
        Devices
    end
    
    methods
        
        function obj = DAQInputStream(name)            
            obj.Devices = System.Collections.Generic.List();
            obj.Name = name;
        end
        
        
        function a = get.Active(obj)
            a = obj.Devices.Count > 0;
        end
        
        
        function PushInputData(obj, inData)
            for i = 0:obj.Devices.Count-1
                device = obj.Devices.Item(i);
                device.PushInputData(obj, inData);
            end
        end
        
    end
end