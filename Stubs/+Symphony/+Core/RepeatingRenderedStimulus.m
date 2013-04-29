classdef RepeatingRenderedStimulus < handle
   
    properties
        StimulusID
        Units
        Parameters
    end
    
    properties (Access = private)
        data
        duration % TimeSpanOption
    end
        
    methods
        
        function obj = RepeatingRenderedStimulus(identifier, parameters, data, duration)
            obj = obj@handle();
            
            obj.StimulusID = identifier;
            obj.Units = Symphony.Core.Measurement.HomogenousBaseUnits(data.Data);
            obj.Parameters = parameters;
            
            obj.data = data;
            obj.duration = duration;
        end
        
        
        function enumerable = DataBlocks(obj, blockDuration)
            % HACK: Creating an enumerable/enumerator class "on the fly" to avoid creating a bunch of class files.
            enumerable.GetEnumerator = @()DataEnumerator(obj.data, obj.duration, blockDuration);
        end
                
        
        function d = Duration(obj) % TimeSpanOption
            d = obj.duration;
        end
        
    end
    
end

function enum = DataEnumerator(data, duration, blockDuration)
    enum.local = data;
    enum.index = System.TimeSpan.Zero();

    enum.Current = [];
    enum.MoveNext = @(e)MoveNext(e); 
    
    function [b, enum] = MoveNext(enum)
        enum.Current = [];
        
        isIndefinite = duration == Symphony.Core.TimeSpanOption.Indefinite();
        
        if enum.index >= duration && ~isIndefinite
            b = false;
            return;
        end
        
        if blockDuration <= duration - enum.index || isIndefinite
            dur = blockDuration;
        else
            dur = duration - enum.index;
        end

        while (enum.local.Duration < dur)
            enum.local = enum.local.Concat(data);
        end

        [head, rest] = enum.local.SplitData(dur);
        enum.local = rest;

        enum.index = enum.index + dur;

        enum.Current = Symphony.Core.OutputData(head.Data, head.SampleRate, enum.index >= duration && ~isIndefinite);
        b = true;
    end
end

