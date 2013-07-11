classdef Controller < Symphony.Core.ITimelineProducer
   
    properties
        Clock
        DAQController
        BackgroundDataStreams
    end
    
    properties (SetAccess = private)
        Devices
        IsRunning
    end
    
    properties (Access = private)
        CurrentEpoch
    end
    
    events
        ReceivedInputData
        PushedInputData
        CompletedEpoch
        DiscardedEpoch
    end
    
    methods      
        
        function obj = Controller()
            obj.Devices = System.Collections.ArrayList();
            obj.BackgroundDataStreams = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IExternalDevice', 'Symphony.Core.IOutputDataStream'});
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
            
            obj.OnReceivedInputData(device, inData);
            
            if ~isempty(obj.CurrentEpoch) && obj.CurrentEpoch.Responses.ContainsKey(device)
                response = obj.CurrentEpoch.Responses.Item(device);
                
                [head, ~] = inData.SplitData(obj.CurrentEpoch.Duration - response.Duration);
                response.AppendData(head);
            end
            
            obj.OnPushedInputData(obj.CurrentEpoch);
        end
        
        
        function OnReceivedInputData(obj, device, inData)
            notify(obj, 'ReceivedInputData', Symphony.Core.TimeStampedDeviceDataEventArgs(obj.Clock, device, inData));
        end
        
        
        function OnPushedInputData(obj, epoch)
            notify(obj, 'PushedInputData', Symphony.Core.TimeStampedEpochEventArgs(obj.Clock, epoch));
        end    
        
        
        function OnCompletedEpoch(obj, epoch)
            notify(obj, 'CompletedEpoch', Symphony.Core.TimeStampedEpochEventArgs(obj.Clock, epoch));
        end
        
        
        function EnqueueEpoch(obj, epoch) %#ok<INUSD>
            error('The stub controller cannot EnqueueEpoch');
        end
        
        
        function ClearEpochQueue(obj) %#ok<MANU>
            
        end
        
        
        function task = StartAsync(obj, persistor) %#ok<STOUT,INUSD>
            error('The stub controller cannot StartAsync');
        end
        
        
        function RunEpoch(obj, epoch, persistor)
            obj.IsRunning = true;
            
            epochCompleted = addlistener(obj, 'CompletedEpoch', @(src, data)obj.RequestStop());
            cleanup = onCleanup(@()delete(epochCompleted));
            
            obj.Process(epoch, persistor);
        end
        
        
        function Process(obj, epoch, persistor)
            
            cleanup = onCleanup(@()obj.Stop());
            
            obj.ProcessLoop(epoch, persistor);
        end
        
        
        function Stop(obj)
            obj.IsRunning = false;
        end
        
        
        function ProcessLoop(obj, epoch, persistor)
                       
            inputPushed = addlistener(obj, 'PushedInputData', @(src, data)obj.InputPushed(src, data, persistor));
            exceptionalStop = addlistener(obj.DAQController, 'ExceptionalStop', @(src, data)obj.ExceptionalStop(src, data));
            
            cleanup = onCleanup(@()delete([inputPushed exceptionalStop]));
                        
            obj.CurrentEpoch = epoch;
            
            epoch.StartTime = now;
            obj.DAQController.Start(epoch.WaitForTrigger); 
        end
                        
        
        function InputPushed(obj, src, data, persistor) %#ok<INUSL>
            epoch = obj.CurrentEpoch;
            
            if epoch.IsComplete
                obj.OnCompletedEpoch(epoch);
                
                obj.DAQController.RequestStop();
                
                if ~isempty(persistor)
                    persistor.Serialize(epoch);
                end
            end
        end
        
        
        function WaitForCompletedEpochTasks(obj) %#ok<MANU>
            
        end
        
        
        function ExceptionalStop(obj, src, data) %#ok<INUSD>
            % MATLAB doesn't appear to appropriately bubble up exceptions on listeners
            
            %exception = addCause(MException('', 'DAQ Controller stopped'), data.Exception);
            %throw(exception);
        end
        
        
        function RequestPause(obj)
            
        end
        
        
        function RequestStop(obj)
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