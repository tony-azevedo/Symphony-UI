classdef PetriSymphony < Symphony
    properties
        % Variables for Petri's Functionality
        sController;
        petrilogger
        mh
        lf
        lfStop
        lfStart   
        reInitSol = false
    end
    
    %% Instantiation Method for the Symphony Application
    methods (Static)
%         function solutionControllerChange( ~ , eventData , protocol )
%             h = eventData.AffectedObject;
%             if(~strcmp(h.deviceStatus,''))
%                 h.updateGUI();
%                 protocol.solutionControler.deviceStatus = h.deviceStatus;
%                 protocol.solutionControler.recordStatus = true;
%             end
%         end        
        
        function singleObj = getInstance
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = PetriSymphony;
            end
            singleObj = localObj;
        end
    end
    
    methods (Access = private)
        function obj = PetriSymphony
            obj =  obj@Symphony();
        end
    end
    
    methods
        function addLabMenu(obj)
            obj.mh = uimenu(obj.mainWindow,'Label','Petri''s Lab Features'); 
            uimenu(obj.mh,'Label','Solution Controller','Callback',@(hObject,eventdata)solutionControllerInitGui(obj,hObject,eventdata));
            
            obj.lf = uimenu(obj.mh,'Label','Log File');
            obj.lfStart = uimenu(obj.lf,'Label','Start ','Enable','on','Callback',@(hObject,eventdata)logFile(obj,hObject,eventdata, true));
            obj.lfStop = uimenu(obj.lf,'Label','Stop','Enable','off','Callback',@(hObject,eventdata)logFile(obj,hObject,eventdata, false));
            
            uimenu(obj.mh,'Label','Quit','Accelerator','q','Callback', @(hObject,eventdata)closeRequestFcn(obj,hObject,eventdata));
        end    
        
        %Solution Controller
        function solutionControllerInitGui( varargin )
            narginchk(1,3);
            obj =  varargin{1};
            if isa(obj,'PetriSymphony')
%                 obj.sController = @(p, c)SolutionController({'port',7} , {'channels',5});
%                 batch(obj.sController,'matlabpool',1);
                  obj.sController =  SolutionController({'port',8} , {'channels',5});
                addlistener(obj.sController,'deviceStatus','PostSet',@( metaProp , eventData )obj.solutionControllerChange( metaProp , eventData, obj.protocol));   
            end
        end
        
        %Log File
        function logFile(obj, ~, ~, status)
            if status
                startEnable = 'off';
                stopEnable = 'on';
                
                obj.petrilogger = logger(); 
                obj.protocol.petrilogger = obj.petrilogger;
                
                obj.petrilogger.start({'main','C:\Users\local_admin\Desktop'},{'hidden','C:\Users\local_admin\Desktop'});
            else
                deleteLog = questdlg('Are you sure you want to stop logging', 'Stop Logging', 'Yes', 'No', 'No');
                if strcmp(deleteLog, 'Yes')
                    startEnable = 'on';
                    stopEnable = 'off';  
                    obj.deleteLogFile();
                end
            end
            
            set(obj.lfStart, 'Enable', startEnable);
            set(obj.lfStop, 'Enable', stopEnable);
        end

        function close(obj)
            obj.deleteLogFile;
            obj.deleteSolutionController;
            % deleting the symphony Instance
            symphonyInstance = PetriSymphony.getInstance;
            delete(symphonyInstance);
        end
        
        function deleteSolutionController(obj)
            if ~isempty(obj.sController) && isvalid(obj.sController)
                obj.sController.disconnect;
                delete(obj.sController.gui);
                delete(obj.sController);                    
            end
        end    
        
        function deleteLogFile(obj)
            if isvalid(obj.petrilogger) && obj.petrilogger.isValid
                obj.petrilogger.stopTimer;
                delete(obj.petrilogger.saveTimer);
                delete(obj.petrilogger.gui);
                delete(obj.petrilogger);        
            end
        end     
        
        function showMainWindow(obj)
             showMainWindow@Symphony(obj);
             obj.addLabMenu();       
        end
        
        function chooseRigConfiguration(obj,hObject,eventdata)
            obj.solControllerTest;
            chooseRigConfiguration@Symphony(obj,hObject,eventdata);
        end
        
        function newProtocol = createProtocol(obj, className)     
            obj.solControllerTest;
            newProtocol =  createProtocol@Symphony(obj, className);
            newProtocol.petrilogger = obj.petrilogger;
            
            if obj.reInitSol
                obj.solutionControllerInitGui;
                obj.reInitSol = false;
            end            
        end
        
        function solControllerTest(obj)
            if ~isempty(obj.sController) && isvalid(obj.sController)
                obj.reInitSol = true;
                obj.deleteSolutionController;
            end            
        end
    end
end