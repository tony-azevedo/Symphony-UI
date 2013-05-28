classdef HekaDAQControllerFactory < DAQControllerFactory
    
    methods
        
        function daq = createDAQ(obj) %#ok<MANU>

            % Add required .NET assembly
            % TODO: Getting the Symphony framework path should be extracted somehow, maybe into a function.
            if isWin64bit
                symphonyPath = fullfile(getenv('PROGRAMFILES(x86)'), 'Physion\Symphony\bin');
            else
                symphonyPath = fullfile(getenv('PROGRAMFILES'), 'Physion\Symphony\bin');
            end
            try
                NET.addAssembly(fullfile(symphonyPath, 'HekaDAQInterface.dll'));
            catch %#ok<CTCH>
                error('Unable to load the Heka DAQ Interface. You probably need to install the Heka ITC drivers.');
            end
            
            import Symphony.Core.*;
            import Heka.*;
                
            % Register the unit converters
            HekaDAQInputStream.RegisterConverters();
            HekaDAQOutputStream.RegisterConverters();

            % Get the bus ID of the Heka ITC.
            % (Stored as a local pref so that each rig can have its own value.)
            hekaID = getpref('Symphony', 'HekaBusID', '');
            if isempty(hekaID)
                answer = questdlg('How is the Heka connected?', 'Symphony', 'USB', 'PCI', 'Cancel', 'Cancel');
                if strcmp(answer, 'Cancel')
                    error('Symphony:Heka:NoBusID', 'Cannot create a Heka controller without a bus ID');
                elseif strcmp(answer, 'PCI')
                    % Convert these to Matlab doubles because they're more flexible calling .NET functions in the future
                    hekaID = double(NativeInterop.ITCMM.ITC18_ID);
                else    % USB
                    hekaID = double(NativeInterop.ITCMM.USB18_ID);
                end
                setpref('Symphony', 'HekaBusID', hekaID);
            end

            daq = HekaDAQController(hekaID, 0);
            daq.InitHardware();
        end
        
    end
    
end

