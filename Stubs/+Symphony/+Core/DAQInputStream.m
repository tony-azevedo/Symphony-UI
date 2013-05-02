classdef DAQInputStream < Symphony.Core.IDAQInputStream
   
    properties
        Configuration
        SampleRate
        Active
        MeasurementConversionTarget
        Clock
        Devices
        Name
    end
    
    methods
        
        function obj = DAQInputStream(name)            
            obj.Devices = System.Collections.Generic.List();
            obj.Name = name;
        end
        
        
        function b = get.Active(obj)
            b = obj.Devices.Count > 0;
        end
        
        
        function PushInputData(obj, inData)
            for i = 0:obj.Devices.Count-1
                dev = obj.Devices.Item(i);
                dev.PushInputData(obj, inData);
            end
        end
        
    end
end