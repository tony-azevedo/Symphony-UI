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
            enumerable = System.Collections.Generic.Enumerable(@GetEnumerator);
            
            function enum = GetEnumerator()
                enum = System.Collections.Generic.Enumerator(@MoveNext);
                enum.State.local = obj.data;
                enum.State.index = System.TimeSpan.Zero();
                
                function b = MoveNext()
                    enum.Current = [];
                    local = enum.State.local;
                    index = enum.State.index;

                    isIndefinite = obj.duration == Symphony.Core.TimeSpanOption.Indefinite();

                    if index >= obj.duration && ~isIndefinite
                        b = false;
                        return;
                    end

                    if blockDuration <= obj.duration - index || isIndefinite
                        dur = blockDuration;
                    else
                        dur = obj.duration - index;
                    end

                    while (local.Duration < dur)
                        local = local.Concat(obj.data);
                    end

                    [head, rest] = local.SplitData(dur);
                    local = rest;

                    index = index + dur;

                    enum.Current = Symphony.Core.OutputData(head.Data, head.SampleRate, index >= obj.duration && ~isIndefinite);
                    enum.State.local = local;
                    enum.State.index = index;
                    b = true;
                end
            end
        end
                
        
        function d = Duration(obj) % TimeSpanOption
            d = obj.duration;
        end
        
    end
    
end