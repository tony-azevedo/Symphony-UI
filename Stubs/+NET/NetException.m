classdef NetException < MException
    
    properties
        ExceptionObject
    end
    
    methods
        
        function obj = NetException(id, msg, netObj)
            obj@MException(id, '%s', msg);
            
            obj.ExceptionObject = netObj;
        end
        
    end
    
end

