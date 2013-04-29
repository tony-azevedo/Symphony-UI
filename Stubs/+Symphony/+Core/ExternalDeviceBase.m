classdef ExternalDeviceBase < Symphony.Core.IExternalDevice
   
    properties
        Name
        Controller
        Background
        Streams
        Manufacturer
        Clock
    end
    
    methods
        
        function obj = ExternalDeviceBase(name, manufacturer, controller, background)
            obj.Name = name;
            obj.Manufacturer = manufacturer;
            obj.Controller = controller;
            obj.Background = background;
            
            obj.Streams = GenericDictionary();
            
            obj.Controller.AddDevice(obj);
        end
        
        
        function device = BindStream(obj, arg1, arg2)            
            if nargin == 2
                obj.Streams.Add(arg1.Name, arg1);
            else
                obj.Streams.Add(arg1, arg2);
            end    
            
            device = obj;
        end
        
    end
end