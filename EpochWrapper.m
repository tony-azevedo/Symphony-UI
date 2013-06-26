% A wrapper around a core Epoch instance, making it easier and more efficient to work with in Matlab.

classdef EpochWrapper
    
    properties (Access = private)
        epoch
        deviceNameConverter
        responseCache
    end
    
    methods
        
        function obj = EpochWrapper(epoch, deviceNameConverter)
            obj.epoch = epoch;
            obj.deviceNameConverter = deviceNameConverter;
            obj.responseCache = containers.Map();
        end
        
        
        function addKeyword(obj, keyword)
            % Add a keyword to the Epoch.
            
            obj.epoch.Keywords.Add(keyword);
        end
        
        
        function addParameter(obj, name, value)
            % Add a parameter to the Epoch.
            
            if ~ischar(value) && length(value) > 1
                if isnumeric(value)
                    value = sprintf('%g ', value);
                else
                    error('Parameter values must be scalar or vectors of numbers.');
                end
            end
            
            obj.epoch.ProtocolParameters.Add(name, value);
        end
        
        
        function addStimulus(obj, deviceName, stimulusID, stimulusData, units, durationInSeconds)
            % Add a stimulus to present when the Epoch is run. Duration is optional.
            
            import Symphony.Core.*;
            
            [device, digitalChannel] = obj.deviceNameConverter(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            if isempty(digitalChannel)
                if nargin == 4
                    % Default to the the device's background units if none specified
                    units = device.Background.Unit;
                end
                
                stimDataList = Measurement.FromArray(stimulusData, units);
            else
                % Digital outputs to the Heka ITC have to be merged together.
                
                if any(stimulusData ~= 0 & stimulusData ~= 1)
                    error('Symphony:BadDigitalStimulus', 'Stimuli for digital outputs must contain only 0 or 1 values.');
                end
                
                if epoch.Stimuli.ContainsKey(device)
                    stim = epoch.Stimuli.Item(device);
                    existingData = Measurement.ToQuantityArray(stim.Data.Data);
                else
                    existingData = zeros(1, length(stimulusData));
                end
                
                % TODO: pad with zeros if different lengths
                
                stimulusData = existingData + (stimulusData .* 2 ^ digitalChannel);
                units = Measurement.UNITLESS;
                stimDataList = Measurement.FromArray(stimulusData, units);
            end
            
            outputData = OutputData(stimDataList, device.OutputSampleRate);
            
            providedDuration = nargin >= 6;
            
            if ~providedDuration
                duration = TimeSpanOption(outputData.Duration);
            elseif strcmpi(durationInSeconds, 'indefinite')
                duration = TimeSpanOption.Indefinite;
            else
                duration = TimeSpanOption(System.TimeSpan.FromSeconds(durationInSeconds));
            end
            
            stim = RepeatingRenderedStimulus(stimulusID, structToDictionary(struct()), outputData, duration);
            
            obj.epoch.Stimuli.Add(device, stim);
        end
        
        
        function setBackground(obj, deviceName, background, units)
            % Add a background to present in the absence of a stimulus when the Epoch is run.
            
            import Symphony.Core.*;
            
            device = obj.deviceNameConverter(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            background = Measurement(background, units);
            
            obj.epoch.SetBackground(device, background, device.OutputSampleRate);
        end
        
        
        function recordResponse(obj, deviceName)
            % Indicate that a response should be recorded from the device when the Epoch is run.
                   
            import Symphony.Core.*;
            
            device = obj.deviceNameConverter(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            obj.epoch.Responses.Add(device, Response());
        end
        
        
        function [r, s, u] = response(obj, deviceName)
            % Return a recorded response, sample rate and units from the device with the given name.
            
            import Symphony.Core.*;
            
            if nargin == 1
                % If no device specified then pick the first one.
                devices = dictionaryKeysAndValues(obj.epoch.Responses);
                if isempty(devices)
                    error('No devices have had their responses recorded.');
                end
                device = devices{1};
            else
                device = obj.deviceNameConverter(deviceName);
                if isempty(device)
                    error('There is no device named ''%s''.', deviceName);
                end
            end
            
            deviceName = char(device.Name);
            
            if isKey(obj.responseCache, deviceName)
                % Use the cached response data.
                response = obj.responseCache(deviceName);
                r = response.data;
                s = response.sampleRate;
                u = response.units;
            else
                % Extract the raw data.
                try
                    response = obj.coreEpoch.Responses.Item(device);
                    data = response.Data;
                    r = double(Measurement.ToQuantityArray(data));
                    u = char(Measurement.HomogenousDisplayUnits(data));
                catch ME %#ok<NASGU>
                    r = [];
                    u = '';
                end
                
                if ~isempty(r)
                    s = System.Decimal.ToDouble(response.SampleRate.QuantityInBaseUnit);
                    % TODO: do we care about the units of the SampleRate measurement?
                else
                    s = [];
                end
                
                % Cache the results.
                obj.responseCache(deviceName) = struct('data', r, 'sampleRate', s, 'units', u);
            end
        end
        
    end       
    
end