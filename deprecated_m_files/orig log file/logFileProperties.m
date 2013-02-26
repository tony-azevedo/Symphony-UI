function varargout = logFileProperties(varargin)
% LOGFILEPROPERTIES
%
%
% Returns 1x6 matrix, with the text editor properties that can be
% configured by the user.
%
% The properties that return a boolean value, 1 for yes, 0 for no are:
%   - rigConfigChanges
%   - protocolChanges
%   - epochGroupInformation
%   - epochs
%   - createHiddenFile
%  
% The property that returns a string location of where the file is to be saved is:
%    - folder
%
% NOTE:
% If the user cancels or quits the properties window, an empty array is returned
%
%
% INPUTS:
% This function can take an input of a 1x7 matrix to load values into the
% GUI. The values must correspond correctly to the information listed
% above.
%
% If no input is provided, the default values are loaded:
%       - {0,0,0,0,0,0,fullfile(fileparts(mfilename('fullpath')))}
%

% Last Modified by GUIDE v2.5 29-Oct-2012 17:21:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @logFileProperties_OpeningFcn, ...
                   'gui_OutputFcn',  @logFileProperties_OutputFcn, ...
                   'gui_LayoutFcn',  @logFileProperties_LayoutFcn, ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before logFileProperties is made visible.
function logFileProperties_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to logFileProperties (see VARARGIN)

% Choose default command line output for logFileProperties
handles.output = hObject;

handles.properties = {};

if ~isempty(varargin)
    try
        for i = 1:6
           if i < 6
               if varargin{1,1}{i} == 0 || varargin{1,1}{i} == 1
                    handles.properties{1,1}{i} = varargin{1,1}{i};
               else
                   handles.properties = {};
                   waitfor(errordlg('Incorrect Inputs into the function, the default settings have been loaded'));
                   break;
               end
           else
                if isdir(varargin{1,1}{6})
                    handles.properties{1,1}{6} = varargin{1,1}{6};
                else
                   handles.properties{1,1}{6} = fullfile(fileparts(mfilename('fullpath')));
                   waitfor(errordlg(['The folder location ' ...
                            varargin{1,1}{6} ...
                           ' not found, the default symphony location  has been loaded']));
                end               
           end
        end
    catch ME
        waitfor(errordlg(ME.message));
    end

    if ~isempty(handles.properties)
        set(handles.rigConfigChanges, 'value', handles.properties{1,1}{1});
        set(handles.protocolChanges, 'value', handles.properties{1,1}{2});
        set(handles.epochGroupInformation, 'value', handles.properties{1,1}{3});
        set(handles.epochs, 'value', handles.properties{1,1}{4});
        set(handles.createHiddenFile, 'value', handles.properties{1,1}{5});
        set(handles.folder, 'String', handles.properties{1,1}{6});
    end
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes logFileProperties wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = logFileProperties_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.properties;
delete(handles.figure1);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
% delete(hObject);
handles.properties = {};
guidata(hObject, handles);
uiresume

% --- Executes during object creation, after setting all properties.
function folder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in selectFolder.
function selectFolder_Callback(hObject, eventdata, handles)
% hObject    handle to selectFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
symphonyPath = mfilename('fullpath');
parentDir = fileparts(symphonyPath);
configsDir = fullfile(parentDir, 'log_files');
logFileFolder = uigetdir(configsDir, 'Log File Location');
set(handles.folder, 'String', logFileFolder);

% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
rcc = get(handles.rigConfigChanges, 'value');
pc = get(handles.protocolChanges, 'value');
egi = get(handles.epochGroupInformation, 'value');
e = get(handles.epochs, 'value');
chf = get(handles.createHiddenFile, 'value');
lfl = get(handles.folder, 'String');

handles.properties = {
    rcc, ...
    pc, ...
    egi, ...
    e, ...
    chf, ...
    lfl
};

guidata(hObject, handles);

uiresume

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.properties = {};
guidata(hObject, handles);
uiresume

% --- Creates and returns a handle to the GUI figure. 
function h1 = logFileProperties_LayoutFcn(policy)
% policy - create a new figure or use a singleton. 'new' or 'reuse'.

