function Symphony()
    
    % Add our utility folder to the search path.
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    addpath(fullfile(parentDir, filesep, 'Utility'));
    
    if isempty(which('NET.createGeneric'))
        addpath(fullfile(parentDir, filesep, 'Stubs'));
    else
        symphonyPath = 'C:\Program Files\Physion\Symphony';

        % Add Symphony.Core assemblies
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.Core.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.ExternalDevices.dll'));
        %NET.addAssembly(fullfile(symphonyPath, 'HekaDAQInterface.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.SimulationDAQController.dll'));
    end
    
    showMainWindow();
end


function controller = createSymphonyController(daqName, sampleRate)
    import Symphony.Core.*;
    import Symphony.SimulationDAQController.*;
    import Heka.*;
    
%    % Register Unit Converters
%    HekaDAQInputStream.RegisterConverters();
%    HekaDAQOutputStream.RegisterConverters();
    
    % Create Symphony.Core.Controller
    
    controller = Controller();
    
    if(strcmpi(daqName, 'heka'))
        daq = HekaDAQController(1, 0); %PCI18 = 1, USB18=5
        daq.SampleRate = sampleRate;
        
        % Finding input and output streams by name
        outStream = daq.GetStream('ANALOG_OUT.0');
        inStream = daq.GetStreams('ANALOG_IN.0');
    elseif(strcmpi(daqName, 'simulation'))
        if ~isempty(which('NET.createGeneric'))
            Symphony.Core.Converters.Register('V','V', @(m) m);
        end
        daq = SimulationDAQController();
        
        outStream = DAQOutputStream('OUT');
        outStream.SampleRate = sampleRate;
        outStream.MeasurementConversionTarget = 'V';
        outStream.Clock = daq;
        daq.AddStream(outStream);
        
        inStream = DAQInputStream('IN');
        inStream.SampleRate = sampleRate;
        inStream.MeasurementConversionTarget = 'V';
        inStream.Clock = daq;
        daq.AddStream(inStream);
        
        daq.SimulationRunner = Simulation(@(output,step) loopbackSimulation(output, step, outStream, inStream));
       
    else
        error(['Unknown daqName: ' daqName]);
    end
        
    daq.Clock = daq;
    daq.Setup();
    
    controller.DAQController = daq;
    controller.Clock = daq;
    
    % Create external device and bind streams
    % TODO: set default background?
    dev = ExternalDevice('test-device', controller, Measurement(0, 'V'));
    dev.Clock = daq;
    dev.MeasurementConversionTarget = 'V';
    dev.BindStream(outStream);
    dev.BindStream('input', inStream);
end


function input = loopbackSimulation(output, ~, outStream, inStream)
    import Symphony.Core.*;
    
    if ~isempty(which('NET.createGeneric'))
        input = NET.createGeneric('System.Collections.Generic.Dictionary', {'Symphony.Core.IDAQInputStream','Symphony.Core.IInputData'});
        time = System.DateTimeOffset.Now;
    else
        input = GenericDictionary();
        time = now;
    end
    outData = output.Item(outStream);
    inData = InputData(outData.Data, outData.SampleRate, time, inStream.Configuration);
    input.Add(inStream, inData);
end


