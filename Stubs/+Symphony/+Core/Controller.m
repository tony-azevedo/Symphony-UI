classdef Controller < Symphony.Core.ITimelineProducer
   
    properties
        Clock
        DAQController
    end
    
    properties (SetAccess = private)
        Devices
        CurrentEpoch
        Running
    end
    
    events
        NextEpochRequested
        PushedInputData
    end
    
    methods      
        
        function obj = Controller()
            obj.Devices = System.Collections.Generic.List();
        end
        
        
        function controller = AddDevice(obj, device)
            obj.Devices.Add(device);
            device.Controller = obj;
            controller = obj;
        end
        
        
        function d = GetDevice(obj, deviceName)
            d = [];
            for i = 0:obj.Devices.Count-1
                device = obj.Devices.Item(i);
                if strcmp(device.Name, deviceName)
                    d = device;
                    break;
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
        
        
        function PrepareRun(obj)
            % TODO: Validate
            
            if obj.Running
                error('Controller is running');
            end
            
            obj.Running = true;
        end                    
               
        
        function FinishRun(obj)
            obj.Running = false;
        end
        
        
        function task = RunEpochAsync(obj, epoch, persistor)
            obj.PrepareRun();
            
            task = System.Threading.Tasks.Task(@()obj.CommonRunEpoch(epoch, persistor));
            task.Start();
        end
        
        
        function CommonRunEpoch(obj, epoch, persistor)
            cEpoch = obj.CurrentEpoch;
            cleanup = onCleanup(@()obj.CleanupCommonRunEpoch(cEpoch));
            
            obj.CurrentEpoch = epoch;
            obj.RunCurrentEpoch(persistor);
        end
        
        
        function CleanupCommonRunEpoch(obj, epoch)
            obj.CurrentEpoch = epoch;
            obj.FinishRun();
        end
        
        
        function RunCurrentEpoch(obj, persistor)
            inputPushed = addlistener(obj, 'PushedInputData', @(src, data)obj.InputPushed(src, data, persistor));
            exceptionalStop = addlistener(obj.DAQController, 'ExceptionalStop', @(src, data)obj.ExceptionalStop(src, data));
            
            cleanup = onCleanup(@()delete([inputPushed exceptionalStop]));
            
            obj.CurrentEpoch.StartTime = now;
            obj.DAQController.Start(obj.CurrentEpoch.WaitForTrigger);            
        end
                
        
        function InputPushed(obj, src, data, persistor) %#ok<INUSL>
            epoch = obj.CurrentEpoch;
            
            if epoch.IsComplete
                obj.DAQController.RequestStop();
                
                if ~isempty(persistor)
                    persistor.Serialize(epoch);
                end
            end
        end
        
        
        function ExceptionalStop(obj, src, data) %#ok<INUSD>
            % MATLAB doesn't appear to appropriately bubble up exceptions on listeners
            
            %exception = addCause(MException('', 'DAQ Controller stopped'), data.Exception);
            %throw(exception);
        end
        
        
        function CancelRun(obj)
            obj.DAQController.RequestStop();
        end
        
        
        function persistor = BeginEpochGroup(obj, path, label, source)
            persistor = EpochXMLPersistor(path);
            
            keywords = NET.createArray('System.String', 0);
            properties = NET.createGeneric('System.Collections.Generic.Dictionary', {'System.String', 'System.Object'});
            identifier = System.Guid.NewGuid();
            startTime = obj.Clock.Now;
            persistor.BeginEpochGroup(label, source, keywords, properties, identifier, startTime);
        end
        
        
        function EndEpochGroup(~, persistor)
            persistor.EndEpochGroup();
            persistor.CloseDocument();
        end
        
    end
end