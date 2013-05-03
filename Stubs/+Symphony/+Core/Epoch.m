classdef Epoch < handle
   
    properties        
        StartTime
        WaitForTrigger
    end
    
    properties (SetAccess = private)
        ProtocolID 
        ProtocolParameters
        Stimuli
        Responses
        Background
        Keywords
        Duration
        IsComplete
        IsIndefinite
        Identifier % TODO: Remove identifier
    end
    
    properties (Access = private)
        StimulusDataEnumerators
    end
    
    methods
        
        function obj = Epoch(protocolID, parameters)            
            obj.ProtocolID = protocolID;
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
        
        
        function outData = PullOutputData(obj, device, blockDuration)
            
            if obj.Stimuli.ContainsKey(device)
                if obj.StimulusDataEnumerators.ContainsKey(device)
                    blockEnum = obj.StimulusDataEnumerators.Item(device);
                else
                    blockEnum = obj.Stimuli.Item(device).DataBlocks(blockDuration).GetEnumerator();
                    obj.StimulusDataEnumerators.Add(device, blockEnum);
                end
                                
                stimData = [];
                while isempty(stimData) || stimData.Duration < blockDuration
                    if ~blockEnum.MoveNext();
                        break;
                    end
                    
                    if isempty(stimData)
                        stimData = blockEnum.Current;
                    else
                        stimData = stimData.Concat(blockEnum.Current);
                    end
                end
                
                if isempty(stimData)
                    outData = obj.BackgroundDataForDevice(device, blockDuration);
                    return;
                end
                
                if stimData.Duration < blockDuration
                    remainingDuration = blockDuration - stimData.Duration;
                    stimData = stimData.Concat(obj.BackgroundDataForDevice(device, remainingDuration));
                end
                
                outData = stimData;
                return;
            end
            
            outData = obj.BackgroundDataForDevice(device, blockDuration);
        end
        
        
        function outData = BackgroundDataForDevice(obj, device, blockDuration)
            
            if ~obj.Background.ContainsKey(device)
                error(['Epoch does not have a stimulus or background for ' device.Name]);
            end
            
            srate = obj.Background.Item(device).SampleRate;
            value = obj.Background.Item(device).Background;
            
            samples = Symphony.Core.TimeSpanExtensions.Samples(blockDuration, srate);
            data = Symphony.Core.Measurement.FromArray(zeros(1, samples), value.BaseUnit);
            
            outData = Symphony.Core.OutputData(data, srate, false);
        end
        
        
        function SetBackground(obj, device, background, sampleRate)
            obj.Background.Item(device, Symphony.Core.Epoch.EpochBackground(background, sampleRate));
        end
        
        
        function d = get.Duration(obj)
            % TODO: Build out Maybe<TimeSpan> stuff?
            
            if obj.IsIndefinite
                d = Symphony.Core.TimeSpanOption.Indefinite;
                return;
            end
            
            dur = System.TimeSpan.Zero();
            
            for i = 0:obj.Stimuli.Values.Count-1
                if obj.Stimuli.Values.Item(i).Duration > dur
                    dur = obj.Stimuli.Values.Item(i).Duration;
                end
            end
            
            d = Symphony.Core.TimeSpanOption(dur);
        end
        
        
        function c = get.IsComplete(obj)
            for i = 0:obj.Responses.Values.Count-1
                if obj.Responses.Values.Item(i).Duration < obj.Duration
                    c = false;
                    return;
                end
            end
            
            c = true;
        end
        
    end
    
    methods (Static)
        
        function b = EpochBackground(background, sampleRate)
            b.Background = background;
            b.SampleRate = sampleRate;
        end
        
    end
end