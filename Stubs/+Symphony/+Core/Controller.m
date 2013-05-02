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
        NextEpochRequested
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
        
        
        function PrepareRun(obj)
            % TODO: Validate
            
            if obj.Running
                error('Controller is running');
            end
            
            obj.Running = true;
        end                
        
        
        function t = RunEpochAsync(obj, epoch, persistor)
            obj.PrepareRun();
            
            t = System.Threading.Tasks.Task();
            try
                obj.CommonRunEpoch(epoch, persistor)
            catch ME
                t.IsFaulted = true;
                t.Exception = System.AggregateException(getReport(ME, 'extended', 'hyperlinks', 'off'));
            end
        end
        
        
        function CommonRunEpoch(obj, epoch, persistor)
            cEpoch = obj.CurrentEpoch;
            
            cleaner = onCleanup(@()obj.CleanupCommonRunEpoch(cEpoch));
            
            obj.CurrentEpoch = epoch;
            obj.RunCurrentEpoch(persistor);
        end
        
        
        function CleanupCommonRunEpoch(obj, epoch)
            obj.CurrentEpoch = epoch;
            obj.FinishRun();
        end
        
        
        function FinishRun(obj)
            obj.Running = false;
            % TODO: OnFinishedRun
        end
        
        
        function RunCurrentEpoch(obj, persistor)
            inputPushed = addlistener(obj, 'PushedInputData', @(src, data)obj.InputPushed(src, data, persistor));
            
            c = onCleanup(@()delete(inputPushed));
            
            obj.CurrentEpoch.StartTime = now;
            obj.DAQController.Start(obj.CurrentEpoch.WaitForTrigger);            
        end
        
        
        function InputPushed(obj, src, data, persistor)
            epoch = obj.CurrentEpoch;
            
            if epoch.IsComplete
                obj.DAQController.RequestStop();
                
                if ~isempty(persistor)
                    persistor.Serialize(epoch);
                end
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