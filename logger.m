classdef (Sealed) logger < handle
    properties
        gui
        guiObjects  
    end  

    properties (SetAccess = private, GetAccess = public)
        dateStamp
        newFileCount = 0
        newFileCode
        folders
        fileNames
        currentFileName
        logFileHeaderFile
        fsGUI
        fsGUIObjects
        isValid
    end
    
    %% Main Method
    methods          
        function pl = logger()
            pl.isValid = false;
        end
        
        function start(varargin)            
           narginchk(1,4);
           pl =  varargin{1};
           pl.folders = struct();
           
           if ispref('SymphonyLogger', 'hiddenFolder');
               pl.folders.hidden = getpref('SymphonyLogger', 'hiddenFolder');
           else
               pl.folders.hidden = '';
           end
           
           if ispref('SymphonyLogger', 'mainFolder');
               pl.folders.main = getpref('SymphonyLogger', 'mainFolder');
           else
               pl.folders.main = '';
           end
           
           pl.logFileHeaderFile = '';
           
            for v = 2:(nargin)
                input = varargin{v};
                
                if iscell(input)
                    if strcmp(input{1},'main')
                        pl.folders.main = input{2};
                    elseif strcmp(input{1},'hidden')
                        pl.folders.hidden = input{2};
                    elseif strcmp(input{1},'logFileHeaderFile')
                        pl.logFileHeaderFile = input{2};
                    end
                end
            end
            
            pl.fsGUI = pl.folderSelector;
            
            waitfor(pl.fsGUI);
            
            pl.dateStamp = datestr(now, 'mm_dd_yy');
            
            pl.fileNames = struct();
            pl.fileNames.currentFileName = pl.dateStamp;
            pl.showGui;
            pl.isValid = true;
        end
        
        %% GUI generation
        function fsGUI = folderSelector(pl)
            dialogWidth = 300;
            dialogHeight = 210;
            
             fsGUI = figure(...
            'Units', 'points', ...
            'Name', 'folder Selector', ...
            'position',[364, 350, dialogWidth, dialogHeight],...
            'Menubar', 'none', ...
            'Tag', 'figure');
        
            pl.fsGUIObjects = struct();
            
            panelParamTag = 'MainPanel';
            pl.fsGUIObjects.(panelParamTag) = uipanel(...
                'Parent', fsGUI, ...
                'Units', 'points', ...
                'Title', 'Main Log File Location', ...
                'Tag', 'Main Log File Location', ...
                'Position', [0 (dialogHeight-dialogHeight/3) dialogWidth dialogHeight/3] ...
            );
            
            panelObjectTag = 'mainView';
            pl.fsGUIObjects.(panelObjectTag) = uicontrol(...
                'Parent', pl.fsGUIObjects.(panelParamTag), ...
                'Units','points',...
                'Enable','off',...
                'Position',[5 (dialogHeight/3 - 40) (dialogWidth - 15) 22],...
                'String', pl.folders.main,...
                'Style','edit',...
                'Tag','loggingFolderView');
            
            panelObjectTag = 'mainButton';
            pl.fsGUIObjects.(panelObjectTag) = uicontrol(...
                'Parent', pl.fsGUIObjects.(panelParamTag), ...
                'Units','points',...
                'Callback',@(hObject,eventdata)changeMainLogFileFolder(pl,hObject,eventdata),...
                'Position',[5 (dialogHeight/3 - 62) (dialogWidth - 15) 22],...
                'String','Change Main Folder Location',...
                'Tag','loggingFolderChange');

            
            % The Settings Panel
            panelParamTag = 'HiddenPanel';
            pl.fsGUIObjects.(panelParamTag) = uipanel(...
                'Parent', fsGUI, ...
                'Units', 'points', ...
                'Title', 'Hidden Log File Location', ...
                'Tag', 'Hidden Log File Location', ...
                'Position', [0 (dialogHeight-2*dialogHeight/3) dialogWidth dialogHeight/3] ...
            );
            
            panelObjectTag = 'hiddenView';
            pl.fsGUIObjects.(panelObjectTag) = uicontrol(...
                'Parent', pl.fsGUIObjects.(panelParamTag), ...
                'Units','points',...
                'Enable','off',...
                'Position',[5 (dialogHeight/3 - 40) (dialogWidth - 15) 22],...
                'String', pl.folders.hidden,...
                'Style','edit',...
                'Tag','loggingFolderView');
            
            panelObjectTag = 'hiddenButton';
            pl.fsGUIObjects.(panelObjectTag) = uicontrol(...
                'Parent', pl.fsGUIObjects.(panelParamTag), ...
                'Units','points',...
                'Callback',@(hObject,eventdata)changeHiddenLogFileFolder(pl,hObject,eventdata),...
                'Position',[5 (dialogHeight/3 - 62) (dialogWidth - 15) 22],...
                'String','Change Hidden Folder Location',...
                'Tag','loggingFolderChange');
            
            panelParamTag = 'savePanel';
            pl.fsGUIObjects.(panelParamTag) = uipanel(...
                'Parent', fsGUI, ...
                'Units', 'points', ...
                'Title', 'Save Preferences', ...
                'Tag', 'Save Preferences', ...
                'Position', [0 0 dialogWidth dialogHeight/3] ...
            );
        
            panelObjectTag = 'saveButton';
            pl.fsGUIObjects.(panelObjectTag) = uicontrol(...
                'Parent', pl.fsGUIObjects.(panelParamTag), ...
                'Units','points',...
                'Callback',@(hObject,eventdata)savePref(pl,hObject,eventdata),...
                'Position',[5 (dialogHeight/3 - 50) (dialogWidth - 15) 22],...
                'String','Save',...
                'Tag','loggingFolderChange');
        
        end
        
        function savePref( pl , ~ , ~ )
            close(pl.fsGUI);
        end
        
        function changeHiddenLogFileFolder( pl , ~ , ~ )
           pl.folders.hidden = uigetdir(pl.folders.hidden, 'Log File Location');
           setpref('SymphonyLogger', 'hiddenFolder', pl.folders.hidden);
           set(pl.fsGUIObjects.hiddenView, 'String', pl.folders.hidden);
        end

       function changeMainLogFileFolder( pl , ~ , ~ )
           pl.folders.main = uigetdir(pl.folders.main, 'Log File Location');
           setpref('SymphonyLogger', 'mainFolder', pl.folders.main);
           set(pl.fsGUIObjects.mainView, 'String', pl.folders.main);
        end

        function showGui(pl)
            %Construcing the GUI
             
            dialogWidth = 500;
            dialogHeight = 600;
 
            pl.gui = figure(...
                'Units', 'points', ...
                'Name', 'Solution Controller', ...
                'Menubar', 'none', ...
                'Tag', 'figure', ...
                'position',[364, 100, dialogWidth, dialogHeight],...
                'CloseRequestFcn', @(hObject,eventdata)closeRequestFcn(pl,hObject,eventdata), ...
                'Resize','off' ...
            );
        
            pl.guiObjects = struct();
            
            pl.guiObjects.textArea = uicontrol(...
                 'Parent',pl.gui,...
                 'BackgroundColor',[1 1 1],...
                 'FontSize', 8,...
                 'Units','points',...
                 'Enable','off',...
                 'HorizontalAlignment','left',...
                 'Max',1000,...
                 'Position',[0 0 dialogWidth dialogHeight],...
                 'Min',1,...
                 'Style','edit',...
                 'Tag','textArea'...
            );
        
            pl.guiObjects.menu = pl.createMenu;
            pl.openExistingFile;
        end 
        
        function menu = createMenu(pl)
            menu = struct();
            menu.file = struct();            
            menu.edit = struct();
            menu.comments = struct();           
            
            menu.file.parent = uimenu(pl.gui,'Label','File');
            menu.file.new = uimenu(menu.file.parent,'Label','New','Callback',@(hObject,eventdata)newFcn(pl,hObject,eventdata));
            menu.file.save = uimenu(menu.file.parent,'Label','Save','Callback',@(hObject,eventdata)saveFcn(pl,hObject,eventdata));

            menu.edit.parent = uimenu(pl.gui,'Label','Edit');
            menu.edit.enable = uimenu(menu.edit.parent,'Label','Enable','Callback',@(hObject,eventdata)enableFcn(pl,hObject,eventdata));
            menu.edit.disable = uimenu(menu.edit.parent,'Label','Disable','Enable','Off', 'Callback',@(hObject,eventdata)disableFcn(pl,hObject,eventdata));
            
            menu.comments.parent = uimenu(pl.gui,'Label','Comments');
            menu.comments.insert = uimenu(menu.comments.parent,'Label','Insert','Callback',@(hObject,eventdata)insertFcn(pl,hObject,eventdata));
        end
        
        function enableFcn( pl , ~ , ~ )
            set(pl.guiObjects.menu.edit.enable, 'Enable', 'off');
            set(pl.guiObjects.menu.edit.disable, 'Enable', 'on');
            set(pl.guiObjects.textArea, 'Enable', 'on');
        end
        
        function disableFcn( pl , ~ , ~ )
            set(pl.guiObjects.menu.edit.enable, 'Enable', 'on');
            set(pl.guiObjects.menu.edit.disable, 'Enable', 'off'); 
            set(pl.guiObjects.textArea, 'Enable', 'off');
        end
                
        function insertFcn( pl , ~ , ~ )
            comment = inputdlg('Enter you Comment','Comments', [30 100]);
            comment = char(comment);

            if ~isempty(comment)
                commentBanner = '***************************************************';
                currentText = get(pl.guiObjects.textArea, 'String');   
                
                if ~isempty(currentText)
                    formatSpec ='%s\r%s\r%s\r%s';
                    s = sprintf(formatSpec,currentText,commentBanner,comment,commentBanner);
                else
                    formatSpec ='%s\r%s\r%s';
                    s = sprintf(formatSpec,commentBanner,comment,commentBanner);                    
                end
                
                set(pl.guiObjects.textArea, 'String', s);
            end  
        end
        
        function closeRequestFcn( ~ , ~ , ~ )
            waitfor(errordlg('The Log File Editor can only be closed from the main symphony GUI'));
        end
        
        function saveFcn( pl , ~ , ~ )
            s = get(pl.guiObjects.textArea, 'String');
            nRow = size(s,1);
            
            foldersLoc = fieldnames(pl.folders);
            
            for folder = 1:2
                loc = pl.folders.(foldersLoc{folder});
                if exist(loc, 'dir')
                    if strcmp(foldersLoc{folder}, 'main')
                        f = [loc '\' pl.fileNames.currentFileName '.log'];
                    else
                        f = [loc '\.' pl.fileNames.currentFileName '.log'];
                    end
                    
                    fid = fopen(f, 'w');                   
                    
                    formatSpec = '%s%s\r\n';
                    out = '';
                    
                    for iRow = 1:nRow
                        out = sprintf(formatSpec,out,s(iRow,:)); 
                    end
                    fprintf(fid, out);
                    fclose(fid);
                else
                    waitfor(warndlg(['could not save to the folder location "' loc '" as it is not a valid folder']));
                end
            end
        end
        
        function newFcn( pl , ~ , ~ )
            pl.saveFcn(false,false);
            oldFile = pl.fileNames.currentFileName;
            
            if pl.newFileCount > 0
                pl.fileNames.( ['file' pl.newFileCode(pl.newFileCount)] ) = oldFile;
            else
                pl.fileNames.file = oldFile;
            end
            
            pl.newFileCount = pl.newFileCount + 1;
            pl.newFileName;
            
            warning = [ 'The File you were just working on, ' ...
                oldFile ...
                ' has now been saved. ' ...
                'A new File will be created with the name: ' ...
                pl.fileNames.currentFileName];
            
            waitfor(warndlg(warning));
            set(pl.guiObjects.textArea, 'String', '');
            
            if(exist(pl.logFileHeaderFile, 'file'))
                parseFile(pl, pl.logFileHeaderFile);
            end
        end

        %% helper functions
        function openExistingFile(pl)
            tempFileName = getpref('SymphonyLogger', 'currentFileName', pl.fileNames.currentFileName);
            
            dateCheck = strfind(tempFileName, pl.dateStamp);
            
            fileLoc = fullfile(pl.folders.main ,[tempFileName '.log']);
            
            if dateCheck == 1 && exist(fileLoc, 'file')
                pl.fileNames.currentFileName = tempFileName;
                pl.newFileCount = getpref('SymphonyLogger', 'newFileCount', pl.newFileCount);
                parseFile(pl, fileLoc);
                pl.newFileCode = getpref('SymphonyLogger', 'newFileCode', pl.newFileCode);
            else
                if(exist(pl.logFileHeaderFile, 'file'))
                    parseFile(pl, pl.logFileHeaderFile);
                end
                
                setpref('SymphonyLogger', 'currentFileName', pl.fileNames.currentFileName);
                setpref('SymphonyLogger', 'newFileCount', pl.newFileCount);
                setpref('SymphonyLogger', 'newFileCode', []);
            end
        end
        
        % A function to parse a simple text file
        function  parseFile(pl, s)
            fid = fopen(s, 'r');
            openFile = textscan(fid, '%s', 'Delimiter', '\r');
            fclose(fid);
            
            formatSpec = '%s%s\r';
            out = '';
                    
            for iRow = 1:length(openFile{1})
                out = sprintf(formatSpec,out,char(openFile{1}(iRow)));
            end
      
            pl.log(out);
        end
        
        function log(pl, varargin)
           if nargin > 0
              s = get(pl.guiObjects.textArea, 'String');

                for v = 1:(nargin-1)
                    formatSpec ='%s\r%s';
                    if v == 1 && isempty(s)
                        formatSpec ='%s%s';
                    end
                    
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

                set(pl.guiObjects.textArea,'string',s);
           end
        end
        
        function newFileName(pl)
            upperCaseStart = 65;
            alphabetLength = 26;
            lowerCaseStart = 97;
            
            if pl.newFileCount < (alphabetLength + 1)
                indexnum = pl.newFileCount - 1;
                number = upperCaseStart;
            else
                indexnum = pl.newFileCount - 1 - alphabetLength;
                number = lowerCaseStart;
            end

            pl.newFileCode(pl.newFileCount) = char(number + indexnum);
            pl.fileNames.currentFileName = [pl.dateStamp pl.newFileCode(pl.newFileCount)];
            setpref('SymphonyLogger', 'currentFileName', pl.fileNames.currentFileName);
            setpref('SymphonyLogger', 'newFileCount', pl.newFileCount);
            setpref('SymphonyLogger', 'newFileCode', pl.newFileCode);
        end
        
    end
    
end