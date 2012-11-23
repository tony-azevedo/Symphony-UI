%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function edited = editParameters(protocol)
handles.protocol = protocol;
handles.protocolCopy = copy(protocol);

params = handles.protocolCopy.protocolProperties;
paramChannel = handles.protocolCopy.selectedChannel;
channels = handles.protocolCopy.channels;
paramNames = keys(params);
paramCount = params.Count;

defaultProperties = getpref('Symphony', [class(handles.protocol) '_Defaults']);

stimuli = handles.protocolCopy.sampleStimuli();
handles.showStimuli = ~isempty(stimuli);

% TODO: determine the width from the actual labels using textwrap.
labelWidth = 120;

paramsHeight = (paramCount+1) * 30;
axesHeight = max([paramsHeight 300]);
dialogHeight = axesHeight + 50;

% Place this dialog on the same screen that the main window is on.
s = windowScreen(gcf);

% Size the dialog so that the sample axes is square but don't let it be wider than the screen.
if handles.showStimuli
    bounds = screenBounds(s);
    dpi = get(0, 'ScreenPixelsPerInch');
    bounds = bounds / dpi * 72;
    dialogWidth = min([labelWidth + 225 + 30 + axesHeight + 10, bounds(3) - 20]);
else
    dialogWidth = labelWidth + 225;
end

handles.figure = dialog(...
    'Units', 'points', ...
    'Name', [class(protocol) ' Parameters'], ...
    'Position', centerWindowOnScreen(double(dialogWidth), double(dialogHeight), s), ...
    'WindowKeyPressFcn', @(hObject, eventdata)editParametersKeyPress(hObject, eventdata, guidata(hObject)), ...
    'Tag', 'figure');

uicontrolcolor = reshape(get(0,'defaultuicontrolbackgroundcolor'), [1,1,3]);

% array for pushbutton's CData
button_size = 16;
mid = button_size/2;
push_cdata = repmat(uicontrolcolor,button_size,button_size);
for r = 4:11
    start = mid - r + 8 ;
    last = mid + r - 8;
    push_cdata(r,start:last,:) = 0;
end

% Create a control for each of the protocol's parameters.
textFieldParamNames = {};
for paramIndex = 1:paramCount
    paramName = paramNames{paramIndex};
    paramValue = params(paramName);
    paramLabel = humanReadableParameterName(paramName);
    
    try
        originalValue = defaultProperties(paramName);
        defaultValue = originalValue{paramChannel}; 
        
        if iscell(defaultValue)
            defaultValue = originalValue;
        end
        
    catch ME %#ok<NASGU>
        % There is no stored preference for the variable so use the
        % definition in the protocol m file
        defaultValue = paramValue{paramChannel};
        
        if iscell(defaultValue)
            defaultValue = paramValue;
        end

    end

    uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [10 dialogHeight-(paramIndex+1)*30 labelWidth 18], ...
        'String',  paramLabel,...
        'Style', 'text');
    
    paramTag = [paramName 'Edit'];

    if isinteger(defaultValue)
        handles.(paramTag) = uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'FontSize', 12,...
            'HorizontalAlignment', 'left', ...
            'Position', [labelWidth+15 dialogHeight-(paramIndex+1)*30-2 185 26], ...
            'String',  num2str(defaultValue),...
            'Style', 'edit', ...
            'Tag', paramTag);
        uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'Position', [labelWidth+201 dialogHeight-(paramIndex+1)*30+10 12 12], ...
            'CData', push_cdata, ...
            'Callback', @(hObject,eventdata)stepValue(hObject, eventdata, guidata(hObject), paramTag, 'up', paramName));
        uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'Position', [labelWidth+201 dialogHeight-(paramIndex+1)*30-1 12 12], ...
            'CData', flipdim(push_cdata, 1), ...
            'Callback', @(hObject,eventdata)stepValue(hObject, eventdata, guidata(hObject), paramTag, 'down', paramName));
        
        textFieldParamNames{end + 1} = paramName; %#ok<AGROW>
    elseif islogical(defaultValue)
        handles.(paramTag) = uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'FontSize', 12,...
            'Position', [labelWidth+15 dialogHeight-(paramIndex+1)*30-2 200 26], ...
            'Callback', @(hObject,eventdata)checkboxToggled(hObject, eventdata, guidata(hObject), paramName), ...
            'Value', defaultValue, ...
            'Style', 'checkbox', ...
            'Tag', paramTag);
    elseif isnumeric(defaultValue) || ischar(defaultValue)
        if isnumeric(defaultValue) && length(defaultValue) > 1
            % Convert a vector of numbers to a comma separated list.
            defaultValue = sprintf('%g,', defaultValue{paramChannel});
            defaultValue = defaultValue(1:end-1);
        end
        handles.(paramTag) = uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'FontSize', 12,...
            'HorizontalAlignment', 'left', ...
            'Position', [labelWidth+15 dialogHeight-(paramIndex+1)*30-2 200 26], ...
            'String',  defaultValue,...
            'Style', 'edit', ...
            'Tag', paramTag);
        
        textFieldParamNames{end + 1} = paramName; %#ok<AGROW>
    elseif iscell(defaultValue)
        
        if ~isempty(defaultValue{channels + 1}{paramChannel})
            popupValue = defaultValue{channels + 1}{paramChannel};
        else
            popupValue = paramChannel;
        end
        
        defaultValue = defaultValue{paramChannel};
        
        % Convert the items to human readable form.
        for i = 1:length(defaultValue)
            if ischar(defaultValue{i})
                defaultValue{i} = humanReadableParameterName(defaultValue{i});
            else
                defaultValue{i} = num2str(defaultValue{i});
            end
        end
        
        handles.(paramTag) = uicontrol(...
            'Parent', handles.figure, ...
            'Units', 'points', ...
            'Position', [labelWidth+15 dialogHeight-(paramIndex+1)*30-2 200 22], ...
            'Callback', @(hObject,eventdata)popUpMenuChanged(hObject, eventdata, guidata(hObject), paramTag, paramName), ...
            'String', defaultValue, ...
            'Style', 'popupmenu', ...
            'Value', popupValue, ...
            'Tag', paramTag);
    else
        error('Unhandled param type for param ''%s''', paramName);
    end
    
