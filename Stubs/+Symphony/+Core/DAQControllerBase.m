classdef DAQControllerBase < Symphony.Core.IDAQController
   
    properties
        Clock
        Running
        Streams
        InputStreams
        OutputStreams
        ProcessInterval
        StopRequested
    end
    
    methods
        
        function obj = DAQControllerBase()
            obj.Running = false;
            obj.Streams = System.Collections.Generic.List();
        end
        
        
        function Start(obj, waitForTrigger)
            if ~obj.Running
                obj.Running = true;
                obj.StopRequested = false;
                
                obj.Process(waitForTrigger);
            end
        end
        
        
        function Process(obj, waitForTrigger)
            c = onCleanup(@obj.Stop);
            try
                obj.ProcessLoop(waitForTrigger);
            catch x
                disp(getReport(x));
                obj.StopWithException(x);
            end
        end
        
        
        function ProcessLoop(obj, ~)
            
            iterationStart = now;
            
            while obj.Running && ~obj.ShouldStop()
                
                outgoingData = obj.NextOutgoingData();
                
                incomingData = obj.ProcessLoopIteration(outgoingData);
                
                obj.PushIncomingData(incomingData);
                
                obj.SleepForRestOfIteration(iterationStart, obj.ProcessInterval.TotalSeconds);
                
                iterationStart = iterationStart + obj.ProcessInterval.TotalSeconds;
            end
            
        end
        
        
        function outData = NextOutgoingData(obj)
            outData = System.Collections.Generic.Dictionary();
            
            activeStreams = obj.ActiveOutputStreams;
            for i = 0:activeStreams.Count-1
                s = activeStreams.Item(i);
                outData.Add(s, obj.NextOutputDataForStream(s));
            end            
        end
             
        
        function d = NextOutputDataForStream(obj, outStream)
            d = outStream.PullOutputData(obj.ProcessInterval);
        end
        
        
        function PushIncomingData(obj, incomingData)            
            for i = 0:incomingData.Keys.Count-1
                inStream = incomingData.Keys.Item(i);
                inStream.PushInputData(incomingData.Item(inStream));
            end
        end
        
        
        function SleepForRestOfIteration(~, iterationStart, iterationDuration)
            pause(now - iterationStart + iterationDuration);
        end
        
        
        function b = ShouldStop(obj)
            b = obj.ActiveOutputStreamsWithData.Count == 0 || obj.StopRequested;
        end
        
        
        function Stop(obj)
            obj.Running = false;
        end
        
        
        function StopWithException(obj, exception)
            obj.Running = false;
        end
                      
        
        function RequestStop(obj)
            obj.StopRequested = true;
        end
        
        
        function SetStreamsBackground(~)
        end
        
        
        function s = ActiveOutputStreams(obj)
            s = System.Collections.Generic.List();
            
            outStreams = obj.OutputStreams;
            for i = 0:outStreams.Count-1
                if outStreams.Item(i).Active
                    s.Add(outStreams.Item(i));
                end
            end
        end
        
        
        function s = ActiveInputStreams(obj)
            s = System.Collections.Generic.List();
            
            inStreams = obj.InputStreams;
            for i = 0:inStreams.Count-1
                if inStreams.Item(i).Active
                    s.Add(inStreams.Item(i));
                end
            end
        end
        
        
        function s = ActiveOutputStreamsWithData(obj)
            s = System.Collections.Generic.List();
            
            outStreams = obj.ActiveOutputStreams;
            for i = 0:outStreams.Count-1
                if outStreams.Item(1).HasMoreData
                    s.Add(outStreams.Item(i));
                end
            end
        end
        
        
        function AddStream(obj, stream)
            obj.Streams.Add(stream);
        end
        
        
        function s = GetStream(obj, name)
            s = [];
            for i = 0:obj.Streams.Count-1
                if strcmp(name, obj.Streams.Item(i))
                    s = obj.Streams.Item(i);
                    return;
                end
            end
        end
        
        
        function s = get.InputStreams(obj)
            s = System.Collections.Generic.List();
            for i = 0:obj.Streams.Count-1
                if isa(obj.Streams.Item(i), 'Symphony.Core.IDAQInputStream')
                    s.Add(obj.Streams.Item(i))
                end
            end
        end
        
        
        function s = get.OutputStreams(obj)
            s = System.Collections.Generic.List();
            for i = 0:obj.Streams.Count-1
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