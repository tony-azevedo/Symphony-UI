classdef (Sealed) logger < handle
    properties
        gui
        guiObjects
    end
    
    properties (SetAccess = private, GetAccess = public)
        dateStamp
        currentFileName
        fsGUI
        isValid
        autoSave
        saveTimer        
    end
    
    properties (SetAccess = private, GetAccess = private)
        symphonyDir
        newFileCount = 0
        newFileCode
        folders
        fileNames
        fsGUIObjects
        timerInterval = 60;
    end
    
    %% Main Method
    methods
        function pl = logger()
            pl.isValid = false;
        end
        
        function start( varargin )
            narginchk(1,5);
            pl =  varargin{1};
            
            if isa(pl,'logger')
                pl.folders = struct();
                
                pl.symphonyDir = fileparts(mfilename('fullpath'));
                
                pl.folders.main = '';
                pl.folders.hidden = '';
                pl.folders.header = '';
                pl.autoSave = 0;
                
                for v = 2:(nargin)
                    input = varargin{v};
                    
                    if iscell(input)
                        if strcmp(input{1},'main') && pl.dirCheck(input{2})
                            pl.folders.main = input{2};
                        elseif strcmp(input{1},'hidden') && pl.dirCheck(input{2})
                            pl.folders.hidden = input{2};
                        elseif strcmp(input{1},'header') && pl.dirCheck(input{2})
                            pl.folders.header = input{2};
                        elseif strcmp(input{1},'autosave') && isboolean(input{2})
                            pl.autoSave = input{2};
                        elseif strcmp(input{1},'timerInterval') && isnumeric(input{2})
                            pl.timerInterval = input{2};
                        end
                        
                    end
                end
                
                if ispref('SymphonyLogger', 'hiddenFolder') && isempty(pl.folders.hidden)
                    pl.folders.hidden = getpref('SymphonyLogger', 'hiddenFolder');
                else
                    pl.folders.hidden = fullfile(pl.symphonyDir, 'log_files_hidden');
                end
                
                if ispref('SymphonyLogger', 'mainFolder') && isempty(pl.folders.main)
                    pl.folders.main = getpref('SymphonyLogger', 'mainFolder');
                else
                    pl.folders.main = fullfile(pl.symphonyDir, 'log_files');
                end
                
                if ispref('SymphonyLogger','logFileHeaderFile') && isempty(pl.folders.header)
                    pl.folders.header = getpref('SymphonyLogger', 'headerFolder');
                else
                    pl.folders.header = fullfile(pl.symphonyDir, 'log_templates');
                end
                
                pl.initTimer;
                
                pl.dateStamp = datestr(now, 'mm_dd_yy');
                
                pl.fileNames = struct();
                pl.fileNames.currentFileName = pl.dateStamp;
                
                pl.showGui;
                pl.isValid = true;
            end
        end
                
        %% GUI Generation
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
            menu.file.new = uimenu(menu.file.parent,'Label','New','Accelerator','n','Callback',@(hObject,eventdata)newFcn(pl,hObject,eventdata , ''));
            menu.file.open = uimenu(menu.file.parent,'Label','Open','Accelerator','o','Callback',@(hObject,eventdata)openFcn(pl,hObject,eventdata));
            menu.file.save = uimenu(menu.file.parent,'Label','Save','Accelerator','s','Callback',@(hObject,eventdata)saveFcn(pl,hObject,eventdata));
            
            menu.file.autoSaveOptions = uimenu(menu.file.parent,'Label','Auto Save Options');
            menu.file.autosave = uimenu(menu.file.autoSaveOptions,'Label','Autosave');
            if(pl.autoSave)
                on = 'Off';
                off = 'On';
            else
                on = 'On';
                off = 'Off';                
            end
            
            menu.file.autosaveOn = uimenu(menu.file.autosave,'Label','On','Enable',on,'Callback',@(hObject,eventdata)autoSaveFcn(pl,hObject,eventdata,1));
            menu.file.autosaveOff = uimenu(menu.file.autosave,'Label','Off','Enable',off,'Callback',@(hObject,eventdata)autoSaveFcn(pl,hObject,eventdata,0));
            
            menu.file.saveLoc = uimenu(menu.file.autoSaveOptions,'Label','Select File Save Locations');
            menu.file.saveLocHidden = uimenu(menu.file.saveLoc,'Label','Hidden Log File','Callback',@(hObject,eventdata)changeLogFolders(pl,hObject,eventdata,'hidden'));
            menu.file.saveLocMain = uimenu(menu.file.saveLoc,'Label','Main Log File','Callback',@(hObject,eventdata)changeLogFolders(pl,hObject,eventdata,'main'));
            
            menu.edit.parent = uimenu(pl.gui,'Label','Edit');
            menu.edit.enable = uimenu(menu.edit.parent,'Label','Enable','Accelerator','e','Callback',@(hObject,eventdata)enableFcn(pl,hObject,eventdata));
            menu.edit.disable = uimenu(menu.edit.parent,'Label','Disable','Accelerator','d','Enable','Off', 'Callback',@(hObject,eventdata)disableFcn(pl,hObject,eventdata));
            
            menu.comments.parent = uimenu(pl.gui,'Label','Insert');
            menu.comments.insert = uimenu(menu.comments.parent,'Label','Comments','Accelerator','i','Callback',@(hObject,eventdata)insertCommentsFcn(pl,hObject,eventdata));
            menu.comments.insert = uimenu(menu.comments.parent,'Label','Log Header Template','Accelerator','l','Callback',@(hObject,eventdata)insertLogHeaderFcn(pl,hObject,eventdata));
            
            menu.goto.parent = uimenu(pl.gui,'Label','GoTo');
            menu.goto.sof = uimenu(menu.goto.parent,'Label','Top','Accelerator','t','Callback',@(hObject,eventdata)goto(pl,hObject,eventdata,0));
            menu.goto.eof = uimenu(menu.goto.parent,'Label','End Of File','Accelerator','g','Callback',@(hObject,eventdata)goto(pl,hObject,eventdata));
        end
        
        %% GUI Callback Funtions
        function autoSaveFcn ( pl , ~ , ~ , status)
            if(status)
                pl.startTimer;
                on = 'off';
                off = 'on';
            else
                pl.stopTimer;
                on = 'on';
                off = 'off';
            end
            
            set(pl.guiObjects.menu.file.autosaveOn, 'Enable', on);
            set(pl.guiObjects.menu.file.autosaveOff, 'Enable', off);
        end
        
        function goto( varargin )
            narginchk(1,4);
            
            pl = varargin{1};
            if isa(pl,'logger')
                
                javaTextAreaHandler = findjobj(pl.guiObjects.textArea);
                javaTextArea = javaTextAreaHandler.getComponent(0).getComponent(0);
                
                if nargin == 4 && isnumeric(varargin{4}) && varargin{4} == 0
                    position = varargin{4};
                elseif nargin == 2 && isnumeric(varargin{2}) && varargin{2} == 0
                    position = varargin{2};
                else
                    position = javaTextArea.getDocument.getLength;
                end
                
                javaTextArea.setCaretPosition(position);
            end
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
        
        function changeLogFolders( pl , ~ , ~ , folder)
            getDir = pl.folders.( folder );          
            temp = uigetdir(getDir, 'Log File Location');
            
            if temp ~= 0
                pl.folders.( folder ) = temp;
                setpref('SymphonyLogger', [folder 'Folder'], temp);
            end
        end
        
        function insertLogHeaderFcn( pl , ~ , ~ )
            [filename, pathname] =  uigetfile({'*.log;*.txt','All Files'}, 'Log Header File', pl.folders.header);
            if filename ~= 0
                pl.folders.header = pathname;
                getpref('SymphonyLogger', 'headerFolder', pl.folders.header);
                file = fullfile(pathname, filename);
                pl.parseFile(file);
            end
        end
        
        function insertCommentsFcn( pl , ~ , ~ )
            comment = inputdlg('Enter you Comment','Comments', [30 100]);
            
            if ~isempty(comment)
                comment = char(comment);
                commentBanner = '***************************************************';
                formatSpec ='%s\r%s\r%s';
                s = sprintf(formatSpec,commentBanner,comment,commentBanner);

                currentText = char(get(pl.guiObjects.textArea, 'String'));    
                formatSpec ='%s\r%s';
                s = sprintf(formatSpec,currentText,s);
                set(pl.guiObjects.textArea, 'String', s);
            end
        end
        
        function closeRequestFcn( ~ , ~ , ~ )
            waitfor(errordlg('The Log File Editor can only be closed from the main symphony GUI'));
        end
        
        function openFcn ( pl , hObject , eventdata )
            [filename, pathname] =  uigetfile({'*.log;*.txt','All Files'}, 'Log Header File', pl.symphonyDir);
            if filename ~= 0
                msg = [ 
                        '\n\nNote: The File Opened will not be Overwritten.' ...
                        'It will only be saved under the new file name.'
                      ];
                  
                pl.newFcn( hObject , eventdata , msg);
                file = fullfile(pathname, filename);
                pl.parseFile(file);   
            end 
        end
        
        function saveFcn( varargin )
            narginchk(1,3);
            pl = varargin{1};
            
            if isa(pl,'logger')
                s = get(pl.guiObjects.textArea, 'String');
                nRow = size(s,1);
                
                foldersLoc = fieldnames(pl.folders);
                
                for folder = 1:2
                    loc = pl.folders.(foldersLoc{folder});
                    if exist(loc, 'dir')
                        f = [loc '\' pl.fileNames.currentFileName '.log'];
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
        end
        
        function newFcn( pl , ~ , ~ , msg)
            pl.saveFcn;
            oldFile = pl.fileNames.currentFileName;
            
            if pl.newFileCount > 0
                pl.fileNames.( ['file' pl.newFileCode(pl.newFileCount)] ) = oldFile;
            else
                pl.fileNames.file = oldFile;
            end
            
            pl.newFileCount = pl.newFileCount + 1;
            pl.newFileName;
            
            warning = sprintf([ 
                        'The File you were just working on, ' ...
                        oldFile ...
                        ' has now been saved. ' ...
                        'A new File will be created with the name: ' ...
                        pl.fileNames.currentFileName ...
                        msg ...
                      ]);
            
            waitfor(warndlg(warning));
            set(pl.guiObjects.textArea, 'String', '');
        end
        
        %% helper functions
        function openExistingFile(pl)
            tempFileName = getpref('SymphonyLogger', 'currentFileName', pl.fileNames.currentFileName);
            
            dateCheck = strfind(tempFileName, pl.dateStamp);
            
            fileLoc = fullfile(pl.folders.main ,[tempFileName '.log']);
            
            if ~isempty(dateCheck) && exist(fileLoc, 'file')
                pl.fileNames.currentFileName = tempFileName;
                pl.newFileCount = getpref('SymphonyLogger', 'newFileCount', pl.newFileCount);
                parseFile(pl, fileLoc);
                pl.newFileCode = getpref('SymphonyLogger', 'newFileCode', pl.newFileCode);
            else
                setpref('SymphonyLogger', 'currentFileName', pl.fileNames.currentFileName);
                setpref('SymphonyLogger', 'newFileCount', pl.newFileCount);
                setpref('SymphonyLogger', 'newFileCode', []);
                pl.goto(0);
            end
        end
        
        % A function to parse a simple text file
        function  parseFile(pl, s)
            fid = fopen(s, 'r');
            openFile = textscan(fid, '%s', 'Delimiter', '\r');
            fclose(fid);
            out = pl.parseText(openFile{1}); 
            pl.log(out);
        end
        
        function log( varargin )
            narginchk(2,100);
            pl = varargin{1};
            
            if isa(pl,'logger')
                s = '';
                for v = 2:nargin
                    if v == 2
                        formatSpec ='%s%s';
                    else
                        formatSpec ='%s\r%s';
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

                currentText = char(get(pl.guiObjects.textArea, 'String'));

                formatSpec ='%s\r%s';
                s = sprintf(formatSpec,currentText,s);
                set(pl.guiObjects.textArea, 'String', s);
                pl.goto(0);
            end
        end
        
        function out = parseText( ~ , text)
            formatSpec = '%s%s\r';
            out = '';
            for iRow = 1:length(text)
                out = sprintf(formatSpec,out,char(text{iRow}));
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

        function oDir = dirCheck( ~ , dir )
            if isdir(dir)
                oDir = true;
            else
                oDir = false;
            end
        end
        
        function initTimer(pl)
            pl.saveTimer = timer;
            pl.saveTimer.TimerFcn = {@pl.saveFcn};
            pl.saveTimer.Period = pl.timerInterval;
            pl.saveTimer.ExecutionMode = 'fixedSpacing';
            pl.saveTimer.Tag = 'Save Timer';
        end    
                    
        function startTimer(pl)
            if(strcmp(pl.saveTimer.Running, 'off'))
                start(pl.saveTimer);
            end
        end

        function stopTimer(pl)
            if(strcmp(pl.saveTimer.Running, 'on'))
                stop(pl.saveTimer);
            end
        end        
    end
    
end