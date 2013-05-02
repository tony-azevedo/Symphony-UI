classdef Epoch < handle
   
    properties
        ProtocolID
        ProtocolParameters
        Stimuli
        Responses
        Identifier
        StartTime
        Background
        Keywords
        WaitForTrigger
        Duration
        IsComplete
        IsIndefinite
    end
    
    properties
        StimulusDataEnumerators
    end
    
    methods
        
        function obj = Epoch(identifier, parameters)
            obj = obj@handle();
            
            obj.ProtocolID = identifier;
            if nargin == 2
                obj.ProtocolParameters = parameters;
            else
                obj.ProtocolParameters = System.Collections.Generic.Dictionary();
            end
            obj.Stimuli = System.Collections.Generic.Dictionary();
            obj.Responses = System.Collections.Generic.Dictionary();
            obj.StimulusDataEnumerators = System.Collections.Generic.Dictionary();
            obj.Identifier = char(java.util.UUID.randomUUID());
            obj.Background = System.Collections.Generic.Dictionary();
            obj.Keywords = System.Collections.Generic.List();
            obj.WaitForTrigger = false;
        end
        
        
        function d = PullOutputData(obj, device, blockDuration)
            if obj.Stimuli.ContainsKey(device)
                if obj.StimulusDataEnumerators.ContainsKey(device)
                    enum = obj.StimulusDataEnumerators.Item(device);
                else
                    enum = obj.Stimuli.Item(device).DataBlocks(blockDuration).GetEnumerator();
                    obj.StimulusDataEnumerators.Add(device, enum);
                end
                                
                stimData = [];
                while isempty(stimData) || stimData.Duration < blockDuration
                    if ~enum.MoveNext();
                        break;
                    end
                    
                    if isempty(stimData)
                        stimData = enum.Current;
                    else
                        stimData = stimData.Concat(enum.Current);
                    end
                end
                
                if isempty(stimData)
                    d = obj.BackgroundDataForDevice(device, blockDuration);
                    return;
                end
                
                if stimData.Duration < blockDuration
                    remainingDuration = blockDuration - stimData.Duration;
                    stimData = stimData.Concat(obj.BackgroundDataForDevice(device, remainingDuration));
                end
                
                d = stimData;
                return;
            end
            
            d = obj.BackgroundDataForDevice(device, blockDuration);
        end
        
        
        function d = BackgroundDataForDevice(obj, device, blockDuration)
            
            if ~obj.Background.ContainsKey(device)
                error(['Epoch does not have a stimulus or background for ' device.Name]);
            end
            
            srate = obj.Background.Item(device).SampleRate;
            value = obj.Background.Item(device).Background;
            
            samples = Symphony.Core.TimeSpanExtensions.Samples(blockDuration, srate);
            
            data = Symphony.Core.Measurement.FromArray(zeros(1, samples), value.BaseUnit);
            
            d = Symphony.Core.OutputData(data, srate, false);
        end
        
        
        function SetBackground(obj, device, background, sampleRate)
            obj.Background.Item(device, Symphony.Core.Epoch.EpochBackground(background, sampleRate));
        end
        
        
        function d = get.Duration(obj)
            d = System.TimeSpan.Zero();
            
            for i = 0:obj.Stimuli.Values.Count-1
                if obj.Stimuli.Values.Item(i).Duration > d
                    d = obj.Stimuli.Values.Item(i).Duration;
                end
            end
        end
        
        
        function b = get.IsComplete(obj)
            
            for i = 0:obj.Responses.Values.Count-1
                if obj.Responses.Values.Item(i).Duration < obj.Duration
                    b = false;
                    return;
                end
            end
            
            b = true;
        end
        
    end
    
    methods (Static)
        
        function eb = EpochBackground(background, sampleRate)
            eb.Background = background;
            eb.SampleRate = sampleRate;
        end
        
    end
end