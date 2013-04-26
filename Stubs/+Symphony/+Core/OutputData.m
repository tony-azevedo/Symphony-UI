%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef OutputData < Symphony.Core.IOData
   
    properties
        IsLast
    end
    
    methods
        
        function obj = OutputData(data, sampleRate, isLast)
            obj = obj@Symphony.Core.IOData(data, sampleRate);
            
            if nargin > 2
                obj.IsLast = isLast;
            else
                obj.IsLast = true;
            end
        end
        
        
        function [head, rest] = SplitData(obj, duration)
            if duration.Ticks == 0
                requestedSamples = 0;
            else
                requestedSamples = ceil(duration.TotalSeconds * obj.SampleRate.QuantityInBaseUnit);
            end
            
            numSamples = min(requestedSamples, obj.Data.Count);
            
            headData = obj.Data.Take(numSamples);
            restData = obj.Data.Skip(numSamples).Take(obj.Data.Count - numSamples);
            
            head = Symphony.Core.OutputData(headData, obj.SampleRate, obj.IsLast);
            rest = Symphony.Core.OutputData(restData, obj.SampleRate, obj.IsLast);
        end
        
        
        function d = Concat(obj, other)
            if ~isequal(obj.SampleRate, other.SampleRate)
                error('Sample rate mismatch');
            end
            
            d = Symphony.Core.OutputData(obj.Data.Concat(other.Data), obj.SampleRate, obj.IsLast || other.IsLast);
        end
        
    end
    
end