end
% TODO: add save/load settings functionality

if handles.showStimuli
    % Create axes for displaying sample stimuli.
    figure(handles.figure);
    handles.stimuliAxes = axes('Units', 'points', 'Position', [labelWidth + 225 + 30 40 axesHeight axesHeight - 10]);
    updateStimuli(handles);
end

handles.resetButton = uicontrol(...
    'Parent', handles.figure,...
    'Units', 'points', ...
    'Callback', @(hObject,eventdata)useDefaultParameters(hObject,eventdata,guidata(hObject)), ...
    'Position', [10 10 56 20], ...
    'String', 'Reset', ...
    'TooltipString', 'Restore the default parameters', ...
    'Tag', 'resetButton');

handles.cancelButton = uicontrol(...
    'Parent', handles.figure,...
    'Units', 'points', ...
    'Callback', @(hObject,eventdata)cancelEditParameters(hObject,eventdata,guidata(hObject)), ...
    'Position', [labelWidth + 225 - 56 - 10 - 56 - 10 10 56 20], ...
    'String', 'Cancel', ...
    'Tag', 'cancelButton');

handles.saveButton = uicontrol(...
    'Parent', handles.figure,...
    'Units', 'points', ...
    'Callback', @(hObject,eventdata)saveEditParameters(hObject,eventdata,guidata(hObject)), ...
    'Position', [labelWidth + 225 - 10 - 56 10 56 20], ...
    'String', 'Save', ...
    'Tag', 'saveButton');

guidata(handles.figure, handles);

% Try to add Java callbacks so that the stimuli and dependent values can be updated as new values are being typed.
drawnow
for i = 1:length(textFieldParamNames)
    paramName = textFieldParamNames{i};
    hObject = handles.([paramName 'Edit']);
    try
        javaHandle = findjobj(hObject);
        set(javaHandle, 'FocusLostCallback', {@valueChanged, hObject, paramName});
    catch ME %#ok<NASGU>
    end
end

% Wait for the user to cancel or save.
uiwait;

if ishandle(handles.figure)
    handles = guidata(handles.figure);
    edited = handles.edited;
    close(handles.figure);
else
    edited = false;
end
end

%% GUI Callback functions
function checkboxToggled(~, ~, handles, paramName)
updateSingleValue(handles, paramName);
updateStimuli(handles);
end

%If the user is changing the channel, update all values. If the user is
%just changing a parameter, update that
function popUpMenuChanged(~, ~, handles, paramTag, paramName)
if strcmp(paramTag, 'CHANNELSEdit')
    % set the new channel
    handles.protocolCopy.selectedChannel = get(handles.(paramTag), 'value');
    
    % the handles object has been updated for the selected channel
    handles.edited = true;
    guidata(handles.figure, handles);
    
    % update the values
    updateValues(handles);   
