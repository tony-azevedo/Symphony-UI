classdef (Sealed) SolutionController < handle
    %% 
    properties (SetAccess = private, GetAccess = public)
        %the connection object
        port
        conn
        portList
        
        %channel identifiers
        channels
    end
        
    properties (Hidden)
        %GUI
        gui
        color
        guiObjects  
        
        %the connection object
        portValue
        BytesAvailable
        t
        
        %channel identifiers
        channelCode
    end
   
    properties (SetObservable, GetObservable, AbortSet, SetAccess = private, GetAccess = public)
        deviceStatus = '';        
    end

    properties (SetObservable, GetObservable, AbortSet, SetAccess = private, GetAccess = private)
        readControl = '';
    end

    methods (Static)
        function readControlChange( ~ ,eventData)
            h = eventData.AffectedObject;
            if(~strcmp(h.readControl,''))
                h.updateGUI;
            end
        end
    end

    %% Main Methods
    methods          
        function sc = SolutionController( varargin )
            narginchk(0,2);
            sc.channels = 5;
            
            for v = 1:(nargin)
                input = varargin{v};
                
                if iscell(input)
                    
                    if strcmp(input{1},'port') && isnumeric(input{2})
                        sc.port = ['COM' int2str(input{2})];
                    elseif strcmp(input{1},'channels') && isnumeric(input{2}) && input{2} < 53
                        sc.channels = input{2};
                    end
                end
            end
            
            serialInfo = instrhwinfo('serial');
            sc.portList = serialInfo.AvailableSerialPorts;
            
            sc.portValue = 1;
            if ~isempty(sc.port)
                for pv = 1:length(sc.portList)
                    if(sc.port == sc.portList{pv})
                        sc.portValue = pv;
                    end
                end
            end
            sc.initTimer;
            sc.calcChannelCodes();
            sc.showGui();
            addlistener(sc,'readControl','PostSet',@sc.readControlChange);
        end
                
        function showGui(sc)
            % Dimensions of the GUI
            panelWidth = 150;
            dialogWidth = 4 * panelWidth;
            dialogHeight = sc.channels * 35;
            
            %Variables Used for placing objects on the GUI
            fLI = 5;
            sLI = 75;
            FontSize = 9;
            HeadingFontSize = 10;
            objectHeight = 30;
            objectWidth = 65;            
            
             %Construcing the GUI
            sc.gui = figure(...
                'Units', 'points', ...
                'Name', 'Solution Controller', ...
                'Menubar', 'none', ...
                'position',[dialogWidth, dialogHeight, dialogWidth, dialogHeight],...
                'CloseRequestFcn', @(hObject,eventdata)closeRequestFcn(sc,hObject,eventdata), ...
                'Tag', 'figure', ...
                'Resize','off' ...
            );

            sc.color = get(sc.gui, 'Color');
            sc.guiObjects = struct();
            
            % The Settings Panel
            panelParamTag = 'Settings';
            sc.guiObjects.(panelParamTag) = uipanel(...
                'Parent', sc.gui, ...
                'Units', 'points', ...
                'FontSize', HeadingFontSize, ...
                'Title', panelParamTag, ...
                'Tag', panelParamTag, ...
                'Position', [0 0 panelWidth dialogHeight] ...
            );
                                    
            paramTag = 'PortsLabel'; 
            sc.guiObjects.(paramTag) = uicontrol(...
                 'Parent', sc.guiObjects.(panelParamTag), ...
                 'Style', 'text', ...
                 'String', 'Select Port:', ...
                 'Units', 'points', ...
                 'Position', [fLI (dialogHeight - 48) objectWidth objectHeight], ...
                 'FontSize', FontSize, ...
                 'Tag', paramTag);

            paramTag = 'Ports'; 
            sc.guiObjects.(paramTag) = uicontrol(...
                'Parent', sc.guiObjects.(panelParamTag), ...
                'Units', 'points', ...
                'Position', [sLI (dialogHeight - 45) objectWidth objectHeight], ...
                'String', sc.portList, ...
                'Style', 'popupmenu', ...
                'Value', sc.portValue, ...
                'Enable', 'On', ...
                'Tag', paramTag);

            paramTag = 'Connect'; 
            sc.guiObjects.(paramTag) = uicontrol(...
                'Parent', sc.guiObjects.(panelParamTag), ...
                'Units', 'points', ...
                'Enable', 'On', ...
                'Callback', @(hObject,eventdata)connect(sc,hObject,eventdata), ...
                'Position', [fLI (dialogHeight - 70) objectWidth objectHeight], ...
                'String', paramTag, ...
                'Tag', paramTag);

            paramTag = 'Disconnect'; 
            sc.guiObjects.(paramTag) = uicontrol(...
                'Parent', sc.guiObjects.(panelParamTag), ...
                'Units', 'points', ...
                'Enable', 'Off', ...
                'Callback',  @(hObject,eventdata)disconnect(sc,hObject,eventdata), ...
                'Position', [sLI (dialogHeight - 70) objectWidth objectHeight], ...
                'String', paramTag, ...
                'Tag', paramTag);

            % The Panel to control the valves
            panelParamTag = 'ValveControl';
            sc.guiObjects.(panelParamTag) = uipanel(...
                'Parent', sc.gui, ...
                'Units', 'points', ...
                'FontSize', HeadingFontSize, ...
                'Title', panelParamTag, ...
                'Tag', panelParamTag, ...
                'Position', [panelWidth 0 panelWidth dialogHeight] ...
            );

            for v = 1:sc.channels

                sPanelParamTag = ['valve' sc.channelCode(v)];
                sc.guiObjects.(sPanelParamTag) = uipanel(...
                    'Parent', sc.guiObjects.(panelParamTag), ...
                    'Units', 'points', ...
                    'FontSize', FontSize, ...
                    'Title', v, ...
                    'Tag', sPanelParamTag, ...
                    'Position', [1 ((dialogHeight - 15) - ((v) * (((dialogHeight - 15)/sc.channels)))) 145 (dialogHeight/sc.channels)] ...
                );

                paramTag = ['Open' sc.channelCode(v)];
                sc.guiObjects.(paramTag) = uicontrol(...
                    'Parent', sc.guiObjects.(sPanelParamTag), ...
                    'Units', 'points', ...
                    'Enable', 'Off', ...
                    'Position', [fLI 3 objectWidth 20], ...
                    'Callback',   @(hObject,eventdata)openClose(sc, hObject,eventdata,v, 1), ...
                    'String', 'Open', ...
                    'Tag', paramTag);

                paramTag = ['Close' sc.channelCode(v)];
                sc.guiObjects.(paramTag) = uicontrol(...
                    'Parent', sc.guiObjects.(sPanelParamTag), ...
                    'Units', 'points', ...
                    'Enable', 'Off', ...
                    'Position', [sLI 3 objectWidth 20], ...
                    'Callback',  @(hObject,eventdata)openClose(sc, hObject,eventdata,v, 0), ...
                    'String', 'Close', ...
                    'Tag', paramTag);       
            end
            
            % The Panel Display the Valve Status
            panelParamTag = 'ValveStatus';
            sc.guiObjects.(panelParamTag) = uipanel(...
                'Parent', sc.gui, ...
                'Units', 'points', ...
                'FontSize', HeadingFontSize, ...
                'Title', panelParamTag, ...
                'Tag', panelParamTag, ...
                'Position', [(panelWidth*2) 0 panelWidth dialogHeight] ...
            );

            for v = 1:sc.channels
                sPanelParamTag = [panelParamTag sc.channelCode(v)];
                sc.guiObjects.(sPanelParamTag) = uipanel(...
                    'Parent', sc.guiObjects.(panelParamTag), ...
                    'Units', 'points', ...
                    'FontSize', FontSize, ...
                    'Tag', sPanelParamTag, ...
                    'Position', [1 ((dialogHeight - 15) - ((v) * (((dialogHeight - 15)/sc.channels)))) 145 ((dialogHeight/sc.channels) - 6)] ...
                );
            end
            
            % The Panel Display the Valve Status
            panelParamTag = 'ValveControl';
            sc.guiObjects.(panelParamTag) = uipanel(...
                'Parent', sc.gui, ...
                'Units', 'points', ...
                'FontSize', HeadingFontSize, ...
                'Title', panelParamTag, ...
                'Tag', panelParamTag, ...
                'Position', [(panelWidth*3) 0 panelWidth dialogHeight] ...
            );
 
            for v = 1:sc.channels
                sPanelParamTag = [panelParamTag sc.channelCode(v)];
                sc.guiObjects.(sPanelParamTag) = uipanel(...
                    'Parent', sc.guiObjects.(panelParamTag), ...
                    'Units', 'points', ...
                    'FontSize', FontSize, ...
                    'Tag', sPanelParamTag, ...
                    'Position', [1 ((dialogHeight - 15) - ((v) * (((dialogHeight - 15)/sc.channels)))) 145 ((dialogHeight/sc.channels) - 6)] ...
                );
 
                paramTag = ['PortsLabel' sc.channelCode(v)]; 
                sc.guiObjects.(paramTag) = uicontrol(...
                 'Parent', sc.guiObjects.(sPanelParamTag), ...
                 'Style', 'text', ...
                 'String', '', ...
                 'Units', 'points', ...
                 'Position', [5 (FontSize - 6) 125 objectHeight/2], ...
                 'FontSize', FontSize, ...
                 'Tag', paramTag);
                
            end
           
        end
    end
    
    %% Helper Functions
    methods
        function calcChannelCodes(sc)
            upperCaseStart = 65;
            alphabetLength = 26;
            lowerCaseStart = 97;

            for v = 1:sc.channels
                if v < (alphabetLength + 1)
                    indexnum = v - 1;
                    number = upperCaseStart;
                else
                    indexnum = v - 1 - alphabetLength;
                    number = lowerCaseStart;
                end

                sc.channelCode(v) = char(number + indexnum);
            end            
        end
    end
    
    %% GUI Functions
    methods
        function closeRequestFcn(sc, ~, ~)
            if ~isempty(sc.conn)
                fclose(sc.conn);
                delete(sc.conn);
            end
           
           sc.stopTimer();
           
           delete(sc.gui);
           
           delete(sc);
        end
        
        function openClose(sc, ~ , ~ , v, s)
            msg = ['V,' int2str(v) ',' int2str(s)];
            sc.send(msg);
            sc.deviceStatus = sc.status('S');
        end
        
        function updateGUI(sc)
            if(~isempty(sc.deviceStatus))
                status = textscan(sc.deviceStatus, '%s', 'delimiter', sprintf(','));
            end
            
            if(~isempty(sc.readControl))
                statusRC = textscan(sc.readControl, '%s', 'delimiter', sprintf(','));
            end
            
            if(~isempty(sc.readControl) && ~isempty(sc.deviceStatus))
                for v = 1:sc.channels  
                   sc.changeValveStatus(v, str2double(status{1}{v+1}), str2double(statusRC{1}{v+1}));
                end        
            end
        end
                
        % A function to change the status of the valve in the GUI
        function changeValveStatus(sc, valve, status, control)
            name = sc.channelCode(valve);

            % status values:
            % 0 = Off
            % 1 = On
            % 2 = Overloaded
            % 3 = Disconnecting From the Device. (ie. No Color Marker)

            switch status
                case 0
                    c = [1 0 0];
                    onBtn = 'On';
                    offBtn = 'Off';        
                case 1
                    onBtn = 'Off';
                    offBtn = 'On';
                    c = [0 1 0];
                case 2
                    %To Do
                case 3
                    c = sc.color;
                    onBtn = 'Off';
                    offBtn = 'Off';      
                    device = '';
            end
            
 
            % status values:
            % 0 = Front panel switch
            % 1 = On
            % 2 = Remote switch
            
            if status ~= 3
                switch control
                    case 0
                        onBtn = 'Off';
                        offBtn = 'Off';            
                        device = 'Front panel switch';
                    case 1
                        device = 'Remote computer';
                    case 2
                        onBtn = 'Off';
                        offBtn = 'Off';      
                        device = 'Remote switch';
                end     
            end
                        
            label = ['Open' name];
            set(sc.guiObjects.(label), 'Enable', onBtn);

            label = ['Close' name];
            set(sc.guiObjects.(label), 'Enable', offBtn);
            
            label = ['PortsLabel' name];
            set(sc.guiObjects.(label), 'String', device);          
            
            label = ['ValveStatus' name];
            set(sc.guiObjects.(label), 'BackgroundColor', c); 
        end     
        
    end
    %% Serial Port Methods
    methods    
       function send(sc, msg)
           fprintf(sc.conn,msg);
       end
       
       function flush(sc)
           if sc.conn.BytesAvailable > 0
            fread(sc.conn, sc.conn.BytesAvailable)
           end
       end
       
       function status = status(sc, msg) 
            pause(0.03);
            sc.send(msg); 
            status = fscanf(sc.conn);
        end
        
        function disconnect( varargin )
            narginchk(1,3);
            sc =  varargin{1};
            if isa(sc,'SolutionController')
                sc.deviceStatus = sc.status('S');

                sc.stopTimer;
                fclose(sc.conn);

                set(sc.guiObjects.Disconnect, 'Enable', 'Off');
                set(sc.guiObjects.Connect, 'Enable', 'On');    
                set(sc.guiObjects.Ports, 'Enable', 'On');       

                for v = 1:sc.channels
                    sc.changeValveStatus(v, 3, 3);
                end

                sc.deviceStatus = '';
                sc.readControl = '';
            end
        end
        
        function valveStatus( sc , ~ , ~ )
            try
                if strcmp(sc.conn.Status, 'open') && strcmp(sc.t.Running, 'on')
                    sc.deviceStatus = sc.status('S');
                    sc.readControl = sc.status('C');
                end
            catch %#ok<CTCH>
            end
        end
                
        function initTimer(sc)
            sc.t = timer;
            sc.t.TimerFcn = {@sc.valveStatus};
            sc.t.Period = 0.02;
            sc.t.ExecutionMode = 'fixedSpacing';
            sc.t.Tag = 'SolutionControllerPolling';
        end    
        
                    
        function startTimer(sc)
            if(strcmp(sc.t.Running, 'off'))
                start(sc.t);
            end
        end

        
        function stopTimer(sc)
            if(strcmp(sc.t.Running, 'on'))
                stop(sc.t);
            end
        end
        
        function connect( varargin )
            narginchk(1,3);
            sc =  varargin{1};
            if isa(sc,'SolutionController')
                sc.portValue = get(sc.guiObjects.Ports,'Value');
                sc.port = sc.portList{sc.portValue};

                sc.conn = serial(sc.port);

                sc.conn.BaudRate = 57600;
                sc.conn.ReadAsyncMode = 'continuous';
                sc.conn.Terminator = 'LF/CR';

                fopen(sc.conn);

                set(sc.guiObjects.Disconnect, 'Enable', 'On');
                set(sc.guiObjects.Connect, 'Enable', 'Off');
                set(sc.guiObjects.Ports, 'Enable', 'Off');

                sc.startTimer;
            end
        end 
    end
end

