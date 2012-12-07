%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef SymphonyProtocol < handle & matlab.mixin.Copyable
    % Create a sub-class of this class to define a protocol.
    %
    % Interesting methods to override:
    % * prepareRun
    % * prepareEpoch
    % * completeEpoch
    % * continueRun
    % * completeRun
    %
    % Useful methods:
    % * addStimulus
    % * setDeviceBackground
    % * recordResponse
    
    %% Properties
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
        persistor = []              % The persistor to use with each epoch.
        epochKeywords = {}          % A cell array of string containing keywords to be applied to any upcoming epochs.
        protocolProperties = {}     % A Map that contains the properties and values for the protocol. This allows for multiple channels
        previousEpochProtocol = {}
    end
    
    properties
        sampleRate = {10000, 20000, 50000}      % in Hz        
    end
    
    
    properties (Hidden, SetAccess = private)
        multiClampMode = 'VClamp'
    end

    properties (SetAccess = public, GetAccess = private)
        % Logging Variables can be set by Symphony but can only be used by
        % the Symphony Protocol Class
        log = {}
        loggingHandles = {}
        hfig
        
        epochNumContinuous = 0
        
        epochGroup = {}
        prevEpochGroup = {}
        logFileFolders
        
        timeString = 'HH:MM:SS'    
	end
    
    events
        StateChanged
    end
    
    
    methods
        %% Constructor (Can be overriden in the protocol)
        function obj = SymphonyProtocol(logging, logFileFolders)
            obj = obj@handle();
            
            obj.setState('stopped');
            obj.responses = containers.Map();
            obj.protocolProperties = obj.createChannelParameters;
            obj.logFileFolders = logFileFolders;
            
            if logging && ~isempty(obj.logFileFolders)
                obj.openLog();
            end
            
            obj.protocolProperties = obj.createChannelParameters;
        end 

        %% Parameters for the Protocol
        
        % creating the protocol object that will be used within the
        % application it is built from the properties specified within the
        % protocol
        function p = createChannelParameters(obj)
            paramNames = properties(obj);
            pCount = numel(paramNames);
            
            p = containers.Map('KeyType','char','ValueType','any');
            
            tempCell{1,(obj.channels)} = [];
            
            for i = 1:pCount
                name = paramNames{i};
                prop = findprop(obj, paramNames{i});
                if ~prop.Dependent
                    value = obj.(name);
                    if ischar(value) || isnumeric(value) || islogical(value) || iscell(value)
                        if iscell(value)
                            tempCell{1,(obj.channels+1)} = cell(1,obj.channels);
                        end
                        
                        for j = 1:obj.channels
                            tempCell{1,j} = value;
                        end
                        p(name) = tempCell;
                    end
                end
            end
            
            setpref('Symphony', [class(obj) '_Defaults'], p);
        end
        
        % A function to return the value of the protocol
        function pPV = getProtocolPropertiesValue(obj, prop)
            [pPV, isC, isE] = isProtocolPropertiesValueCell(obj,prop);
            if isC && isE
                pPV = pPV{obj.selectedChannel}{1};    
            elseif isC
                pPV = pPV{obj.selectedChannel}{pPV{obj.channels + 1}{obj.selectedChannel}};
            else
                pPV = pPV{obj.selectedChannel};
            end
        end
        
        % A function that returns the property and allows a way for a quick
        % check to see if it is a cell and weather the pointer is empty
        function [pPV, isC, isE] = isProtocolPropertiesValueCell(obj,prop)
            pPV = obj.protocolProperties(prop);
            isC = iscell(pPV{obj.selectedChannel});
            if isC
                isE = isempty(pPV{obj.channels + 1}{obj.selectedChannel});
            else
                isE = false;
            end
        end
        
       %% Log Functions
       % sendToLog can either take a cell input or a string
       function sendToLog(obj,varargin)
           if nargin > 0 && (~isempty(obj.loggingHandles))
               s = get(obj.loggingHandles.edit3,'string');
               formatSpec ='%s\r%s';

                for v = 1:(nargin-1)
                    if isa(varargin{v},'cell')
                        for c = 1:length(varargin{v})
                             for l = 1:length(varargin{v}{c})  
                                s = sprintf(formatSpec,s,varargin{v}{c}{l}); 
                             end
                        end    
                    elseif ischar(varargin{v});
                        s = sprintf(formatSpec,s,varargin{v}); 
                    end
                end

                set(obj.loggingHandles.edit3,'string',s);
                obj.loggingHandles = guidata(obj.hfig);
           end
       end
       
       % A function to parse a simple text file
       function  parseFile(obj, s)
           if ~isempty(obj.loggingHandles)
               fid = fopen(s, 'r');
               logFileHeader = textscan(fid, '%s', 'Delimiter', '\n');
               fclose(fid);
               
               obj.sendToLog(logFileHeader);
           end
       end
       
       % A function to open the log file       
       function openLog(obj)
            obj.log = logFile(obj.logFileFolders);
            set(0, 'showHiddenHandles', 'on');
            obj.hfig = gcf;
            obj.loggingHandles = guidata(obj.hfig);
            
            dateStamp = datestr(now, 'mm_dd_yy');
            formatString = '%s%s%s%s';
            currentFile = sprintf(formatString,obj.logFileFolders{1},'\',dateStamp,'.log');
            
            if exist(currentFile, 'file') == 2
                obj.parseFile(currentFile);
            elseif isprop(obj,'logFileHeaderFile') && ~isempty(obj.logFileHeaderFile) && exist(obj.logFileHeaderFile, 'file') == 2
                obj.parseFile(obj.logFileHeaderFile);   
            end    
       end 
       
       %A function to close the log file
       function closeLog(obj)
           if ~isempty(obj.loggingHandles)
               logFile('save_Callback',obj.loggingHandles.edit3,[],obj.loggingHandles,obj.logFileFolders);
               delete(obj.log)
               obj.loggingHandles = {};
               obj.epochNumContinuous = 0;
           end
       end
       
       %A function to send information about created epoch groups through
       %to the log file
       function logEpochGroup(obj)
            if ~isempty(obj.loggingHandles) && ...
               ~isempty(obj.epochGroup) && ...
               ~isequal(obj.prevEpochGroup, obj.epochGroup)
                if isempty(obj.epochGroup.parentGroup)
                    formatSpec = '\r\rPARENT GROUP (CELL)\rTIME: %s\rID: %s\rLabel: %s\rKeywords: %s\rSource: %s\rMouse ID: %s\rCell ID: %s\rRig Name: %s'; 
                    s = sprintf(formatSpec, ...
                    datestr(now,obj.timeString), ...
                    obj.epochGroup.source.name, ...
                    obj.epochGroup.label, ...
                    obj.epochGroup.keywords, ...
                    obj.epochGroup.source.parentSource.name ,...
                    obj.epochGroup.userProperties.mouseID, ...
                    obj.epochGroup.userProperties.cellID, ...
                    obj.epochGroup.userProperties.rigName);
                    obj.epochNumContinuous = 0;
                else
                    formatSpec = '\rCHILD GROUP:\rLabel: %s\rKeywords: %s'; 
                    s = sprintf(formatSpec, ...
                    obj.epochGroup.label, ...
                    obj.epochGroup.keywords);
                end
                    
                obj.sendToLog(s);
                obj.prevEpochGroup = obj.epochGroup;
             end   
       end
       
       %% Heat Recording
       function average = recordSolutionTemp(obj)
            recordedTemp = obj.response('HeatSync');
            samples = length(recordedTemp); 
            total = 0;
            
            for i = 1:samples
                total = total + recordedTemp(i);
            end
            
            %The total is multiplied by 10 as the Heat Controller response
            %is a factor of 10 lower then the actual value.
            average = 10 * (total/samples);
            
             m = 3; % Number of significant decimals
             k = floor(log10(abs(average)))-m+1;
             average = round(average/10^k)*10^k;
       end
       
       %% Symphony Functions
        function setState(obj, state)
            obj.state = state;
            notify(obj, 'StateChanged');
        end
        
        function dn = requiredDeviceNames(obj) %#ok<MANU>
            % Override this method to indicate the names of devices that are required for this protocol.
            dn = {};
        end
        
        function prepareRig(obj)            
            obj.rigConfig.sampleRate = obj.getProtocolPropertiesValue('sampleRate');
            if ~isempty(obj.loggingHandles)
                formatSpec = '\rTIME:%s\rRIG: %s\rPROTOCOL: %s\r';    
                s = sprintf(formatSpec,datestr(now,obj.timeString),obj.rigConfig.displayName,obj.displayName);
                obj.sendToLog(s);
            end
        end
        
        function prepareRun(obj)
            % Override this method to perform any actions before the start of the first epoch, e.g. open a figure window, etc.
            obj.epoch = [];
            obj.epochNum = 0;
            obj.clearFigures()
            
            if ~isempty(obj.loggingHandles) && isprop(obj, 'propertiesToLog')
                if ~isempty(obj.propertiesToLog)
                    count = numel(obj.propertiesToLog);
                    
                    s = '';
                    x = 1;

                    for f = 1:count
                        value=obj.getProtocolPropertiesValue((obj.propertiesToLog{f})); 
                        
                        if f == 1
                            formatSpec = '\r%s%s = %s  ';
                        else
                            formatSpec = '%s%s = %s  ';
                        end

                        if ~ischar(value)
                            if f == 1
                                formatSpec ='\r%s%s = %i  ';
                            else
                                formatSpec ='%s%s = %i  ';
                            end
                            
                            if isequal(obj.propertiesToLog{f},'preSynapticHold') ...
                                    && f == count
                                formatSpec = '%s\r        %s = %i  ';
                            end
                        end

                        s = sprintf(formatSpec,s,obj.propertiesToLog{f},value);
                        x = x + 1;
                    end    
                    
                    obj.sendToLog(s);
                    clear s formatSpec
                end
            end
        end
                
        function stimuli = sampleStimuli(obj) %#ok<MANU>
            stimuli = {};
        end
        
        function prepareEpoch(obj)
            % Override this method to add stimulii, record responses, change parameters, etc.
            
            import Symphony.Core.*;
            
            % Create a new epoch.
            obj.epochNum = obj.epochNum + 1;
            obj.epochNumContinuous = obj.epochNumContinuous + 1;
            obj.epoch = Epoch(obj.identifier);

            % Add any keywords specified by the user.
            for i = 1:length(obj.epochKeywords)
                obj.epoch.Keywords.Add(obj.epochKeywords{i});
            end
            
            % Set the default background value and record any input streams for each device.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                % Set each device's background for this epoch to be the same as the inter-epoch background.
                obj.setDeviceBackground(device.Name, device.Background);
                
                % Record the response from any device that has an input stream.
                [~, streams] = dictionaryKeysAndValues(device.Streams);
                for j = 1:length(streams)
                    if isa(streams{j}, 'Symphony.Core.DAQInputStream')
                        obj.recordResponse(device.Name);
                        break
                    end
                end
            end
            
            % Clear out the cache of responses.
            obj.responses = containers.Map();
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
              if ~isempty(obj.previousEpochProtocol)
                p = structDiff(dictionaryToStruct(obj.epoch.ProtocolParameters), dictionaryToStruct(obj.previousEpochProtocol));
              else
                p = dictionaryToStruct(obj.epoch.ProtocolParameters);
              end
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
        
        function addStimulus(obj, deviceName, stimulusID, stimulusData, units)
            % Queue data to send to the named device when the epoch is run.
            
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
                units = 'V';
                stimDataList = Measurement.FromArray(stimulusData, units);
            end
            
            outputData = OutputData(stimDataList, obj.deviceSampleRate(device, 'OUT'), true);
            
            stim = RenderedStimulus(stimulusID, units, structToDictionary(struct()), outputData);
            
            obj.epoch.Stimuli.Add(device, stim);
        end
        
        function setDeviceBackground(obj, deviceName, background, units, lightMean)
            % Set a constant stimulus value to be sent to the device.
            
            import Symphony.Core.*;
            
            device = obj.rigConfig.deviceWithName(deviceName);
            
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            if nargin == 5 && strcmp(lightMean,'lightMean')
                sendVoltage = true;
            else
                sendVoltage = false;
            end
            
            if nargin == 4 || nargin == 5
                backgroundSCM = Measurement(background, units);
            elseif isnumeric(background)
                backgroundSCM = Measurement(background, 'V');
            elseif isa(background, 'Symphony.Core.Measurement')
                backgroundSCM = background;
                sendVoltage = false;
            else
                error('Symphony:InvalidBackground', 'The background value for a device must be a number or a Symphony.Core.Measurement');
            end
            
            if sendVoltage
                obj.rigConfig.setDeviceBackground(deviceName, backgroundSCM, background);
            else
                obj.rigConfig.setDeviceBackground(deviceName, backgroundSCM);
            end
            
            if ~isempty(obj.epoch)
                obj.epoch.SetBackground(device, backgroundSCM, obj.deviceSampleRate(device, 'OUT'));
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
                % TODO: what happens when there is no device with that name?
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
                    u = char(Measurement.HomogenousUnits(data));
                    
                    s = System.Decimal.ToDouble(response.SampleRate.QuantityInBaseUnit);
                    % TODO: do we care about the units of the SampleRate measurement?
                catch ME %#ok<NASGU>
                    r = [];
                    u = '';
                    s = 0;
                end

                % Cache the results.
                obj.responses(deviceName) = struct('data', r, 'sampleRate', s, 'units', u);
            end
        end 
                    
        function completeEpoch(obj)
            % Override this method to perform any post-analysis, etc. on the current epoch.
            if ~isempty(obj.loggingHandles)
                if obj.rigConfig.isDevice('HeatSync')
                    formatSpec = '            Epoch # %u     Start Time:%u:%u:%u      Duration (ms):%u      Temperature (degrees celsius):%g';
                    s = sprintf(formatSpec, ...
                        obj.epochNumContinuous, ...
                        obj.epoch.StartTime.Item2.DateTime.Hour, ...
                        obj.epoch.StartTime.Item2.DateTime.Minute, ...
                        obj.epoch.StartTime.Item2.DateTime.Second, ...
                        obj.epoch.Duration.Item2.TotalMilliseconds, ...
                        obj.recordSolutionTemp);
                else
                     formatSpec = '            Epoch # %u     Start Time:%u:%u:%u      Duration (ms):%u';
                    s = sprintf(formatSpec, ...
                        obj.epochNumContinuous, ...
                        obj.epoch.StartTime.Item2.DateTime.Hour, ...
                        obj.epoch.StartTime.Item2.DateTime.Minute, ...
                        obj.epoch.StartTime.Item2.DateTime.Second, ...
                        obj.epoch.Duration.Item2.TotalMilliseconds);
                end
                obj.sendToLog(s);
            end
            obj.updateFigures();
            obj.previousEpochProtocol = obj.epoch.ProtocolParameters;
        end     
         
        function keepGoing = continueRun(obj)
            % Override this method to return true/false based on the current state.
            % The object's epochNum is typically useful.
            
            keepGoing = strcmp(obj.state, 'running');
        end
        
        function completeRun(obj)
            % Override this method to perform any actions after the last epoch has completed.
            if ~isempty(obj.loggingHandles)
                logFile('save_Callback',obj.loggingHandles.edit3,[],obj.loggingHandles,obj.logFileFolders);
            end
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
                                        
                    paramNames = properties(obj);
                    pCount = numel(paramNames);
                    
                    for i = 1:pCount
                        prop = findprop(obj, paramNames{i});
                        if ~prop.Dependent
                            name = paramNames{i};
                            value = obj.getProtocolPropertiesValue(name);
                            
                            if ~ischar(value) && length(value) > 1
                                if isnumeric(value)
                                    value = sprintf('%g ', value);
                                else
                                    error('Parameter values must be scalar or vectors of numbers.');
                                end
                            end
                            obj.epoch.ProtocolParameters.Add(name, value);
                        end 
                    end
                    
                    try
                        % Tell the Symphony framework to run the epoch.
                        obj.rigConfig.controller.RunEpoch(obj.epoch, obj.persistor);
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
                    
                    % Perform any post-epoch analysis, clean up, etc.
                    obj.completeEpoch();
                    
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
                % Set a flag that will be checked after the current epoch completes.
                obj.setState('stopping');
            end
        end
        
        function m = get.multiClampMode(obj)
            try
                m = obj.rigConfig.multiClampMode();
            catch ME
                m = ['unknown (' ME.message ')'];
            end
        end
        
    
        %% Figure handeling Methods 
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