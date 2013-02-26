classdef (Sealed) SolControl < handle
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
        connObject
        
        %channel identifiers
        channelCode
    end
   
    properties (SetObservable, SetAccess = private, GetAccess = public)
        deviceStatus       
    end
    
    methods (Static)
        function propChange(metaProp,eventData)
            h = eventData.AffectedObject;
            propName = metaProp.Name;           
        
             disp(['The ',propName,' property has changed.'])
             disp([h.deviceStatus])        
        end
    end
    
    %% Main Methods
    methods          
        function sc = SolControl(varargin)
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
            
            javaaddpath('C:\Users\local_admin\Documents\GitHub\Symphony-UI\petri_required_libraries\ComPortConnector.jar');

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
            
            sc.calcChannelCodes();
            sc.showGui();
        end
        
        function attachListener(sc)
            addlistener(sc,'deviceStatus','PostSet',@SolControl.propChange);
        end
        
        function showGui(sc)
            % Dimensions of the GUI
            panelWidth = 150;
            dialogWidth = 3 * panelWidth;
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
                sPanelParamTag = ['ValveStatus' sc.channelCode(v)];
                sc.guiObjects.(sPanelParamTag) = uipanel(...
                    'Parent', sc.guiObjects.(panelParamTag), ...
                    'Units', 'points', ...
                    'FontSize', FontSize, ...
                    'Tag', sPanelParamTag, ...
                    'Position', [1 ((dialogHeight - 15) - ((v) * (((dialogHeight - 15)/sc.channels)))) 145 ((dialogHeight/sc.channels) - 6)] ...
                );
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
                %fclose(sc.conn);
                %Closing the connection
                sc.conn.closeAll();
                sc.connObject.rd.closeThreadPool();

                % Clearing all variables
                clear sc.connObject.rd sc.connObject.s sc.conn;

                % delete(sc.conn);
            end
            
           delete(sc.gui);
           
           delete(sc);
           clear sc.conn sc sc.gui;
        end
        
        function openClose(sc, ~ , ~ , v, s)
            msg = ['V,' int2str(v) ',' int2str(s)];
            sc.send(msg);
            sc.changeValveStatus(v, s);
            sc.deviceStatus = sc.status('S');
        end
        
        % A function to change the status of the valve in the GUI
        function changeValveStatus(sc, valve, status)
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
                otherwise
                    c = sc.color;
                    onBtn = 'Off';
                    offBtn = 'Off';   
            end

            On = ['Open' name];
            set(sc.guiObjects.(On), 'Enable', onBtn);

            Off = ['Close' name];
            set(sc.guiObjects.(Off), 'Enable', offBtn);

            ValveStatus = ['ValveStatus' name];
            set(sc.guiObjects.(ValveStatus), 'BackgroundColor', c); 
        end     
        
    end
    %% Serial Port Methods
    methods    
       function send(sc, msg)
           import com.comportconnector.lib.*;
           sc.connObject.s.sendString(msg);
           %fprintf(sc.conn,msg);
       end
              
       function status = status(sc, msg) 
           import com.comportconnector.lib.*;
           % fprintf(sc.conn,msg); 
           % status = fscanf(sc.conn);
           sc.connObject.rd = RecieveData(sc.conn.getIn()); 		
           sc.connObject.s.sendString(msg);
           status = char(sc.connObject.rd.submitTask());
           sc.connObject.rd.closeThreadPool();
        end
        
        function disconnect(sc, ~ , ~ )
            import com.comportconnector.lib.*;
            sc.deviceStatus = sc.status('S');
            % fclose(sc.conn);
            
            %Closing the connection
            sc.conn.closeAll();
            sc.connObject.rd.closeThreadPool();

            % Clearing all variables
            clear sc.connObject.rd sc.connObject.s sc.conn;

            set(sc.guiObjects.Disconnect, 'Enable', 'Off');
            set(sc.guiObjects.Connect, 'Enable', 'On');    
            set(sc.guiObjects.Ports, 'Enable', 'On');       
            
            for v = 1:sc.channels
                sc.changeValveStatus(v, 3);
            end            
        end
                
        function connect(sc, ~ , ~ )
            import com.comportconnector.lib.*;
            sc.portValue = get(sc.guiObjects.Ports,'Value');
            sc.port = sc.portList{sc.portValue};
            
            % sc.conn = serial(sc.port);
            sc.conn = Connector(sc.port);
            % sc.conn.BaudRate = 57600;
            % sc.conn.ReadAsyncMode = 'continuous';
            % sc.conn.Terminator = 'CR';
                        
            % fopen(sc.conn);
            sc.conn.connect();	
            sc.connObject.s = SendData(sc.conn.getOut());

            set(sc.guiObjects.Disconnect, 'Enable', 'On');
            set(sc.guiObjects.Connect, 'Enable', 'Off');
            set(sc.guiObjects.Ports, 'Enable', 'Off');
            
            sc.deviceStatus = sc.status('S');
            status = textscan(sc.deviceStatus, '%s', 'delimiter', sprintf(','));
            
            for v = 1:sc.channels  
               sc.changeValveStatus(v, str2double(status{1}{v+1}));
            end
        end 
    end
end