function showMainWindow()
    import Symphony.Core.*;
    
    if isempty(which('NET.createGeneric'))
        sampleRate = Measurement(10000, 'Hz');
    else
        sampleRate = Symphony.Core.Measurement(10000, 'Hz');
    end
    handles.controller = createSymphonyController('simulation', sampleRate);
    
    % Get the list of protocols from the 'Protocols' folder.
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    protocolsDir = fullfile(parentDir, filesep, 'Protocols');
    protocolDirs = dir(protocolsDir);
    handles.protocolClassNames = cell(length(protocolsDir), 1);
    protocolCount = 0;
    for i = 1:length(protocolDirs)
        if protocolDirs(i).isdir && ~strcmp(protocolDirs(i).name, '.') && ~strcmp(protocolDirs(i).name, '..') && ~strcmp(protocolDirs(i).name, '.svn')
            protocolCount = protocolCount + 1;
            handles.protocolClassNames{protocolCount} = protocolDirs(i).name;
            addpath(fullfile(protocolsDir, filesep, protocolDirs(i).name));
        end
    end
    handles.protocolClassNames = sort(handles.protocolClassNames(1:protocolCount));
    
    handles.figure = figure(...
        'Units', 'points', ...
        'Menubar', 'none', ...
        'Name', 'Symphony', ...
        'NumberTitle', 'off', ...
        'Position', centerWindowOnScreen(364, 280), ...
        'UserData', [], ...
        'Tag', 'figure');

    handles.startButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)startAcquisition(hObject,eventdata,guidata(hObject)), ...
        'Position', [7.2 252 56 20.8], ...
        'String', 'Start', ...
        'Tag', 'startButton');

    handles.stopButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)stopAcquisition(hObject,eventdata,guidata(hObject)), ...
        'Enable', 'off', ...
        'Position', [61.6 252 56 20.8], ...
        'String', 'Stop', ...
        'Tag', 'stopButton');
    
    % TODO: should param editor pop-up automatically the first time?
    handles.protocolPopup = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)chooseProtocol(hObject,eventdata,guidata(hObject)), ...
        'Position', [224.8 251.2 130.4 21.6], ...
        'String', {  'Pop-up Menu' },...
        'Style', 'popupmenu', ...
        'String', handles.protocolClassNames, ...
        'Value', 1,...
        'Tag', 'protocolPopup');

    uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [168 255.2 56.8 17.6], ...
        'String', 'Protocol:', ...
        'Style', 'text', ...
        'Tag', 'text1');

    handles.saveEpochsCheckbox = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'Position', [7.2 222.4 100.8 18.4], ...
        'String', 'Save Epochs', ...
        'Style', 'checkbox', ...
        'Tag', 'saveEpochsCheckbox');

    uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [10.4 192.8 56.8 17.6], ...
        'String', 'Keywords:', ...
        'Style', 'text', ...
        'Tag', 'text2');

    handles.keywordsEdit = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)keywordsEditCallback(hObject,eventdata,guidata(hObject)), ...
        'FontSize', 12,...
        'HorizontalAlignment', 'left', ...
        'Position', [79 189 273 26], ...
        'String', blanks(0), ...
        'Style', 'edit', ...
        'Tag', 'keywordsEdit');

    handles.epochPanel = uipanel(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'Title', 'Epoch Group', ...
        'Tag', 'uipanel1', ...
        'Clipping', 'on', ...
        'Position', [13 70 336 111]);

    uicontrol(...
        'Parent', handles.epochPanel,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [8 74.4 67.2 17.6], ...
        'String', 'Output path:', ...
        'Style', 'text', ...
        'Tag', 'text3');

    handles.epochGroupOutputPathText = uicontrol(...
        'Parent', handles.epochPanel,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'left', ...
        'Position', [77.6 74.4 250.4 17.6], ...
        'String', blanks(0), ...
        'Style', 'text', ...
        'Tag', 'epochGroupOutputPathText');

    uicontrol(...
        'Parent', handles.epochPanel,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [8 58.4 67.2 17.6], ...
        'String', 'Label:', ...
        'Style', 'text', ...
        'Tag', 'text5');

    handles.epochGroupLabelText = uicontrol(...
        'Parent', handles.epochPanel,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'left', ...
        'Position', [77.6 58.4 250.4 17.6], ...
        'String', blanks(0), ...
        'Style', 'text', ...
        'Tag', 'epochGroupLabelText');

    uicontrol(...
        'Parent', handles.epochPanel,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [8 42.4 67.2 17.6], ...
        'String', 'Source:', ...
        'Style', 'text', ...
        'Tag', 'text7');

    handles.epochGroupSourceText = uicontrol(...
        'Parent', handles.epochPanel,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'left', ...
        'Position', [77.6 42.4 250.4 17.6], ...
        'String', blanks(0), ...
        'Style', 'text', ...
        'Tag', 'epochGroupSourceText');

    handles.newEpochGroupButton = uicontrol(...
        'Parent', handles.epochPanel,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)newEpochGroupCallback(hObject,eventdata,guidata(hObject)), ...
        'Position', [224.8 9.6 97.6 20.8], ...
        'String', 'New Epoch Group', ...
        'Tag', 'newEpochGroupButton');

    handles.experimentPanel = uipanel(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'Title', 'Experiment', ...
        'Tag', 'experimentPanel', ...
        'Clipping', 'on', ...
        'Position', [14.4 16.8 333.6 41.6]);

    uicontrol(...
        'Parent', handles.experimentPanel,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [6.4 7.2 67.2 17.6], ...
        'String', 'Mouse ID:', ...
        'Style', 'text', ...
        'Tag', 'text9');

    handles.mouseIDText = uicontrol(...
        'Parent', handles.experimentPanel,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'left', ...
        'Position', [76 7.2 250.4 17.6], ...
        'String', blanks(0), ...
        'Style', 'text', ...
        'Tag', 'mouseIDText');

    guidata(handles.figure, handles);
end


