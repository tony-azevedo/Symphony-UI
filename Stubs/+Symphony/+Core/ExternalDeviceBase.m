classdef ExternalDeviceBase < Symphony.Core.IExternalDevice
   
    properties
        Controller
        Background
        Clock
        Name
        Manufacturer
    end
    
    properties (SetAccess = private)
        Streams
    end
    
    methods
        
        function obj = ExternalDeviceBase(name, manufacturer, controller, background)
            obj.Name = name;
            obj.Manufacturer = manufacturer;
            obj.Controller = controller;
            obj.Background = background;
            
            obj.Streams = System.Collections.Generic.Dictionary();
            
            obj.Controller.AddDevice(obj);
        end
        
        
        function device = BindStream(obj, arg1, arg2)            
            if nargin == 2
                stream = arg1;
                obj.Streams.Add(stream.Name, stream);
            else
                stream = arg2;
                obj.Streams.Add(arg1, stream);
            end    
            
            if isa(stream, 'Symphony.Core.IDAQOutputStream')
                stream.Device = obj;
            else
                stream.Devices.Add(obj);
            end
            
            device = obj;
        end
        
    end
end