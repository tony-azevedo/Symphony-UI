%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

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
            enumerable.GetEnumerator = @()obj.GetDataEnumerator(blockDuration);
        end
                
        
        function d = Duration(obj) % TimeSpanOption
            d = obj.duration;
        end
        
    end
    
    methods (Access = private)
        
        function e = GetDataEnumerator(obj, blockDuration)
            e.local = obj.data;
            e.index = System.TimeSpan.Zero();
            
            e.Current = [];
            e.MoveNext = @()NextDataBlock(obj, e, blockDuration);
        end
        
        
        function [b, enum] = NextDataBlock(obj, enum, blockDuration)
            enum.Current = [];
            
            isIndefinite = obj.Duration == Symphony.Core.TimeSpanOption.Indefinite();
            
            if enum.index > obj.Duration.Item2 && ~isIndefinite
                b = false;
                return;
            end
            
            if blockDuration <= obj.Duration - enum.index || isIndefinite
                dur = blockDuration;
            else
                dur = obj.Duration - enum.index;
            end
            
            while (enum.local.Duration < dur)
                enum.local = enum.local.Concat(obj.data);
            end
            
            [head, rest] = enum.local.SplitData(dur);
            enum.local = rest;
            
            enum.index = enum.index + dur;
            
            enum.Current = Symphony.Core.OutputData(head.Data, head.SampleRate, enum.index >= obj.Duration && ~isIndefinite);
            b = true;
        end
        
    end
    
end