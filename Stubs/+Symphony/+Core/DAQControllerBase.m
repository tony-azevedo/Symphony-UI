classdef DAQControllerBase < Symphony.Core.IDAQController
   
    properties
        Clock
        Running
        Streams
        OutputStreams
        ProcessInterval
        StopRequested
    end
    
    methods
        
        function obj = DAQControllerBase()
            obj.Streams = GenericList();
        end
        
        
        function Start(obj, waitForTrigger)
            if ~obj.Running
                obj.Running = true;
                obj.StopRequested = false;
                
                obj.Process(waitForTrigger);
            end
        end
        
        
        function Process(obj, waitForTrigger)
            c = onCleanup(@()obj.Stop());
            try
                obj.ProcessLoop(waitForTrigger);
            catch x
                obj.StopWithException(x);
            end
        end
        
        
        function ProcessLoop(obj, ~)
            
            iterationStart = now;
            
            while obj.Running && ~obj.ShouldStop()
                
                incomingData = obj.ProcessLoopIteration(outgoingData);
                
                obj.PushIncomingData(incomingData);
                
                obj.SleepForRestOfIteration(iterationStart, obj.ProcessInterval);
                
                iterationStart = iterationStart + obj.ProcessInterval;
            end
            
        end
        
        
        function outData = NextOutgoingData(obj)
            outData = GenericDictionary();
            
            activeStreams = obj.ActiveOutputStreams;
            for i = 1:activeStreams.Count
                s = activeStreams.Item(i);
                outData.Add(s, NextOutputDataForStream(s));
            end            
        end
             
        
        function d = NextOutputDataForStream(outStream)
            d = outStream.PullOutputData(obj.ProcessInterval);
        end
        
        
        function SleepForRestOfIteration(~, iterationStart, iterationDuration)
            pause(now - iterationStart + iterationDuration);
        end
        
        
        function b = ShouldStop(obj)
            b = obj.StopRequested;
        end
        
        
        function Stop(obj)
            obj.Running = false;
        end
                      
        
        function RequestStop(obj)
            obj.StopRequested = true;
        end
        
        
        function SetStreamsBackground(~)
        end
        
        
        function s = ActiveOutputStreams(obj)
            s = GenericList();
            
            outStreams = obj.OutputStreams;
            for i = 1:outStreams.Count
                if outStreams.Item(i).Active
                    s.Add(outStreams.Item(i));
                end
            end
        end
        
        
        function AddStream(obj, stream)
            obj.Streams.Add(stream);
        end
        
        
        function s = GetStream(obj, name)
            s = [];
            for i = 1:obj.Streams.Count()
                if strcmp(name, obj.Streams.Item(i))
                    s = obj.Streams.Item(i);
                    return;
                end
            end
        end
        
        
        function s = get.OutputStreams(obj)
            s = GenericList();
            for i = 1:obj.Streams.Count()
                if isa(obj.Streams.Item(i), 'Symphony.Core.IDAQOutputStream')
                    s.Add(obj.Streams.Item(i))
                end
            end
        end
        
    end
    
    methods (Abstract)
        incomingData = ProcessLoopIteration(obj, outputData);
    end
end