classdef Controller < Symphony.Core.ITimelineProducer
   
    properties
        Clock
        DAQController
        Devices = {}
        Configuration
        HardwareControllers
        CurrentEpoch
        Running
    end
    
    events
        PushedInputData
    end
    
    methods      
        
        function AddDevice(obj, device)
            obj.Devices{end + 1} = device;
        end
        
        
        function d = GetDevice(obj, deviceName)
            d = [];
            for device = obj.Devices
                if strcmp(device{1}.Name, deviceName)
                    d = device{1};
                end
            end
        end
        
        
        function d = PullOutputData(obj, device, duration)
            d = obj.CurrentEpoch.PullOutputData(device, duration);
        end
        
        
        function PushInputData(obj, device, inData)
            
            if ~isempty(obj.CurrentEpoch) && obj.CurrentEpoch.Responses.ContainsKey(device)
                response = obj.CurrentEpoch.Responses.Item(device);
                
                [head, ~] = inData.SplitData(obj.CurrentEpoch.Duration - response.Duration);
                response.AppendData(head);
            end
            
            obj.OnPushedInputData(obj.CurrentEpoch);
        end
        
        
        function OnPushedInputData(obj, epoch)
            notify(obj, 'PushedInputData', Symphony.Core.TimeStampedEpochEventArgs(obj.Clock, epoch));
        end
        
        
        function persistor = BeginEpochGroup(obj, path, label, source)
            persistor = EpochXMLPersistor(path);
            
            keywords = NET.createArray('System.String', 0);
            properties = NET.createGeneric('System.Collections.Generic.Dictionary', {'System.String', 'System.Object'});
            identifier = System.Guid.NewGuid();
            startTime = obj.Clock.Now;
            persistor.BeginEpochGroup(label, source, keywords, properties, identifier, startTime);
        end
        
        
        function t = RunEpochAsync(obj, epoch, persistor)
            t = System.Threading.Tasks.Task();
            try
                obj.RunEpoch(epoch, persistor)
            catch ME
                t.IsFaulted = true;
                t.Exception = System.AggregateException(getReport(ME, 'extended', 'hyperlinks', 'off'));
            end
        end
        
        
%         function RunEpoch(obj, epoch, persistor)
%             import Symphony.Core.*;
%             
%             tic;
%             
%             obj.CurrentEpoch = epoch;
%             epoch.StartTime = now;
%             
%             % Figure out how long the epoch should run.
%             epochDuration = 0;
%             for i = 1:epoch.Stimuli.Count()
%                 stimulus = epoch.Stimuli.Values{i};
%                 epochDuration = max([epochDuration stimulus.Duration().Item2.TotalSeconds]);
%             end
%             
%             % Create dummy responses.
%             for i = 1:epoch.Responses.Count
%                 device = epoch.Responses.Keys{i};
%                 
%                 if epoch.Stimuli.ContainsKey(device)
%                     % Copy the stimulii to the responses.
%                     stimulus = epoch.Stimuli.Item(device);
%                     
%                     e = stimulus.DataBlocks(stimulus.Duration.Item2);
%                     e = e.GetEnumerator();
%                     [b, e] = e.MoveNext(e);
%                     d = e.Current();
%                     
%                     epoch.Responses.Values{i} = InputData(d.Data, d.SampleRate, now);
%                 else
%                     % Generate random noise for the response.
%                     response = epoch.Responses.Values{i};
%                     samples = epochDuration * response.SampleRate.Quantity;
%                     data = System.Collections.Generic.List(samples);
%                     for j = 1:samples
%                         data.Add(Measurement((rand(1, 1) * 1000 - 500) / 1000000, 'A'));
%                     end
%                     response.Data = data;
%                     respones.InputTime = now;
%                 end
%             end
%             
%             elapsedTime = toc;
%             
%             pause(epochDuration - elapsedTime);
%             
%             if ~isempty(persistor)
%                 persistor.Serialize(epoch);
%             end
%             
%             obj.CurrentEpoch = [];
%         end
        
        function RunEpoch(obj, epoch, persistor)
            obj.CurrentEpoch = epoch;
            
            inputPushed = addlistener(obj, 'PushedInputData', @(src,data)obj.InputPushed(src, data));
            c = onCleanup(@()delete(inputPushed));
            
            obj.DAQController.Start(epoch.WaitForTrigger);
        end
        
        
        function InputPushed(obj, src, data)
            epoch = data.Epoch;
            
            if epoch.IsComplete
                obj.DAQController.RequestStop();
            end
        end

        
        function CancelRun(obj)
            obj.DAQController.RequestStop();
        end
        
        
        function EndEpochGroup(~, persistor)
            persistor.EndEpochGroup();
            persistor.CloseDocument();
        end
        
    end
end