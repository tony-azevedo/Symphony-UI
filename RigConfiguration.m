classdef RigConfiguration < handle
    
    properties (Constant, Abstract)
        displayName
    end
    
    
    properties
        controller
    end
    
    
    properties (Dependent)
        sampleRate
    end
    
    
    properties (GetAccess = private)
        hekaDigitalOutDevice = []
        hekaDigitalOutNames = {}
        hekaDigitalOutChannels = []
    end
    
    
    properties (Hidden)
        symphonyConfig                  % The Symphony configuration prepared by symphonyrc
        proxySampleRate                 % numeric, in Hz
    end
    
    
    methods
        
        function obj = init(obj, symphonyConfig, daqControllerFactory)
            % This method is essentially a constructor. If you need to override the constructor, override this instead.
            
            import Symphony.Core.*;
            
            obj.symphonyConfig = symphonyConfig;
                        
            obj.controller = Controller();
            obj.controller.DAQController = daqControllerFactory.createDAQ();
            obj.controller.Clock = obj.controller.DAQController.Clock;
            
            obj.sampleRate = 10000;

            try
                obj.createDevices();
                
                % Have all devices start emitting their background values.
                obj.controller.DAQController.SetStreamsBackground();
            catch ME
                obj.close();
                throw(ME);
            end    
        end
        
        
        function set.sampleRate(obj, rate)
            import Symphony.Core.*;             % import this so this method knows what a 'Measurement' - see below - is...

            if ~isnumeric(rate)
                error('Symphony:InvalidSampleRate', 'The sample rate for a rig configuration must be a number.');
            end
            
            % Update the rate of the DAQ controller.
            srProp = findprop(obj.controller.DAQController, 'SampleRate');
            if isempty(srProp)
                obj.proxySampleRate = rate;
            else
                obj.controller.DAQController.SampleRate = Measurement(rate, 'Hz');
            end
            
            % Update the rate of all devices.
            devices = obj.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                if ~isempty(device.OutputSampleRate)
                    device.OutputSampleRate = Measurement(rate, 'Hz');
                    
                    % Update device background stream rate.
                    out = BackgroundOutputStream(Background(device.Background, device.OutputSampleRate));
                    obj.controller.BackgroundStreams.Item(device, out);
                end
                
                if ~isempty(device.InputSampleRate)
                    device.InputSampleRate = Measurement(rate, 'Hz');
                end                
            end
            
            % Update the rate of all DAQ streams.
            enum = obj.controller.DAQController.Streams.GetEnumerator;
            while enum.MoveNext()
                stream = enum.Current;
                if stream.CanSetSampleRate
                    stream.SampleRate = Measurement(rate, 'Hz');
                end
            end
        end
        
        
        function rate = get.sampleRate(obj)
            srProp = findprop(obj.controller.DAQController, 'SampleRate');
            if isempty(srProp)
                rate = obj.proxySampleRate;
            else
                m = obj.controller.DAQController.SampleRate;
                if ~strcmp(char(m.BaseUnit), 'Hz')
                    error('Symphony:SampleRateNotInHz', 'The sample rate is not in Hz.');
                end
                rate = System.Decimal.ToDouble(m.QuantityInBaseUnit);
            end
        end
        
        
        function stream = streamWithName(obj, streamName, isOutput)
            import Symphony.Core.*;
            
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')     % TODO: or has method 'GetStream'?
                stream = obj.controller.DAQController.GetStream(streamName);
            else
                if isOutput
                    stream = DAQOutputStream(streamName);
                else
                    stream = DAQInputStream(streamName);
                end
                stream.SampleRate = Measurement(obj.sampleRate, 'Hz');
                stream.MeasurementConversionTarget = 'V';
                stream.Clock = obj.controller.DAQController.Clock;
                obj.controller.DAQController.AddStream(stream);
            end
        end
        
        
        function addStreams(obj, device, outStreamName, inStreamName)
            import Symphony.Core.*;
            
            % Create and bind any output stream.
            if ~isempty(outStreamName)
                stream = obj.streamWithName(outStreamName, true);
                device.BindStream(stream);
                device.OutputSampleRate = Measurement(obj.sampleRate, 'Hz');
            end
            
            % Create and bind any input stream.
            if ~isempty(inStreamName)
                stream = obj.streamWithName(inStreamName, false);
                device.BindStream(stream);
                device.InputSampleRate = Measurement(obj.sampleRate, 'Hz');
            end
        end
        
        
        function addDevice(obj, deviceName, outStreamName, inStreamName)            
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            
            if strncmp(outStreamName, 'DIGITAL', 7) || strncmp(inStreamName, 'DIGITAL', 7)
                units = Measurement.UNITLESS;                   
            else
                units = 'V';
            end
            
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController') && strncmp(outStreamName, 'DIGITAL_OUT', 11)
                % The digital out channels for the Heka ITC share a single device.
                if isempty(obj.hekaDigitalOutDevice)
                    dev = UnitConvertingExternalDevice('Heka Digital Out', 'HEKA Instruments', obj.controller, Measurement(0, units));
                    dev.MeasurementConversionTarget = units;
                    dev.Clock = obj.controller.DAQController.Clock;
                    dev.OutputSampleRate = Measurement(obj.sampleRate, 'Hz');
                    
                    out = BackgroundOutputStream(Background(Measurement(0, units), dev.OutputSampleRate));
                    obj.controller.BackgroundStreams.Item(dev, out);
                    
                    stream = obj.streamWithName('DIGITAL_OUT.1', true);
                    dev.BindStream(stream);
                    
                    obj.hekaDigitalOutDevice = dev;
                else
                    dev = obj.hekaDigitalOutDevice;
                end
                
                % Keep track of which virtual device names map to which channel of the real device.
                obj.hekaDigitalOutNames{end + 1} = deviceName;
                obj.hekaDigitalOutChannels(end + 1) = str2double(outStreamName(end));
            else               
                dev = UnitConvertingExternalDevice(deviceName, 'unknown', obj.controller, Measurement(0, units));
                dev.MeasurementConversionTarget = units;
                dev.Clock = obj.controller.DAQController.Clock;
                
                obj.addStreams(dev, outStreamName, inStreamName);
                
                % Set default device background stream in the controller.
                if ~isempty(dev.OutputSampleRate)
                    out = BackgroundOutputStream(Background(Measurement(0, units), dev.OutputSampleRate));
                    obj.controller.BackgroundStreams.Item(dev, out);
                end
            end
        end
        
        
        function mode = multiClampMode(obj, deviceName)
            if nargin == 2 && ~isempty(deviceName)
                device = obj.deviceWithName(deviceName);
            else
                % Find a MultiClamp device to query.
                devices = obj.multiClampDevices();
                if ~isempty(devices)
                    device = devices{1};
                end
            end

            if isempty(device)
                error('Symphony:MultiClamp:NoDevice', 'Cannot determine the MultiClamp mode because no MultiClamp device has been created.');
            end

            requireOutMode = ~isempty(device.OutputSampleRate);
            requireInMode = ~isempty(device.InputSampleRate);
            
            % Try to get the multiclamp mode from the commander.
            start = tic;
            timeOutSeconds = 2;
            mode = '';
            while isempty(mode)              
                                
                outMode = '';
                if requireOutMode && device.HasDeviceOutputParameters
                    outMode = char(device.CurrentDeviceOutputParameters.Data.OperatingMode);
                end
                                
                inMode = '';
                if requireInMode && device.HasDeviceInputParameters
                    inMode = char(device.CurrentDeviceInputParameters.Data.OperatingMode);
                end
                
                if requireOutMode && requireInMode
                    if strcmp(outMode, inMode)
                        mode = outMode;
                    end
                elseif requireOutMode
                    mode = outMode;
                else
                    mode = inMode;
                end
                
                if isempty(mode)
                    if toc(start) < timeOutSeconds
                        pause(0.25);
                    else
                        input(['Please toggle the MultiClamp commander for ' deviceName ' mode then press enter (or Ctrl-C to cancel)...'], 's'); 
                    end
                end
            end
        end
        
        
        function addMultiClampDevice(obj, deviceName, channel, outStreamName, inStreamName)
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            
            if channel ~= 1 && channel ~= 2
                error('Symphony:MultiClamp:InvalidChannel', 'The MultiClamp channel must be either 1 or 2.');
            end
            
            % TODO: validate that the same channel is not added a second time?
            
            % Get the local serial number of the MultiClamp.
            % (Stored as a local pref so that each rig can have its own value.)
            if ispref('Symphony', 'MultiClamp_SerialNumber')
                multiClampSN = getpref('Symphony', 'MultiClamp_SerialNumber', '');
            else
                multiClampSN = getpref('MultiClamp', 'SerialNumber', '');
                if ispref('MultiClamp') && ~isempty(multiClampSN)
                    setpref('Symphony', 'MultiClamp_SerialNumber', multiClampSN);
                    rmpref('MultiClamp');
                end
            end
            if isempty(multiClampSN)
                answer = inputdlg({'Enter the serial number of the MultiClamp:'}, 'Symphony', 1, {'831400'});
                if isempty(answer)
                    error('Symphony:MultiClamp:NoSerialNumber', 'Cannot create a MultiClamp device without a serial number');
                else
                    multiClampSN = uint32(str2double(answer{1}));
                    setpref('Symphony', 'MultiClamp_SerialNumber', multiClampSN);
                end
            end
            
            % Create the device so we can query for the current mode.
            modes = NET.createArray('System.String', 3);
            modes(1) = 'VClamp';
            modes(2) = 'I0';
            modes(3) = 'IClamp';
            
            backgroundMeasurements = NET.createArray('Symphony.Core.IMeasurement', 3);
            backgroundMeasurements(1) = Measurement(0, 'V');
            backgroundMeasurements(2) = Measurement(0, 'A');
            backgroundMeasurements(3) = Measurement(0, 'A');
            
            dev = MultiClampDevice(multiClampSN, channel, obj.controller.DAQController.Clock, obj.controller,...
                modes,...
                backgroundMeasurements...
                );
            dev.Name = deviceName;
            dev.Clock = obj.controller.DAQController.Clock;
            
            % Bind the streams.
            obj.addStreams(dev, outStreamName, inStreamName);
            
            % Make sure the current mode of the MultiClamp is known.
            try
                obj.multiClampMode(deviceName);
            catch ME
                dev.Controller = [];
                if iscell(obj.controller.Devices)
                    for i = 1:length(obj.controller.Devices)
                        if obj.controller.Devices{i} == dev
                            obj.controller.Devices(i) = [];
                            break;
                        end
                    end
                else
                    obj.controller.Devices.Remove(dev);
                end
                throw(ME);
            end
        end
        
        
        function d = devices(obj)
            d = listValues(obj.controller.Devices);
        end
        
        
        function d = multiClampDevices(obj)
            d = {};
            devices = obj.devices();
            for i = 1:length(devices)
                if isa(devices{i}, 'Symphony.ExternalDevices.MultiClampDevice')
                    d{end + 1} = devices{i};
                end
            end
        end
        
        
        function n = numMultiClampDevices(obj)
            n = length(obj.multiClampDevices());
        end
                
        
        function names = deviceNames(obj, expr)
            % Returns all device names with a match of the given regular expression.
            
            if nargin < 2
                expr = '.';
            end
            
            names = {};
            devices = obj.devices();
            for i = 1:length(devices)
                name = char(devices{i}.Name);
                if ~isempty(regexpi(name, expr, 'once'))
                    names{end + 1} = name;
                end
            end            
        end
        
        
        function names = multiClampDeviceNames(obj)            
            names = {};
            devices = obj.multiClampDevices();
            for i = 1:length(devices)
                names{end + 1} = char(devices{i}.Name);
            end
        end
        
        
        function [device, digitalChannel] = deviceWithName(obj, name)
            ind = find(strcmp(obj.hekaDigitalOutNames, name));
            
            if isempty(ind)
                device = obj.controller.GetDevice(name);
                digitalChannel = [];
            else
                device = obj.hekaDigitalOutDevice;
                digitalChannel = obj.hekaDigitalOutChannels(ind);
            end
        end
        
        
        function desc = describeDevices(obj)
            desc = '';
            devices = obj.devices();
            for i = 1:length(devices)
                [~, streams] = dictionaryKeysAndValues(devices{i}.Streams);
                for j = 1:length(streams)
                    if isa(streams{j}, 'Symphony.Core.IDAQInputStream')
                        desc = [desc sprintf('%s  <--  %s\n', char(devices{i}.Name), char(streams{j}.Name))]; %#ok<AGROW>
                    else
                        desc = [desc sprintf('%s  -->  %s\n', char(devices{i}.Name), char(streams{j}.Name))]; %#ok<AGROW>
                    end
                end
            end
        end
        
        
        function setDeviceBackground(obj, deviceName, background, units)
            % Set a constant background value for a device in the absence of an epoch.            
            
            import Symphony.Core.*;
            
            device = obj.deviceWithName(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            background = Measurement(background, units);
            
            % Set device background.
            if isa(device, 'Symphony.ExternalDevices.MultiClampDevice')
                % Set the background for the appropriate mode and for the device if the current mode matches.
                if strcmp(char(background.BaseUnit), 'V')
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.VClamp, background);
                else
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.IClamp, background);
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.I0, background);
                end
            else
                device.Background = background;
            end
            
            % Set controller background stream for device.
            if ~isempty(device.OutputSampleRate)
                out = BackgroundOutputStream(Background(background, device.OutputSampleRate));
                obj.controller.BackgroundStreams.Item(device, out);
            end
            
            % Apply the background.
            device.ApplyBackground();
        end
        
        
        function prepared(obj)
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')
                obj.controller.DAQController.SetStreamsBackground();
            end
        end
        
        
        function close(obj)
            % Release any hold we have on hardware.
            
            % Force dispose any multiclamp devices to ensure commander listeners are removed.
            devices = obj.multiClampDevices();
            for i = 1:length(devices)
                devices{i}.Dispose();
            end
            
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')
                obj.controller.DAQController.CloseHardware();
            end
        end
        
    end
    
    
    methods (Abstract)
        
        createDevices(obj);
        
    end
    
end


%% To support units coversion:
%
% fromUnits = 'foo'
% toUnits = 'V'
% Converters.Register(fromUnits, toUnits, @conversionProc);
% 
% 
% function measurementOut = conversionProc(measurementIn)
%   ...
% end
