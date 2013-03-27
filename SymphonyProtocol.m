% Create a sub-class of this class to define a protocol.
%
% Interesting methods to override:
% * prepareRun
% * prepareEpochStimuli
% * prepareEpochResponses
% * prepareEpochAttributes
% * completeEpoch
% * continueRun
% * completeRun
%
% Useful methods:
% * addStimulus
% * setDeviceBackground
% * recordResponse

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef SymphonyProtocol < handle & matlab.mixin.Copyable
    
    properties (Constant, Abstract)
        identifier
        version
        displayName
    end
    
    
    properties (Hidden)
        state                       % The state the protocol is in: 'stopped', 'running', 'paused', etc.
        rigConfig                   % A RigConfiguration instance.
        rigPrepared = false         % A flag indicating whether the rig is ready to run this protocol.
        epoch = []                  % A Symphony.Core.Epoch instance.
        epochNum = 0                % The number of epochs that have been run.
        responses                   % A structure for caching converted responses.
        figureHandlerClasses
        figureHandlers = {}
        figureHandlerParams = {}
        allowSavingEpochs = true    % An indication if this protocol allows it's data to be persisted.
        allowPausing = true         % An indication if this protocol allows pausing during acquisition.
        persistor = []              % The persistor to use with each epoch.
        epochKeywords = {}          % A cell array of string containing keywords to be applied to any upcoming epochs.
        listeners = {}              % An array of event listeners associated with this protocol.
    end
    
    
    properties
        sampleRate = {10000, 20000, 50000}      % in Hz
    end
    
    
    events
        StateChanged
    end
    
    
    methods
        
        function obj = SymphonyProtocol(rigConfig)
            obj = obj@handle();
            
            obj.rigConfig = rigConfig;
            
            obj.setState('stopped');
            obj.responses = containers.Map();
        end 
        
        
        function setState(obj, state)
            obj.state = state;
            notify(obj, 'StateChanged');
        end
        
        
        function dn = requiredDeviceNames(obj) %#ok<MANU>
            % Override this method to indicate the names of devices that are required for this protocol.
            dn = {};
        end
        
        
        function prepareRig(obj)
            % Override this method to perform any actions to get the rig ready for running the protocol, e.g. setting device backgrounds, etc.
            
            obj.rigConfig.sampleRate = obj.sampleRate;
        end
        
        
        function prepareRun(obj)
            % Override this method to perform any actions before the start of the first epoch, e.g. open a figure window, etc.
            obj.epoch = [];
            obj.epochNum = 0;
            obj.clearFigures()
        end
        
        
        function pn = parameterNames(obj, includeConstant)
            % Return a cell array of strings containing the names of the user-defined parameters.
            % By default any parameters defined by a protocol that are not constant or hidden are included.
            
            if nargin == 1
                includeConstant = false;
            end
            
            names = properties(obj);
            pn = {};
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                metaProp = findprop(obj, name);
                if ~metaProp.Hidden && (includeConstant || ~metaProp.Constant)
                    pn{end + 1} = name; %#ok<AGROW>
                end
            end
            pn = pn';
        end
              
               
        function p = parameterProperty(obj, parameterName)
            % Return a ParameterProperty object for the specified parameter.
            
            metaProp = findprop(obj, parameterName);
            p = ParameterProperty(metaProp);
            switch parameterName
                case 'sampleRate'
                    p.units = 'Hz';
            end
        end
        
        
        function p = parameters(obj, includeConstant)
            % Return a struct containing the user-defined parameters.
            % By default any parameters defined by a protocol are included.
            
            if nargin == 1
                includeConstant = false;
            end
            
            names = obj.parameterNames(includeConstant);
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                p.(name) = obj.(name);
            end
        end
        
        
        function stimuli = sampleStimuli(obj) %#ok<MANU>
            stimuli = {};
        end
      
        
        function prepareEpoch(obj)
            % Avoid overriding this method.
            % Override instead: prepareEpochStimuli, prepareEpochResponses, prepareEpochAttributes.
            
            import Symphony.Core.*;
            
            % Create the epoch.
            obj.epochNum = obj.epochNum + 1;
            obj.epoch = Epoch(obj.identifier);
            
            obj.prepareEpochStimuli();
            obj.prepareEpochResponses();
            obj.prepareEpochAttributes();
        end
        
        
        function prepareEpochStimuli(obj)
            % Override this method to add stimuli to the current epoch and set background values for devices.
            
            import Symphony.Core.*;
            
            % Set the default background value for each device.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                % Set each device's background for this epoch to be the same as the inter-epoch background.
                obj.setDeviceBackground(char(device.Name), device.Background);
            end
        end
        
        
        function prepareEpochResponses(obj)
            % Override this method to specify responses to record for the current epoch.
            
            import Symphony.Core.*;
            
            % Clear out the cache of responses.
            obj.responses = containers.Map();
            
            % Indefinite epochs cannot record responses.
            if obj.epoch.IsIndefinite()
                return
            end
            
            % Record a response from all devices with an input stream.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                % Record the response from any device that has an input stream.
                [~, streams] = dictionaryKeysAndValues(device.Streams);
                for j = 1:length(streams)
                    if isa(streams{j}, 'Symphony.Core.DAQInputStream')
                        obj.recordResponse(char(device.Name));
                        break
                    end
                end
            end
        end
        
                
        function prepareEpochAttributes(obj)
            % Override this method to add parameters, keywords, etc. to the current epoch.

            % Add any keywords specified by the user.
            for i = 1:length(obj.epochKeywords)
                obj.epoch.Keywords.Add(obj.epochKeywords{i});
            end
        end
        
        
        function addParameter(obj, name, value)
            if ~ischar(value) && length(value) > 1
                if isnumeric(value)
                    value = sprintf('%g ', value);
                else
                    error('Parameter values must be scalar or vectors of numbers.');
                end
            end
            obj.epoch.ProtocolParameters.Add(name, value);
        end
        
        
        function p = epochSpecificParameters(obj)
            % Determine the parameters unique to the current epoch.
            % TODO: diff against the previous epoch's parameters instead?
            protocolParams = obj.parameters();
            p = structDiff(dictionaryToStruct(obj.epoch.ProtocolParameters), protocolParams);
        end
        
        
        function r = deviceSampleRate(obj, device, inOrOut)
            % Return the output sample rate for the given device based on any bound stream.
            % TODO: this should move to the RigConfiguration.m if it's still even needed...
            
            import Symphony.Core.*;
            
            if ischar(device)
                deviceName = device;
                device = obj.rigConfig.deviceWithName(deviceName);
                
                if isempty(device)
                    error('There is no device named ''%s''.', deviceName);
                end
            end
            
            r = Measurement(10000, 'Hz');   % default if no output stream is found
            [~, streams] = dictionaryKeysAndValues(device.Streams);
            for index = 1:numel(streams)
                stream = streams{index};
                if (strcmp(inOrOut, 'IN') && isa(stream, 'DAQInputStream')) || (strcmp(inOrOut, 'OUT') && isa(stream, 'DAQOutputStream'))
                    r = stream.SampleRate;
                    break;
                end
            end
        end
        
        
        function addStimulus(obj, deviceName, stimulusID, stimulusData, units, durationInSeconds)
            % Queue data to send to the named device when the epoch is run.
            % Duration is optional. Specifying a duration longer than the stimulus data will cause the stimulus to repeat 
            % as needed. Specifying a duration of 'indefinite' will cause the stimulus to repeat indefinitely.
            
            import Symphony.Core.*;
            
            [device, digitalChannel] = obj.rigConfig.deviceWithName(deviceName);
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
                
                if obj.epoch.Stimuli.ContainsKey(device)
                    stim = obj.epoch.Stimuli.Item(device);
                    existingData = Measurement.ToQuantityArray(stim.Data.Data);
                else
                    existingData = zeros(1, length(stimulusData));
                end
                
                % TODO: pad with zeros if different lengths
                
                stimulusData = existingData + (stimulusData .* 2 ^ digitalChannel);
                units = Measurement.UNITLESS;
                stimDataList = Measurement.FromArray(stimulusData, units);
            end
            
            outputData = OutputData(stimDataList, obj.deviceSampleRate(device, 'OUT'));
            
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
        
        
        function setDeviceBackground(obj, deviceName, background, units)
            % Set a constant stimulus value to be sent to the device.
            
            import Symphony.*;
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            import Symphony.ExternalDevices.OperatingMode.*;
            
            device = obj.rigConfig.deviceWithName(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            if nargin == 4
                % The user supplied the quantity and units.
                background = Measurement(background, units);
            elseif isnumeric(background)
                % The user only supplied the quantity, assume volts.
                background = Measurement(background, 'V');
            elseif ~isa(background, 'Symphony.Core.Measurement')
                error('Symphony:InvalidBackground', 'The background value for a device must be a number or a Symphony.Core.Measurement');
            end
            
            if isa(device, 'Symphony.ExternalDevices.MultiClampDevice')
                % Set the background for the appropriate mode and for the device if the current mode matches.
                if strcmp(char(background.BaseUnit), 'V')
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.VClamp, background);
                    setBackground = strcmp(obj.rigConfig.multiClampMode(char(device.Name)), 'VClamp');
                else
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.IClamp, background);
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.I0, background);
                    setBackground = ~strcmp(obj.rigConfig.multiClampMode(char(device.Name)), 'VClamp');
                end
            else
                device.Background = background;
                setBackground = true;
            end
            if setBackground
                if ~isempty(obj.epoch)
                    obj.epoch.SetBackground(device, background, obj.deviceSampleRate(device, 'OUT'));
                end
            end
        end
        
        
        function recordResponse(obj, deviceName)
            % Record the response from the device with the given name when the epoch runs.
                        
            import Symphony.Core.*;
            
            device = obj.rigConfig.deviceWithName(deviceName);
            % TODO: what happens when there is no device with that name?
            
            obj.epoch.Responses.Add(device, Response());
        end
        
        
        function [r, s, u] = response(obj, deviceName)
            % Return the response, sample rate and units recorded from the device with the given name.
            
            import Symphony.Core.*;
            
            if nargin == 1
                % If no device specified then pick the first one.
                devices = dictionaryKeysAndValues(obj.epoch.Responses);
                if isempty(devices)
                    error('Symphony:NoDevicesRecorded', 'No devices have had their responses recorded.');
                end
                device = devices{1};
            else
                device = obj.rigConfig.deviceWithName(deviceName);
                if isempty(device)
                    error('Symphony:NoDeviceWithName', ['There is no device with the name ''' deviceName '''']);
                end
            end
            
            deviceName = char(device.Name);
            
            if isKey(obj.responses, deviceName)
                % Use the cached response data.
                response = obj.responses(deviceName);
                r = response.data;
                s = response.sampleRate;
                u = response.units;
            else
                % Extract the raw data.
                try
                    response = obj.epoch.Responses.Item(device);
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
                obj.responses(deviceName) = struct('data', r, 'sampleRate', s, 'units', u);
            end
        end
        
        
        function runEpoch(obj)
            % This is a core method that runs a single epoch of the protocol.
            
            import Symphony.Core.*;
            
            try
                % Tell the Symphony framework to run the epoch in the background.
                obj.rigConfig.controller.RunEpoch(obj.epoch, obj.persistor, true);
                
                % Spin until the epoch completes, listening for events.
                while obj.rigConfig.controller.Running
                    % Need a small pause to stop Matlab from grinding to a halt.
                    pause(0.01);
                end
            catch e
                % TODO: is it OK to hold up the run with the error dialog or should errors be logged and displayed at the end?
                message = ['An error occurred while running the protocol.' char(10) char(10)];
                if (isa(e, 'NET.NetException'))
                    message = [message netReport(e)]; %#ok<AGROW>
                else
                    message = [message getReport(e, 'extended', 'hyperlinks', 'off')]; %#ok<AGROW>
                end
                waitfor(errordlg(message));
            end 
        end
        
        
        function completeEpoch(obj)
            % Override this method to perform any post-analysis, etc. on the current epoch.
            obj.updateFigures();
        end
        
        
        function keepGoing = continueRun(obj)
            % Override this method to return true/false based on the current state.
            % The object's epochNum is typically useful.
            
            keepGoing = strcmp(obj.state, 'running');
        end
        
        
        function completeRun(obj)
            % Override this method to perform any actions after the last epoch has completed.
            
            obj.setState('stopped');
        end
        
        
        function run(obj)
            % This is the core method that runs a protocol, everything else is preparation for this.
            
            try
                if ~strcmp(obj.state, 'paused')
                    % Prepare the run.
                    obj.prepareRun()
                end
                
                obj.setState('running');
                
                % Loop until the protocol or the user tells us to stop.
                while obj.continueRun()
                    % Run a single epoch.
                    
                    % Prepare the epoch: set backgrounds, add stimuli, record responses, add parameters, etc.
                    obj.prepareEpoch();
                    
                    % Persist the params now that the sub-class has had a chance to tweak them.
                    pluginParams = obj.parameters(true);
                    fields = fieldnames(pluginParams);
                    for fieldName = fields'
                        fieldValue = pluginParams.(fieldName{1});
                        if ~ischar(fieldValue) && length(fieldValue) > 1
                            if isnumeric(fieldValue)
                                fieldValue = sprintf('%g ', fieldValue);
                            else
                                error('Parameter values must be scalar or vectors of numbers.');
                            end
                        end
                        obj.epoch.ProtocolParameters.Add(fieldName{1}, fieldValue);
                    end
                    
                    obj.runEpoch();
                    
                    % Perform any post-epoch analysis, clean up, etc.
                    if ~strcmp(obj.state, 'stopping')
                        obj.completeEpoch();
                    end
                    
                    % Force any figures to redraw and any events (clicking the Pause or Stop buttons in particular) to get processed.
                    drawnow;
                end
            catch e
                waitfor(errordlg(['An error occurred while running the protocol.' char(10) char(10) getReport(e, 'extended', 'hyperlinks', 'off')]));
            end
            
            if strcmp(obj.state, 'pausing')
                obj.setState('paused');
            else
                % Perform any final analysis, clean up, etc.
                obj.completeRun();
            end
        end
        
        
        function pause(obj)
            % Set a flag that will be checked after the current epoch completes.
            obj.setState('pausing'); 
        end
        
        
        function stop(obj)
            if strcmp(obj.state, 'paused')
                obj.completeRun()
            else
                % Set a flag that will be checked after the controller stops the current run.
                obj.setState('stopping');
                
                obj.rigConfig.controller.CancelRun();
            end
        end
        
        
        function addEventListener(obj, source, eventName, callback)
            % Add an event listener to this protocol.
            % Be careful about the method you use to add event handlers; they persist until the protocol is destroyed
            % and will stack if you add the same listener more than once. In general only add listeners in your constructor.
            
            obj.listeners{end + 1} = addlistener(source, eventName, callback);
        end
        
        
        function delete(obj)
            % Delete all event listeners.
            while ~isempty(obj.listeners)
                delete(obj.listeners{1});
                obj.listeners(1) = [];
            end
        end
     
    end
    
    
    methods (Access = protected)
        
        function copy = copyElement(obj)
            copy = copyElement@matlab.mixin.Copyable(obj);
            
            % Copy all event listeners.
            copy.listeners = {};
            for i = 1:length(obj.listeners)
                listener = obj.listeners{i};
                copy.addEventListener(obj.rigConfig.controller, listener.EventName, listener.Callback);
            end
        end
        
    end
    
    
    methods
        
        % Figure handling methods.
        
        function handler = openFigure(obj, figureType, varargin)
            if ~isKey(obj.figureHandlerClasses, figureType)
                error('The ''%s'' figure handler is not available.', figureType);
            end
            
            handlerClass = obj.figureHandlerClasses(figureType);
            
            % Check if the figure is open already.
            for i = 1:length(obj.figureHandlers)
                if strcmp(class(obj.figureHandlers{i}), handlerClass) && isequal(obj.figureHandlerParams{i}, varargin)
                    handler = obj.figureHandlers{i};
                    handler.showFigure();
                    return
                end
            end
            
            % Create a new handler.
            constructor = str2func(handlerClass);
            handler = constructor(obj, varargin{:});
            addlistener(handler, 'FigureClosed', @(source, event)figureClosed(obj, source, event));
            obj.figureHandlers{end + 1} = handler;
            obj.figureHandlerParams{end + 1} = varargin;
        end
        
        
        function updateFigures(obj)
            for index = 1:numel(obj.figureHandlers)
                figureHandler = obj.figureHandlers{index};
                figureHandler.handleCurrentEpoch();
            end
        end
        
        
        function clearFigures(obj)
            for index = 1:numel(obj.figureHandlers)
                figureHandler = obj.figureHandlers{index};
                figureHandler.clearFigure();
            end
        end
        
        
        function closeFigures(obj)
            % Close any figures that were opened.
            while ~isempty(obj.figureHandlers)
                obj.figureHandlers{1}.close();
            end
        end
        
        
        function figureClosed(obj, handler, ~)
            % Remove the handler from our list.
            index = cellfun(@(x) x == handler, obj.figureHandlers);
            obj.figureHandlers(index) = [];
            obj.figureHandlerParams(index) = [];
        end
        
    end
    
end
