%A function for displaying the GUI
function solution = SolutionController()
    import com.comportconnector.lib.*;

    %Opening the Connection
    handles.conn = Connector();
    handles.connected = false;
    
    global cS;
    
    %switches on the controller
    %maximum switches in current programming is 52
    %this can be modified id required
    handles.channels = 5;
    
    upperCaseStart = 65;
    alphabetLength = 26;
    lowerCaseStart = 97;
        
    for v = 1:handles.channels
        if v < (alphabetLength + 1)
            indexnum = v - 1;
            number = upperCaseStart;
        else
            indexnum = v - 1 - alphabetLength;
            number = lowerCaseStart;
        end
        
        handles.channelCode(v) = char(number + indexnum);
        
        if (v == 52) 
            break;
        end
    end
    
    % Dimensions of the GUI
    dialogWidth = 450;
    dialogHeight = handles.channels * 35;
    
    % Place this dialog on the same screen that the main window is on.
    s = windowScreen(gcf);
    
    %Variables Used for placing objects on the GUI
    fLI = 5;
    sLI = 75;
    FontSize = 9;
    HeadingFontSize = 10;
    objectHeight = 30;
    objectWidth = 65;

    %Construcing the GUI
    handles.figure = dialog(...
        'Units', 'points', ...
        'Name', 'Solution Controller', ...
        'Position', centerWindowOnScreen(double(dialogWidth), double(dialogHeight), s), ...
        'Menubar', 'none', ...
        'Tag', 'figure', ...
        'CloseRequestFcn', @(hObject,eventdata)disconnect(hObject,eventdata,guidata(hObject), true) ...
    );
    
    handles.color = get(handles.figure, 'Color');

    % The Settings Panel
    panelParamTag = 'Settings';
    handles.(panelParamTag) = uipanel(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', HeadingFontSize, ...
        'Title', panelParamTag, ...
        'Tag', panelParamTag, ...
        'Position', [0 0 150 dialogHeight] ...
    );
    
    javaPortString = handles.conn.portScan;
    handles.portList = cell(javaPortString);
 
    paramTag = 'PortsLabel'; 
    handles.(paramTag) = uicontrol(...
         'Parent', handles.(panelParamTag), ...
         'Style', 'text', ...
         'String', 'Select Port:', ...
         'Units', 'points', ...
         'Position', [fLI (dialogHeight - 48) objectWidth objectHeight], ...
         'FontSize', FontSize, ...
         'Tag', paramTag);
    
    paramTag = 'Ports'; 
    handles.(paramTag) = uicontrol(...
        'Parent', handles.(panelParamTag), ...
        'Units', 'points', ...
        'Position', [sLI (dialogHeight - 45) objectWidth objectHeight], ...
        'String', handles.portList, ...
        'Style', 'popupmenu', ...
        'Value', 1, ...
        'Enable', 'On', ...
        'Tag', paramTag);
    
    paramTag = 'Connect'; 
    handles.(paramTag) = uicontrol(...
        'Parent', handles.(panelParamTag), ...
        'Units', 'points', ...
        'Enable', 'On', ...
        'Callback',  @(hObject,eventdata)connect(hObject,eventdata,guidata(hObject)), ...
        'Position', [fLI (dialogHeight - 70) objectWidth objectHeight], ...
        'String', paramTag, ...
        'Tag', paramTag);
 
    paramTag = 'Disconnect'; 
    handles.(paramTag) = uicontrol(...
        'Parent', handles.(panelParamTag), ...
        'Units', 'points', ...
        'Enable', 'Off', ...
        'Callback',  @(hObject,eventdata)disconnect(hObject,eventdata,guidata(hObject), false), ...
        'Position', [sLI (dialogHeight - 70) objectWidth objectHeight], ...
        'String', paramTag, ...
        'Tag', paramTag);

    % The Panel to control the valves
    panelParamTag = 'ValveControl';
    handles.(panelParamTag) = uipanel(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', HeadingFontSize, ...
        'Title', panelParamTag, ...
        'Tag', panelParamTag, ...
        'Position', [150 0 150 dialogHeight] ...
    );
    
    for v = 1:handles.channels
        
        sPanelParamTag = ['valve' handles.channelCode(v)];
        handles.(sPanelParamTag) = uipanel(...
            'Parent', handles.(panelParamTag), ...
            'Units', 'points', ...
            'FontSize', FontSize, ...
            'Title', v, ...
            'Tag', sPanelParamTag, ...
            'Position', [1 ((dialogHeight - 15) - ((v) * (((dialogHeight - 15)/5)))) 145 (dialogHeight/5)] ...
        );
    
        paramTag = ['Open' handles.channelCode(v)];
        handles.(paramTag) = uicontrol(...
            'Parent', handles.(sPanelParamTag), ...
            'Units', 'points', ...
            'Enable', 'Off', ...
            'Position', [fLI 3 objectWidth 20], ...
            'Callback',  @(hObject,eventdata)openClose(hObject,eventdata,guidata(hObject),v, 1), ...
            'String', 'Open', ...
            'Tag', paramTag);

        paramTag = ['Close' handles.channelCode(v)];
        handles.(paramTag) = uicontrol(...
            'Parent', handles.(sPanelParamTag), ...
            'Units', 'points', ...
            'Enable', 'Off', ...
            'Position', [sLI 3 objectWidth 20], ...
            'Callback',  @(hObject,eventdata)openClose(hObject,eventdata,guidata(hObject),v, 0), ...
            'String', 'Close', ...
            'Tag', paramTag);       
    end
    
    % The Panel Display the Valve Status
    panelParamTag = 'ValveStatus';
    handles.(panelParamTag) = uipanel(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', HeadingFontSize, ...
        'Title', panelParamTag, ...
        'Tag', panelParamTag, ...
        'Position', [300 0 150 dialogHeight] ...
    );
    
    for v = 1:handles.channels
        sPanelParamTag = ['ValveStatus' handles.channelCode(v)];
        handles.(sPanelParamTag) = uipanel(...
            'Parent', handles.(panelParamTag), ...
            'Units', 'points', ...
            'FontSize', FontSize, ...
            'Tag', sPanelParamTag, ...
            'Position', [1 ((dialogHeight - 15) - ((v) * (((dialogHeight - 15)/5)))) 145 ((dialogHeight/5) - 6)] ...
        );
    end
    
    
    guidata(handles.figure, handles);
    
    uiwait;
    
    solution = cS;
    clearvars -global cS;
