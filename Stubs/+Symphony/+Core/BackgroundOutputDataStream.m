classdef BackgroundOutputDataStream < Symphony.Core.IOutputDataStream
    
    properties (SetAccess = private)
        Duration
        Position
        SampleRate
        IsAtEnd
    end
    
    properties (Access = private)
        Background
    end
    
    methods

        function obj = BackgroundOutputDataStream(background, duration)
            if nargin == 1
                duration = Symphony.Core.TimeSpanOption.Indefinite;
            end
            
            obj.Background = background;
            obj.Duration = duration;
            obj.Position = System.TimeSpan.Zero;
        end
        
        
        function outData = PullOutputData(obj, duration)
            
            import Symphony.Core.*;
            
            if obj.Duration ~= TimeSpanOption.Indefinite && duration > obj.Duration - obj.Position
                dur = obj.Duration - obj.Position;
            else
                dur = duration;
            end
            
            nSamples = TimeSpanExtensions.Samples(dur, obj.SampleRate);
            value = obj.Background.Value;
            
            % Why is preallocating slowing this down?
            %list = NET.createGeneric('System.Collections.Generic.List', {'Symphony.Core.Measurement'}, samples);
            data = NET.createGeneric('System.Collections.Generic.List', {'Symphony.Core.Measurement'}, 0);
            
            % MATLAB constructors are slow, so we'll use the same measurement across the list.
            % I think this is OK because measurements are immutable.
            measurement = Measurement(value.QuantityInBaseUnit, value.BaseUnit);

            % This is significantly faster than using Add
            data.Items(1:nSamples) = measurement;
            data.ItemCount = nSamples;
            
            obj.Position = obj.Position + dur;
                        
            outData = OutputData(data, obj.SampleRate, obj.IsAtEnd);
        end       
        
        
        function r = get.SampleRate(obj)
            r = obj.Background.SampleRate;
        end
        
        
        function tf = get.IsAtEnd(obj)
            tf = obj.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && obj.Position >= obj.Duration;
        end
        
    end
    
end

