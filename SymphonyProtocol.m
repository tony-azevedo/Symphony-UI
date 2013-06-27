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

classdef SymphonyProtocol < handle & matlab.mixin.Copyable
    
    properties (Constant, Abstract)
        identifier                  % It is recommended to use reverse domain name notation.
        version
        displayName
    end
    
    
    properties (Hidden)
        symphonyConfig              % The Symphony configuration prepared by symphonyrc.
        state                       % The state the protocol is in: 'stopped', 'running', 'paused', etc.
        rigConfig                   % A RigConfiguration instance.
        rigPrepared = false         % A flag indicating whether the rig is ready to run this protocol.
        figureHandlerClasses
        figureHandlers = {}
        figureHandlerParams = {}
        allowSavingEpochs = true    % An indication if this protocol allows it's data to be persisted.
        allowPausing = true         % An indication if this protocol allows pausing during acquisition.
        persistor = []              % The persistor to use with each epoch.
        epochKeywords = {}          % A cell array of string containing keywords to be applied to any upcoming epochs.
        numQueuedEpochs
        numCompletedEpochs
    end
    
    
    properties
        sampleRate = {10000, 20000, 50000}      % in Hz
    end
    
    
    events
        StateChanged
    end
    
    
    methods
        
        function obj = init(obj, symphonyConfig, rigConfig)
            % This method is essentially a constructor. If you need to override the constructor, override this instead.
            
            obj.setState('stopped');
            obj.symphonyConfig = symphonyConfig;
            obj.rigConfig = rigConfig;
        end
        
        
        function setState(obj, state)
            obj.state = state;
            notify(obj, 'StateChanged');
        end
            
        
        function dn = requiredDeviceNames(obj) %#ok<MANU>
            % Override this method to indicate the names of devices that are required for this protocol.
            dn = {};
        end
        
        
        function [c , msg] = isCompatibleWithRigConfig(obj, rigConfig)            
            c = true;
            msg = '';
            
            deviceNames = obj.requiredDeviceNames();
            for i = 1:length(deviceNames)
                device = rigConfig.deviceWithName(deviceNames{i});
                if isempty(device)
                    c = false;
                    msg = ['The protocol cannot be run because there is no ''' deviceNames{i} ''' device.'];
                    break;
                end                
            end
        end
        
        
        function prepareRig(obj)
            % Override this method to perform any actions to get the rig ready for running the protocol, e.g. setting device backgrounds, etc.
            
            obj.rigConfig.sampleRate = obj.sampleRate;
        end
        
        
        function prepareRun(obj)
            % Override this method to perform any actions before the start of the first epoch, e.g. open a figure window, etc.
            
            import Symphony.Core.*;
            
            obj.numQueuedEpochs = 0;
            obj.numCompletedEpochs = 0;
            obj.clearFigures();
            
            % Set a default background for all devices.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                obj.rigConfig.setBackground(char(device.Name), device.Background);  
            end
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
      
        
        function prepareEpoch(obj, epoch)
            % Override this method to add stimuli, record responses, change parameters, etc.
            
            import Symphony.Core.*;

            % Add any keywords specified by the user.
            for i = 1:length(obj.epochKeywords)
                epoch.AddKeyword(obj.epochKeywords{i});
            end
            
            % Set the default background value and record any input streams for each device.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                % Set the default epoch background to be the same as the inter-epoch background.
                epoch.setBackground(char(device.Name), device.Background.Quantity, device.Background.DisplayUnit);
                
                % Record the response from any device that has an input stream.
                [~, streams] = dictionaryKeysAndValues(device.Streams);
                for j = 1:length(streams)
                    if isa(streams{j}, 'Symphony.Core.DAQInputStream')
                        epoch.recordResponse(char(device.Name));
                        break
                    end
                end
            end
        end
        
        
        function p = epochSpecificParameters(obj, epoch)
            % Determine the parameters unique to the current epoch.
            % TODO: diff against the previous epoch's parameters instead?
            protocolParams = obj.parameters();
            p = structDiff(epoch.parameters, protocolParams);
        end
        
        
        function queueEpoch(obj, epoch)
            obj.rigConfig.controller.EnqueueEpoch(epoch.getCoreEpoch);
            obj.numQueuedEpochs = obj.numQueuedEpochs + 1;
        end
        
        
        function runEpoch(obj, epoch)
            % This is a core method that runs the current epoch prepared by the protocol.
            
            import Symphony.Core.*;
            
            nameConverter = @(name)obj.rigConfig.deviceWithName(name);
            
            epochCompleted = addlistener(obj.rigConfig.controller, 'CompletedEpoch', ...
                @(src, data) obj.completeEpoch(EpochWrapper(data.Epoch, nameConverter)));
            
            clean = onCleanup(@()delete(epochCompleted));
            
            % Tell the Symphony framework to run the epoch in the background.
            obj.queueEpoch(epoch);
            task = obj.rigConfig.controller.StartAsync(obj.persistor);

            % Spin until the run completes, listening for events.
            while obj.rigConfig.controller.Running
                % Need a small pause to stop Matlab from grinding to a halt.
                pause(0.01);
            end
            
            if task.IsFaulted
                % TODO: is it OK to hold up the run with the error dialog or should errors be logged and displayed at the end?
                message = ['An error occurred while running the protocol.' char(10) char(10)];
                message = [message netReport(NET.NetException('', '', task.Exception.Flatten()))];
                waitfor(errordlg(message));
            end 
        end
        
        
        function completeEpoch(obj, epoch)
            % Override this method to perform any post-analysis, etc. on the current epoch.
            obj.updateFigures(epoch);
            obj.numCompletedEpochs = obj.numCompletedEpochs + 1;
            
            obj.rigConfig.controller.RequestStop();
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
            
            import Symphony.Core.*;
            
            try
                if ~strcmp(obj.state, 'paused')
                    % Prepare the run.
                    obj.prepareRun()
                end
                
                obj.setState('running');
                
                % Loop until the protocol or the user tells us to stop.
                while obj.continueRun()
                    % Run a single epoch.
                    
                    % Create wrapped core epoch.
                    nameConverter = @(name)obj.rigConfig.deviceWithName(name);
                    epoch = EpochWrapper(Epoch(obj.identifier), nameConverter);
                    
                    % Prepare the epoch: set backgrounds, add stimuli, record responses, add parameters, etc.
                    obj.prepareEpoch(epoch);
                    
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
                        epoch.addParameter(fieldName{1}, fieldValue);
                    end
                                        
                    obj.runEpoch(epoch);
                    
                    % Perform any post-epoch analysis, clean up, etc.
                    %if ~strcmp(obj.state, 'stopping')
                    %    obj.completeEpoch(epoch);
                    %end
                    
                    % Force any figures to redraw and any events (clicking the Pause or Stop buttons in particular) to get processed.
                    drawnow;
                end
            catch e
                obj.rigConfig.controller.RequestStop();
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
            
            obj.rigConfig.controller.RequestPause();
        end
        
        
        function stop(obj)
            if strcmp(obj.state, 'paused')
                obj.completeRun()
            else
                % Set a flag that will be checked after the controller stops the current run.
                obj.setState('stopping');
                
                obj.rigConfig.controller.RequestStop();
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
        
        
        function updateFigures(obj, epoch)
            for index = 1:numel(obj.figureHandlers)
                figureHandler = obj.figureHandlers{index};
                figureHandler.handleEpoch(epoch);
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
