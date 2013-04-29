classdef IOData < Symphony.Core.IIOData
   
    properties
        Data
        SampleRate
        Duration
        Time
    end
    
    methods
        
        function obj = IOData(data, sampleRate)            
            obj.Data = data;
            obj.SampleRate = sampleRate;
            obj.Duration = System.TimeSpan.FromSeconds(obj.Data.Count / obj.SampleRate.Quantity);
        end
        
    end
    
end