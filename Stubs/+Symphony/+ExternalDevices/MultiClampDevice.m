classdef MultiClampDevice < Symphony.Core.ExternalDeviceBase
    
    properties
        backgrounds
        mode = 'VClamp'
    end
    
    methods
        
        function obj = MultiClampDevice(serialNumber, channel, clock, controller, modes, backgrounds) %#ok<INUSL>
            obj = obj@Symphony.Core.ExternalDeviceBase('', 'AutoMate', controller, backgrounds(1));
            
            obj.backgrounds = containers.Map();
            for i = 1:numel(modes)
                obj.backgrounds(char(modes(i))) = backgrounds(i);
            end
        end
        
        
        function d = PullOutputData(obj, stream, duration)
            d = obj.Controller.PullOutputData(obj, duration); 
        end
        
        
        function PushInputData(obj, stream, inData)
            obj.Controller.PushInputData(obj, inData);
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
        
        
        function SetBackgroundForMode(obj, mode, background)
            import Symphony.ExternalDevices.*
            
            switch mode
                case OperatingMode.VClamp
                    mode = 'VClamp';
                case OperatingMode.IClamp
                    mode = 'IClamp';
                case OperatingMode.IO
                    mode = 'IO';
            end
            
            obj.backgrounds(mode) = background;            
        end
        
        
        function b = Background(obj)
            b = obj.backgrounds(obj.mode);
        end
        
        
        function Dispose(obj) %#ok<MANU>
            
        end
        
    end
end