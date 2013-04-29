classdef InputData < Symphony.Core.IOData
   
    properties
        InputTime
    end
    
    methods
        
        function obj = InputData(data, sampleRate, inputTime)           
            obj = obj@Symphony.Core.IOData(data, sampleRate);
            
            obj.InputTime = inputTime;
        end
        
    end
    
end