function chooseProtocol(~, ~, handles)
    pluginIndex = get(handles.protocolPopup, 'Value');
    pluginClassName = handles.protocolClassNames{pluginIndex};
    
    if ~isfield(handles, 'pluginInstance') || ~isa(handles.pluginInstance, pluginClassName)
        handles.pluginInstance = eval([pluginClassName '(handles.controller)']);
        guidata(handles.figure, handles);
        
        % Use any previously set parameters.
        params = getpref('ProtocolDefaults', class(handles.pluginInstance), struct);
        paramNames = fieldnames(params);
        for i = 1:numel(paramNames)
            handles.pluginInstance.(paramNames{i}) = params.(paramNames{i});
        end

        editParameters(handles.pluginInstance);
    end
end


function editParameters(pluginInstance)
    handles.pluginInstance = pluginInstance;
    
    params = pluginInstance.parameters();
    paramNames = sort(fieldnames(params));
    paramCount = numel(paramNames);
    
    dialogHeight = paramCount * 30 + 50;
    
    handles.figure = dialog(...
        'Units', 'points', ...
        'Name', [class(pluginInstance) ' Parameters'], ...
        'Position', centerWindowOnScreen(325, dialogHeight), ...
        'WindowKeyPressFcn', @(hObject, eventdata)editParametersKeyPress(hObject, eventdata, guidata(hObject)), ...
        'Tag', 'figure');
    
    uicontrolcolor = reshape(get(0,'defaultuicontrolbackgroundcolor'),[1,1,3]);

    % array for pushbutton's CData
    button_size = 16;
    mid = button_size/2;
    push_cdata = repmat(uicontrolcolor,button_size,button_size);
    for r = 4:11
        start = mid - r + 8 ;
        last = mid + r - 8;
        push_cdata(r,start:last,:) = 0;
    end
    

    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramValue = params.(paramName);
        
        paramLabel = regexprep(paramName, '([^A-Z])([A-Z])', '$1 $2');
        paramLabel = strrep(paramLabel, '_', ' ');
        paramLabel(1) = upper(paramLabel(1));

        uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'FontSize', 12,...
            'HorizontalAlignment', 'right', ...
            'Position', [10 dialogHeight-paramIndex*30 100 18], ...
            'String',  paramLabel,...
            'Style', 'text');
        
        paramTag = [paramName 'Edit'];
        if isinteger(paramValue) 
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'HorizontalAlignment', 'left', ...
                'Position', [115 dialogHeight-paramIndex*30-2 189 26], ...
                'String',  num2str(paramValue),...
                'Style', 'edit', ...
                'Tag', paramTag);
            uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'Position', [301 dialogHeight-paramIndex*30+10 12 12], ...
                'CData', push_cdata, ...
                'Callback', @(hObject,eventdata)stepValueUp(hObject, eventdata, guidata(hObject), paramTag));
            uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'Position', [301 dialogHeight-paramIndex*30-1 12 12], ...
                'CData', flipdim(push_cdata, 1), ...
                'Callback', @(hObject,eventdata)stepValueDown(hObject, eventdata, guidata(hObject), paramTag));
        elseif islogical(paramValue)
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'Position', [115 dialogHeight-paramIndex*30-2 200 26], ...
                'Value', paramValue, ...
                'Style', 'checkbox', ...
                'Tag', paramTag);
        elseif isnumeric(paramValue) || ischar(paramValue)
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'HorizontalAlignment', 'left', ...
                'Position', [115 dialogHeight-paramIndex*30-2 200 26], ...
                'String',  paramValue,...
                'Style', 'edit', ...
                'Tag', paramTag);
        else
            error('Unhandled param type');
        end
    end
    
    handles.cancelButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)cancelEditParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [10 10 56 20], ...
        'String', 'Cancel', ...
        'Tag', 'cancelButton');
    
    handles.saveButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)saveEditParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [80 10 56 20], ...
        'String', 'Save', ...
        'Tag', 'saveButton');
    
    guidata(handles.figure, handles);
end


function editParametersKeyPress(hObject, eventdata, handles)
    if strcmp(eventdata.Key, 'return')
        % Move focus off of any edit text so the changes can be seen.
        uicontrol(handles.saveButton);
        
        saveEditParameters(hObject, eventdata, handles);
    elseif strcmp(eventdata.Key, 'escape')
        cancelEditParameters(hObject, eventdata, handles);
    end
end


function stepValueUp(~, ~, handles, paramTag)
    curValue = int32(str2double(get(handles.(paramTag), 'String')));
    set(handles.(paramTag), 'String', num2str(curValue + 1));
end


function stepValueDown(~, ~, handles, paramTag)
    curValue = int32(str2double(get(handles.(paramTag), 'String')));
    set(handles.(paramTag), 'String', num2str(curValue - 1));
