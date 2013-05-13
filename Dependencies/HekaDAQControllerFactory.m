classdef HekaDAQControllerFactory < DAQControllerFactory
    
    methods
        
        function daq = createDAQ(obj) %#ok<MANU>
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