end

% A function to determine whether the User is opening or closing the valve
% and send the message to the solution controller
function openClose( ~ , ~ , handles, v, s)
    msg = java.lang.String(['V,' int2str(v) ',' int2str(s)]); 
    handles.sendData.sendString(msg);
    
    changeValveStatus(v, s);  
    global cS;
    cS = channelStatus(handles);
    
    guidata(handles.figure, handles);
end

% A function to change the status of the valve in the GUI
function changeValveStatus(valve, status)
    handles = guidata(gcbo);
    name = handles.channelCode(valve);
    
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
            c = handles.color;
            onBtn = 'Off';
            offBtn = 'Off';   
    end
    
    On = ['Open' name];
    set(handles.(On), 'Enable', onBtn);

    Off = ['Close' name];
    set(handles.(Off), 'Enable', offBtn);
    
    ValveStatus = ['ValveStatus' name];
    set(handles.(ValveStatus), 'BackgroundColor', c); 
    guidata(gcbo,handles) 
end

% A function to connect to the solution controller
function connect( ~ , ~ , handles)
    import com.comportconnector.lib.*;
    p = get(handles.Ports,'Value');
    handles.conn.setSerialPort(handles.portList(p)); 
    handles.conn.connect();
    
    %Saying that I want to send and recieve data (You dont have to both send and recieve data)
    handles.recieveData = RecieveData(handles.conn.getIn()); 			
    handles.sendData = SendData(handles.conn.getOut()); 
    
    set(handles.Disconnect, 'Enable', 'On');
    set(handles.Connect, 'Enable', 'Off');
    set(handles.Ports, 'Enable', 'Off');
    
    handles.connected = true;
    global cS;
    cS = channelStatus(handles);
    
    status = textscan(cS, '%s', 'delimiter', sprintf(','));
    
    for v = 1:handles.channels  
       changeValveStatus(v, str2double(status{1}{v+1}));
    end

    guidata(handles.figure, handles);
end

% A function to Disconnect from the Solution Controller
function disconnect( ~ , ~ , handles, cRF)
    import com.comportconnector.lib.*;
    %Closing the connection
    if handles.connected
        handles.conn.closeAll();
        handles.recieveData.closeThreadPool();

        set(handles.Disconnect, 'Enable', 'Off');
        set(handles.Connect, 'Enable', 'On');    
        set(handles.Ports, 'Enable', 'On');
        
        for v = 1:handles.channels
            changeValveStatus(v, 3);
        end
        
        handles.connected = false;
        guidata(handles.figure, handles);
    end  
    
    if cRF
        delete(gcf);
    end
end

% A function to return the status of the solution controller
function channelStatus = channelStatus(handles)
    import com.comportconnector.lib.*;
    % Requesting from the Device what channels are open & closed
    if handles.connected
        handles.sendData.sendString(java.lang.String('S'));
        channelStatus = char(handles.recieveData.submitTask());
    else
        channelStatus = char('');
    end
end