end


function cancelEditParameters(~, ~, handles)
    close(handles.figure);
end


function saveEditParameters(~, ~, handles)
    params = handles.pluginInstance.parameters();
    paramNames = sort(fieldnames(params));
    paramCount = numel(paramNames);
    
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramTag = [paramName 'Edit'];
        if isnumeric(params.(paramName))
            paramValue = str2num(get(handles.(paramTag), 'String')); %#ok<ST2NM>
        elseif islogical(params.(paramName))
            paramValue = get(handles.(paramTag), 'Value') == get(handles.(paramTag), 'Max');
        elseif ischar(params.(paramName))
            paramValue = get(handles.(paramTag), 'String');
        end
        handles.pluginInstance.(paramName) = paramValue;
    end
    
    % Remember these parameters for the next time the protocol is used.
    setpref('ProtocolDefaults', class(handles.pluginInstance), handles.pluginInstance.parameters());
    
    close(handles.figure);
end


function startAcquisition(~, ~, handles)
    import Symphony.Core.*;
    
    xmlPath = get(handles.epochGroupOutputPathText, 'String');
    if isempty(xmlPath)
        xmlPath = uiputfile();
        if xmlPath == 0
            return
        end
    end
    persistor = EpochXMLPersistor(xmlPath);
    
    if isempty(which('NET.createGeneric'))
        parents = GenericList();
        sources = GenericList();
        keywords = GenericList();
        uid = char(java.util.UUID.randomUUID());
    else
        parents = NET.createArray('System.String',  0);
        sources = NET.createArray('System.String',  0);
        keywords = NET.createArray('System.String',  0);
        uid = System.Guid.NewGuid();
    end
    % TODO: populate parents, sources and keywords
    label = get(handles.epochGroupLabelText, 'String');
    
    runProtocol(handles.pluginInstance, persistor, label, parents, sources, keywords, uid);
end


function runProtocol(pluginInstance, persistor, label, parents, sources, keywords, identifier)
    import Symphony.Core.*;
    
    % Open a figure window to show the response of each epoch.
    figure('Name', [class(pluginInstance) ': Response'], ...
           'NumberTitle', 'off');
    responseAxes = axes('Position', [0.1 0.1 0.85 0.85]);
    responsePlot = plot(responseAxes, 1:100, zeros(1, 100));
    xlabel(responseAxes, 'sec');
    drawnow expose;
    
    % Set up the persistor.
    persistor.BeginEpochGroup(label, parents, sources, keywords, identifier);
    
    try
        % Initialize the run.
        pluginInstance.epoch = [];
        pluginInstance.epochNum = 0;
        pluginInstance.prepareEpochGroup()

        % Loop through all of the epochs.
        while pluginInstance.continueEpochGroup()
            % Create a new epoch.
            pluginInstance.epochNum = pluginInstance.epochNum + 1;
            pluginInstance.epoch = Epoch(pluginInstance.identifier);

            % Let sub-classes add stimulii, record responses, tweak params, etc.
            pluginInstance.prepareEpoch();

            % Set the params now that the sub-class has had a chance to tweak them.
            pluginInstance.epoch.ProtocolParameters = structToDictionary(pluginInstance.parameters());

            % Run the epoch.
            try
                pluginInstance.controller.RunEpoch(pluginInstance.epoch, persistor);
                
                persistor.Serialize(pluginInstance.epoch);
                
                % Plot the response.
                 [responseData, sampleRate, units] = pluginInstance.response();
                 duration = numel(responseData) / sampleRate;
                 samplesPerTenth = sampleRate / 10;
                 set(responsePlot, 'XData', 1:numel(responseData), ...
                                   'YData', responseData);
                 set(responseAxes, 'XTick', 1:samplesPerTenth:numel(responseData), ...
                                   'XTickLabel', 0:.1:duration);
                 ylabel(responseAxes, units);
                 drawnow expose;
            catch e
                % TODO: is it OK to hold up the run with the error dialog or should errors be displayed at the end?
                if (isa(e, 'NET.NetException'))
                    eObj = e.ExceptionObject;
                    ed = errordlg(char(eObj.Message));
                else
                    ed = errordlg(e.message);
                end
                waitfor(ed);
            end
            
            % Let the sub-class perform any post-epoch analysis, clean up, etc.
            pluginInstance.completeEpoch();
        end
    catch e
        ed = errordlg(e.message);
        waitfor(ed);
    end
    
    % Let the sub-class perform any final analysis, clean up, etc.
    pluginInstance.completeEpochGroup();
    
    persistor.EndEpochGroup();
    persistor.Close();
end
