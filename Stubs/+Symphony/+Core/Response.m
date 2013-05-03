classdef Response < handle
   
    properties (SetAccess = private)
        Data
        DataSegments
        DataConfigurationSpans
        SampleRate
        InputTime
        Duration
    end
    
    methods
        
        function obj = Response()            
            obj.DataSegments = System.Collections.Generic.List();
            obj.DataConfigurationSpans = System.Collections.Generic.List();
            
            % TODO: This should be a getter and should return a DateTimeOffset
            obj.InputTime = now;
        end
        
        
        function AppendData(obj, data)
            obj.DataSegments.Add(data);
        end  
        
        
        function d = get.Data(obj)
            d = System.Collections.Generic.List();
            
            for i = 0:obj.DataSegments.Count-1
                d.AddRange(obj.DataSegments.Item(i).Data);
            end
        end
        
        
        function d = get.Duration(obj)
            d = System.TimeSpan.Zero();
            
            for i = 0:obj.DataSegments.Count-1
                d = d + obj.DataSegments.Item(i).Duration;
            end
        end
        
        
        function s = get.SampleRate(obj)
            s = obj.DataSegments.Item(0).SampleRate;
        end
        
    end
    
end