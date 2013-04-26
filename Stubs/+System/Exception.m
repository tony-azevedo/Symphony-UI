classdef Exception < handle
    
    properties
        InnerException
        Message
    end
    
    methods
        
        function obj = Exception(message)
            obj = obj@handle();
            
            obj.Message = message;
        end
        
    end
    
end