else
    updateSingleValue(handles, paramName);
end
updateStimuli(handles);
end

% If a textbox looses focus the value is updated
function valueChanged(~, ~, hObject, paramName)
try
handles = guidata(hObject);    
updateSingleValue(handles, paramName);
updateStimuli(handles);
drawnow
catch ME %#ok<NASGU>
    % The text box looses focus on the enter key/esc key being pressed
    % therefore this function gets called after the GUI has been dealt with
end
end

function stepValue(~, ~, handles, paramTag, direction, paramName)
curValue = int32(str2double(get(handles.(paramTag), 'String')));
if strcmp(direction, 'up')
    curValue = curValue + 1;
else
    curValue = curValue - 1;
end

set(handles.(paramTag), 'String', num2str(curValue));
updateSingleValue(handles, paramName);
updateStimuli(handles);
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


%% Functions to interact with the GUI objects
function value = getParamValueFromUI(handles, paramName)
paramTag = [paramName 'Edit'];
params = handles.protocolCopy.protocolProperties;
defaultValue = params(paramName);
paramChannel = handles.protocolCopy.selectedChannel;
defaultValue = defaultValue{paramChannel};

if isnumeric(defaultValue)
    javaHandle = findjobj(handles.(paramTag));
    if length(defaultValue) > 1
        % Convert from a comma separated list, ranges, etc. to a vector of numbers.
        paramValue = str2num(get(javaHandle, 'Text')); %#ok<ST2NM>
    else
        paramValue = str2double(get(javaHandle, 'Text'));
    end
    convFunc = str2func(class(defaultValue));
    value = convFunc(paramValue);
elseif islogical(defaultValue)
    value = get(handles.(paramTag), 'Value') == get(handles.(paramTag), 'Max');
elseif iscell(defaultValue)
    value = get(handles.(paramTag), 'Value');
elseif ischar(defaultValue)
    value = get(handles.(paramTag), 'Value');
end
end

function setParamValueInUI(handles, paramName, value, defaultValue)
paramTag = [paramName 'Edit'];

if iscell(defaultValue) || islogical(defaultValue)
    set(handles.(paramTag), 'Value', value);
elseif ischar(defaultValue)
    set(handles.(paramTag), 'String', value);
elseif isnumeric(defaultValue)
    if length(value) > 1
        % Convert a vector of numbers to a comma separated list.
        value = sprintf('%g,', value);
        value = value(1:end-1);
    end
    set(handles.(paramTag), 'String', value);
end
end


%% Functions to update values
% Push a single value to the copy of the plug-in.
function updateSingleValue(handles, paramName)
paramValue = getParamValueFromUI(handles, paramName);
paramChannel = handles.protocolCopy.selectedChannel;
temp = handles.protocolCopy.protocolProperties(paramName);

if iscell(temp{paramChannel})
    channels = handles.protocolCopy.channels;
    temp{channels+1}{paramChannel} = paramValue;
else
    temp{paramChannel} = paramValue;
end

handles.protocolCopy.protocolProperties(paramName) = temp;

handles.edited = true;
guidata(handles.figure, handles);
end

function updateValues(handles)
% Push all values into the copy of the plug-in.
handles.protocolCopy.protocolProperties = setProtocolsProperties(handles, handles.protocolCopy);

handles.edited = true;
guidata(handles.figure, handles);
updateStimuli(handles);
end