persistent hsingleton;
if strcmpi(policy, 'reuse') & ishandle(hsingleton)
    h1 = hsingleton;
    return;
end

appdata = [];
appdata.GUIDEOptions = struct(...
    'active_h', [], ...
    'taginfo', struct(...
    'figure', 2, ...
    'uipanel', 4, ...
    'checkbox', 7, ...
    'text', 3, ...
    'popupmenu', 2, ...
    'edit', 2, ...
    'pushbutton', 4), ...
    'override', 0, ...
    'release', 13, ...
    'resize', 'none', ...
    'accessibility', 'callback', ...
    'mfile', 1, ...
    'callbacks', 1, ...
    'singleton', 1, ...
    'syscolorfig', 1, ...
    'blocking', 0, ...
    'lastSavedFile', 'C:\Users\local_admin\Documents\GitHub\Symphony-UI\logFileProperties.m', ...
    'lastFilename', 'C:\Users\local_admin\Documents\GitHub\Symphony-UI\Figures\lofFileProperties.fig');
appdata.lastValidTag = 'figure1';
appdata.GUIDELayoutEditor = [];
appdata.initTags = struct(...
    'handle', [], ...
    'tag', 'figure1');

h1 = figure(...
'Units','characters',...
'CloseRequestFcn',@(hObject,eventdata)logFileProperties('figure1_CloseRequestFcn',hObject,eventdata,guidata(hObject)),...
'Color',[0.941176470588235 0.941176470588235 0.941176470588235],...
'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
'IntegerHandle','off',...
'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
'MenuBar','none',...
'Name','lofFileProperties',...
'NumberTitle','off',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'Position',[103.8 29.1538461538462 112 32.3076923076923],...
'Resize','off',...
'HandleVisibility','callback',...
'UserData',[],...
'Tag','figure1',...
'Visible','on',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'loggingPropertiesPanel';

h2 = uipanel(...
'Parent',h1,...
'Units','characters',...
'Title','Logging Properties',...
'Tag','loggingPropertiesPanel',...
'Clipping','on',...
'Position',[1.8 15.2307692307692 108.2 16.2307692307692],...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'rigConfigChanges';

h3 = uicontrol(...
'Parent',h2,...
'Units','characters',...
'Position',[1.8 10.5384615384615 32.2 1.76923076923077],...
'String','Rig Config Changes',...
'Style','checkbox',...
'Tag','rigConfigChanges',...
'value', 0,...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'loggingPropertiesHelp';

h4 = uicontrol(...
'Parent',h2,...
'Units','characters',...
'Position',[1.8 13 102.2 1.61538461538462],...
'String','The following properties you can choose to record in the log file.',...
'Style','text',...
'Tag','loggingPropertiesHelp',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'protocolChanges';

h5 = uicontrol(...
'Parent',h2,...
'Units','characters',...
'Position',[1.8 8.46153846153846 32.2 1.76923076923077],...
'String','Protocol Changes',...
'Style','checkbox',...
'Tag','protocolChanges',...
'value', 0,...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'epochGroupInformation';

h7 = uicontrol(...
'Parent',h2,...
'Units','characters',...
'Position',[1.8 3.84615384615385 38.4 1.76923076923077],...
'String','Epoch Group Information',...
'Style','checkbox',...
'Tag','epochGroupInformation',...
'value', 0,...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'epochs';

h8 = uicontrol(...
'Parent',h2,...
'Units','characters',...
'Position',[1.8 1.53846153846154 38.4 1.76923076923077],...
'String','Epochs',...
'Style','checkbox',...
'Tag','epochs',...
'value', 0,...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel2';

h9 = uipanel(...
'Parent',h1,...
'Units','characters',...
'Title','Create Hidden File',...
'Tag','uipanel2',...
'Clipping','on',...
'Position',[1.8 9.07692307692308 108.2 5.46153846153846],...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'text2';

h10 = uicontrol(...
'Parent',h9,...
'Units','characters',...
'Position',[3.6 2.23076923076923 102.2 1.61538461538462],...
'String','This will create a hidden file as a back up',...
'Style','text',...
'Tag','text2',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'createHiddenFile';

h11 = uicontrol(...
'Parent',h9,...
'Units','characters',...
'Position',[1.8 0.769230769230769 38.4 1.76923076923077],...
'String','Create Hidden File',...
'Style','checkbox',...
'Tag','createHiddenFile',...
'value', 0,...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'uipanel3';

h12 = uipanel(...
'Parent',h1,...
'Units','characters',...
'Title','Location to save the file',...
'Tag','uipanel3',...
'Clipping','on',...
'Position',[1.8 0.615384615384615 108.2 7.76923076923077],...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'folder';

h13 = uicontrol(...
'Parent',h12,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Enable','off',...
'Position',[1.8 3.84615384615384 90.2 1.69230769230769],...
'String', fullfile(fileparts(mfilename('fullpath'))),...
'Style','edit',...
'CreateFcn', {@local_CreateFcn, @(hObject,eventdata)logFileProperties('folder_CreateFcn',hObject,eventdata,guidata(hObject)), appdata} ,...
'Tag','folder');

appdata = [];
appdata.lastValidTag = 'selectFolder';

h14 = uicontrol(...
'Parent',h12,...
'Units','characters',...
'Callback',@(hObject,eventdata)logFileProperties('selectFolder_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[92 3.84615384615384 13.8 1.69230769230769],...
'String','Change',...
'Tag','selectFolder',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'save';

h15 = uicontrol(...
'Parent',h12,...
'Units','characters',...
'Callback',@(hObject,eventdata)logFileProperties('save_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[2 0.769230769230769 13.8 1.69230769230769],...
'String','Save',...
'Tag','save',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'cancel';

h16 = uicontrol(...
'Parent',h12,...
'Units','characters',...
'Callback',@(hObject,eventdata)logFileProperties('cancel_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[18 0.769230769230769 13.8 1.69230769230769],...
'String','Cancel',...
'Tag','cancel',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );


hsingleton = h1;


% --- Set application data first then calling the CreateFcn. 
function local_CreateFcn(hObject, eventdata, createfcn, appdata)

if ~isempty(appdata)
   names = fieldnames(appdata);
   for i=1:length(names)
       name = char(names(i));
       setappdata(hObject, name, getfield(appdata,name));
   end
end

if ~isempty(createfcn)
   if isa(createfcn,'function_handle')
       createfcn(hObject, eventdata);
   else
       eval(createfcn);
   end
end


% --- Handles default GUIDE GUI creation and callback dispatch
function varargout = gui_mainfcn(gui_State, varargin)

gui_StateFields =  {'gui_Name'
    'gui_Singleton'
    'gui_OpeningFcn'
    'gui_OutputFcn'
    'gui_LayoutFcn'
    'gui_Callback'};
gui_Mfile = '';
for i=1:length(gui_StateFields)
    if ~isfield(gui_State, gui_StateFields{i})
        error(message('MATLAB:guide:StateFieldNotFound', gui_StateFields{ i }, gui_Mfile));
    elseif isequal(gui_StateFields{i}, 'gui_Name')
        gui_Mfile = [gui_State.(gui_StateFields{i}), '.m'];
    end
end

numargin = length(varargin);

if numargin == 0
    % LOGFILEPROPERTIES
    % create the GUI only if we are not in the process of loading it
    % already
    gui_Create = true;
elseif local_isInvokeActiveXCallback(gui_State, varargin{:})
    % LOGFILEPROPERTIES(ACTIVEX,...)
    vin{1} = gui_State.gui_Name;
    vin{2} = [get(varargin{1}.Peer, 'Tag'), '_', varargin{end}];
    vin{3} = varargin{1};
    vin{4} = varargin{end-1};
    vin{5} = guidata(varargin{1}.Peer);
    feval(vin{:});
    return;
elseif local_isInvokeHGCallback(gui_State, varargin{:})
    % LOGFILEPROPERTIES('CALLBACK',hObject,eventData,handles,...)
    gui_Create = false;
else
    % LOGFILEPROPERTIES(...)
    % create the GUI and hand varargin to the openingfcn
    gui_Create = true;
end

if ~gui_Create
    % In design time, we need to mark all components possibly created in
    % the coming callback evaluation as non-serializable. This way, they
    % will not be brought into GUIDE and not be saved in the figure file
    % when running/saving the GUI from GUIDE.
    designEval = false;
    if (numargin>1 && ishghandle(varargin{2}))
        fig = varargin{2};
        while ~isempty(fig) && ~ishghandle(fig,'figure')
            fig = get(fig,'parent');
        end
        
        designEval = isappdata(0,'CreatingGUIDEFigure') || isprop(fig,'__GUIDEFigure');
    end
        
    if designEval
        beforeChildren = findall(fig);
    end
    
    % evaluate the callback now
    varargin{1} = gui_State.gui_Callback;
    if nargout
        [varargout{1:nargout}] = feval(varargin{:});
    else       
        feval(varargin{:});
    end
    
    % Set serializable of objects created in the above callback to off in
    % design time. Need to check whether figure handle is still valid in
    % case the figure is deleted during the callback dispatching.
    if designEval && ishghandle(fig)
        set(setdiff(findall(fig),beforeChildren), 'Serializable','off');
    end
else
    if gui_State.gui_Singleton
        gui_SingletonOpt = 'reuse';
    else
        gui_SingletonOpt = 'new';
    end

    % Check user passing 'visible' P/V pair first so that its value can be
    % used by oepnfig to prevent flickering
    gui_Visible = 'auto';
    gui_VisibleInput = '';
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        % Recognize 'visible' P/V pair
        len1 = min(length('visible'),length(varargin{index}));
        len2 = min(length('off'),length(varargin{index+1}));
        if ischar(varargin{index+1}) && strncmpi(varargin{index},'visible',len1) && len2 > 1
            if strncmpi(varargin{index+1},'off',len2)
                gui_Visible = 'invisible';
                gui_VisibleInput = 'off';
            elseif strncmpi(varargin{index+1},'on',len2)
                gui_Visible = 'visible';
                gui_VisibleInput = 'on';
            end
        end
    end
    
    % Open fig file with stored settings.  Note: This executes all component
    % specific CreateFunctions with an empty HANDLES structure.

    
    % Do feval on layout code in m-file if it exists
    gui_Exported = ~isempty(gui_State.gui_LayoutFcn);
    % this application data is used to indicate the running mode of a GUIDE
    % GUI to distinguish it from the design mode of the GUI in GUIDE. it is
    % only used by actxproxy at this time.   
    setappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]),1);
    if gui_Exported
        gui_hFigure = feval(gui_State.gui_LayoutFcn, gui_SingletonOpt);

        % make figure invisible here so that the visibility of figure is
        % consistent in OpeningFcn in the exported GUI case
        if isempty(gui_VisibleInput)
            gui_VisibleInput = get(gui_hFigure,'Visible');
        end
        set(gui_hFigure,'Visible','off')

        % openfig (called by local_openfig below) does this for guis without
        % the LayoutFcn. Be sure to do it here so guis show up on screen.
        movegui(gui_hFigure,'onscreen');
    else
        gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        % If the figure has InGUIInitialization it was not completely created
        % on the last pass.  Delete this handle and try again.
        if isappdata(gui_hFigure, 'InGUIInitialization')
            delete(gui_hFigure);
            gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        end
    end
    if isappdata(0, genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]))
        rmappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]));
    end

    % Set flag to indicate starting GUI initialization
    setappdata(gui_hFigure,'InGUIInitialization',1);

    % Fetch GUIDE Application options
    gui_Options = getappdata(gui_hFigure,'GUIDEOptions');
    % Singleton setting in the GUI M-file takes priority if different
    gui_Options.singleton = gui_State.gui_Singleton;

    if ~isappdata(gui_hFigure,'GUIOnScreen')
        % Adjust background color
        if gui_Options.syscolorfig
            set(gui_hFigure,'Color', get(0,'DefaultUicontrolBackgroundColor'));
        end

        % Generate HANDLES structure and store with GUIDATA. If there is
        % user set GUI data already, keep that also.
        data = guidata(gui_hFigure);
        handles = guihandles(gui_hFigure);
        if ~isempty(handles)
            if isempty(data)
                data = handles;
            else
                names = fieldnames(handles);
                for k=1:length(names)
                    data.(char(names(k)))=handles.(char(names(k)));
                end
            end
        end
        guidata(gui_hFigure, data);
    end

    % Apply input P/V pairs other than 'visible'
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        len1 = min(length('visible'),length(varargin{index}));
        if ~strncmpi(varargin{index},'visible',len1)
            try set(gui_hFigure, varargin{index}, varargin{index+1}), catch break, end
        end
    end

    % If handle visibility is set to 'callback', turn it on until finished
    % with OpeningFcn
    gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
    if strcmp(gui_HandleVisibility, 'callback')
        set(gui_hFigure,'HandleVisibility', 'on');
    end

    feval(gui_State.gui_OpeningFcn, gui_hFigure, [], guidata(gui_hFigure), varargin{:});

    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        % Handle the default callbacks of predefined toolbar tools in this
        % GUI, if any
        guidemfile('restoreToolbarToolPredefinedCallback',gui_hFigure); 
        
        % Update handle visibility
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);

        % Call openfig again to pick up the saved visibility or apply the
        % one passed in from the P/V pairs
        if ~gui_Exported
            gui_hFigure = local_openfig(gui_State.gui_Name, 'reuse',gui_Visible);
        elseif ~isempty(gui_VisibleInput)
            set(gui_hFigure,'Visible',gui_VisibleInput);
        end
        if strcmpi(get(gui_hFigure, 'Visible'), 'on')
            figure(gui_hFigure);
            
            if gui_Options.singleton
                setappdata(gui_hFigure,'GUIOnScreen', 1);
            end
        end

        % Done with GUI initialization
        if isappdata(gui_hFigure,'InGUIInitialization')
            rmappdata(gui_hFigure,'InGUIInitialization');
        end

        % If handle visibility is set to 'callback', turn it on until
        % finished with OutputFcn
        gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
        if strcmp(gui_HandleVisibility, 'callback')
            set(gui_hFigure,'HandleVisibility', 'on');
        end
        gui_Handles = guidata(gui_hFigure);
    else
        gui_Handles = [];
    end

    if nargout
        [varargout{1:nargout}] = feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    else
        feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    end

    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
    end
end

function gui_hFigure = local_openfig(name, singleton, visible)

% openfig with three arguments was new from R13. Try to call that first, if
% failed, try the old openfig.
if nargin('openfig') == 2
    % OPENFIG did not accept 3rd input argument until R13,
    % toggle default figure visible to prevent the figure
    % from showing up too soon.
    gui_OldDefaultVisible = get(0,'defaultFigureVisible');
    set(0,'defaultFigureVisible','off');
    gui_hFigure = openfig(name, singleton);
    set(0,'defaultFigureVisible',gui_OldDefaultVisible);
else
    gui_hFigure = openfig(name, singleton, visible);  
    %workaround for CreateFcn not called to create ActiveX
    if feature('HGUsingMATLABClasses')
        peers=findobj(findall(allchild(gui_hFigure)),'type','uicontrol','style','text');    
        for i=1:length(peers)
            if isappdata(peers(i),'Control')
                actxproxy(peers(i));
            end            
        end
    end
end

function result = local_isInvokeActiveXCallback(gui_State, varargin)

try
    result = ispc && iscom(varargin{1}) ...
             && isequal(varargin{1},gcbo);
catch
    result = false;
end

function result = local_isInvokeHGCallback(gui_State, varargin)

try
    fhandle = functions(gui_State.gui_Callback);
    result = ~isempty(findstr(gui_State.gui_Name,fhandle.file)) || ...
             (ischar(varargin{1}) ...
             && isequal(ishghandle(varargin{2}), 1) ...
             && (~isempty(strfind(varargin{1},[get(varargin{2}, 'Tag'), '_'])) || ...
                ~isempty(strfind(varargin{1}, '_CreateFcn'))) );
catch
    result = false;
end


