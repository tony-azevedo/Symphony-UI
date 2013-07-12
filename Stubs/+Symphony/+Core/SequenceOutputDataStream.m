classdef SequenceOutputDataStream < Symphony.Core.IOutputDataStream
    
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
        
        function obj = SequenceOutputDataStream()
            obj.Streams = System.Collections.Queue();
        end
        
        
        function Add(obj, stream)
            obj.Streams.Enqueue(stream);
        end
        
        
        function tf = get.IsAtEnd(obj)
            tf = obj.Streams.Count == 0;
        end
        
        
        function outData = PullOutputData(obj, duration)
            
            data = [];
            
            while obj.Streams.Count > 0 && (isempty(data) || data.Duration < duration)
                stream = obj.Streams.Peek();
                
                if isempty(data)
                    data = stream.PullOutputData(duration);
                else
                    data = data.Concat(stream.PullOutputData(duration - data.Duration));
                end
                
                if stream.IsAtEnd
                    obj.Streams.Dequeue();
                end
            end
            
            outData = data;
        end
        
        
        function r = get.SampleRate(obj)
            r = obj.Streams.Peek().SampleRate;
        end
        
        
        function p = get.Position(obj)
            p = obj.Streams.Peek().Position;
        end
        
        
        function d = get.Duration(obj)
            d = System.TimeSpan.Zero;
            
            itr = obj.Streams.GetEnumerator();
            while itr.MoveNext()
                stream = itr.Current;
                
                if stream.Duration == Symphony.Core.TimeSpanOption.Indefinite
                    d = Symphony.Core.TimeSpanOption.Indefinite;
                    break;
                end
                
                d = d + stream.Duration;
            end                    
        end    
    end
    
end

