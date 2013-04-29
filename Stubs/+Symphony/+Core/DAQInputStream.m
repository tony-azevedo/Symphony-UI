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
            obj.Devices = GenericList();
            obj.Name = name;
        end
        
    end
end