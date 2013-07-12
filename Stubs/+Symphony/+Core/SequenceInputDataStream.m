classdef SequenceInputDataStream < Symphony.Core.IInputDataStream
    
    properties (SetAccess = private)
        SampleRate
        Duration
        Position
        IsAtEnd        
    end
    
    properties (Access = private)
        Streams
    end
    
    methods
        
        function obj = SequenceInputDataStream()
            obj.Streams = System.Collections.Queue();
        end
        
        
        function Add(obj, stream)
            obj.Streams.Enqueue(stream);
        end
        
        
        function tf = get.IsAtEnd(obj)
            tf = obj.Streams.Count == 0;
        end
        
        
        function PushInputData(obj, inData)
            
            unpushedData = inData;
            
            while unpushedData.Duration > System.TimeSpan.Zero
                stream = obj.Streams.Peek();

                if stream.Duration ~= TimeSpanOption.Indefinite
                    dur = stream.Duration - stream.Position;
                else
                    dur = unpushedData.Duration;
                end
                
                [head,rest] = unpushedData.SplitData(dur);
                
                stream.PushInputData(head);
                unpushedData = rest;
                
                if stream.IsAtEnd
                    obj.Streams.Dequeue();
                end
            end
        end
        
        
        function r = get.SampleRate(obj)
            r = obj.Streams.Peek().SampleRate;
        end
        
        
        function p = get.Position(obj)
            p = obj.Streams.Peek().Position;
        end        
        
    end
    
end