function updateStimuli(handles)
if handles.showStimuli
    set(handles.figure, 'CurrentAxes', handles.stimuliAxes)
    cla;
    stimuli = handles.protocolCopy.sampleStimuli();
    if isempty(stimuli)
        plot3(0, 0, 0);
        set(handles.stimuliAxes, 'XTick', [], 'YTick', [], 'ZTick', [])
        grid on;
        text('Units', 'normalized', 'Position', [0.5 0.5], 'String', 'No samples available', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    else
        stimulusCount = length(stimuli);
        for i = 1:stimulusCount
            stimulus = stimuli{i};
           
            params = handles.protocolCopy.protocolProperties;
            paramChannel = handles.protocolCopy.selectedChannel;
            channels = handles.protocolCopy.channels;
            
            sR = params('sampleRate');
            
            if ~isempty(sR{channels+1}{paramChannel})
                sR = sR{channels+1}{paramChannel};
            else
                sR = sR{paramChannel}{1};
            end
            
            plot3(ones(1, length(stimulus)) * i, (1:length(stimulus)) / double(sR), stimulus);
            hold on
        end
        hold off
        set(handles.stimuliAxes, 'XTick', 1:stimulusCount, 'XLim', [0.75 stimulusCount + 0.25])
        xlabel('Sample #');
        ylabel('Time (s)');
        set(gca,'YDir','reverse');
        zlabel('Stimulus');
        grid on;
    end
    axis square;
    title(handles.stimuliAxes, 'Sample Stimuli');
end
end

%% Additional parameter functions
function useDefaultParameters(~, ~, handles)
handles.protocol.protocolProperties = setProtocolsProperties(handles, handles.protocol);
handles.protocolCopy.protocolProperties = handles.protocol.protocolProperties;

handles.edited = true;
guidata(handles.figure, handles);
updateStimuli(handles);
end

function cancelEditParameters(~, ~, handles)
handles.edited = false;
guidata(handles.figure, handles);
uiresume;
end

function saveEditParameters(~, ~, handles)
params = handles.protocolCopy.protocolProperties;
paramNames = keys(params);
paramCount = params.Count;
paramChannel = handles.protocolCopy.selectedChannel;

channels = handles.protocolCopy.channels;

for paramIndex = 1:paramCount
    paramName = paramNames{paramIndex};
    paramTag = [paramName 'Edit'];
    paramProps = params(paramName);
    defaultValue = paramProps{paramChannel};
    
        if isnumeric(defaultValue)
            if length(defaultValue) > 1
                paramValue = str2num(get(handles.(paramTag), 'String')); %#ok<ST2NM>
            else
                paramValue = str2double(get(handles.(paramTag), 'String'));
            end
            convFunc = str2func(class(defaultValue));
            paramValue = convFunc(paramValue);
        elseif islogical(defaultValue)
            paramValue = get(handles.(paramTag), 'Value') == get(handles.(paramTag), 'Max');
        elseif iscell(defaultValue)
            paramValue = get(handles.(paramTag), 'Value');
        elseif ischar(defaultValue)
            paramValue = get(handles.(paramTag), 'String');
        end
        
        temp = handles.protocolCopy.protocolProperties(paramName);
        if iscell(defaultValue)
            temp{channels+1}{paramChannel} = paramValue;
        else
            temp{paramChannel} = paramValue;
        end
        handles.protocolCopy.protocolProperties(paramName) = temp;
end

try    
    % update the SymphonyProtocol object with the changes made to the copy
    handles.protocol.protocolProperties = handles.protocolCopy.protocolProperties;
    handles.protocol.selectedChannel = handles.protocolCopy.selectedChannel;

    % Remember these parameters for the next time edit Parameters is loaded.
    setpref('Symphony', [class(handles.protocol) '_Defaults'], handles.protocol.protocolProperties);    

    % Allow the protocol to apply any of the new settings to the rig.
    handles.protocol.prepareRig();
    handles.protocol.rigConfig.prepared();
    handles.protocol.rigPrepared = true;        
catch ME
    % TODO: What should be done if the rig can't be prepared?
    throw(ME);
end

handles.edited = true;
guidata(handles.figure, handles);
uiresume;
end

%% helper function to set new values in the UI
function paramValue = setProtocolsProperties(handles, handlesInstance)
protocolProperties = handlesInstance.protocolProperties;

paramNames = keys(protocolProperties);
paramCount = protocolProperties.Count;
paramChannel = handlesInstance.selectedChannel;
channels = handlesInstance.channels;

for paramIndex = 1:paramCount
    paramName = paramNames{paramIndex};
    paramValue = protocolProperties(paramName);
    defaultValue = paramValue{paramChannel};
    
    temp = protocolProperties(paramName);
    if iscell(defaultValue)
        if strcmp('CHANNELS', paramName)
            dV = paramChannel;  
        elseif ~isempty(temp{channels + 1}{paramChannel})
            dV = temp{channels + 1}{paramChannel};
        else
            dV = 1;
        end
        temp{channels + 1}{paramChannel} = dV;
    else
        dV = defaultValue;
        temp{paramChannel} = dV; 
    end
    
    protocolProperties(paramName) = temp;
    setParamValueInUI(handles, paramName, dV, defaultValue);
end

paramValue = protocolProperties;

end
