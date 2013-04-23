%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef MultiClampDevice < Symphony.Core.ExternalDeviceBase
    
    properties
        backgrounds
        mode = 'VClamp'
    end
    
    
    methods
        
        function obj = MultiClampDevice(serialNumber, channel, clock, controller, modes, backgrounds) %#ok<INUSL,INUSD>
            obj = obj@Symphony.Core.ExternalDeviceBase('', 'AutoMate', controller, backgrounds(1));
            
            obj.backgrounds = containers.Map();
            for i = 1:length(modes)
                obj.backgrounds(char(modes(i))) = backgrounds(i);
            end
        end
        
        
        function b = HasDeviceOutputParameters(obj) %#ok<MANU>
            b = true;
        end
        
        
        function params = DeviceParametersForInput(obj, ~)
            params.Data.OperatingMode = obj.mode;
        end
        
        
        function params = DeviceParametersForOutput(obj, ~)
            params.Data.OperatingMode = obj.mode;
        end
        
        
        function params = CurrentDeviceInputParameters(obj)
            params.Data.OperatingMode = obj.mode;
        end
        
        
        function params = CurrentDeviceOutputParameters(obj)
            params.Data.OperatingMode = obj.mode;
        end
        
        
        function b = Background(obj)
            b = obj.backgrounds(obj.mode);
        end
        
        
        function Dispose(obj) %#ok<MANU>
            
        end
        
    end
end