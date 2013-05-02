classdef IDAQInputStream < Symphony.Core.IDAQStream
   
    properties (Abstract)
        Devices
    end
    
    methods (Abstract)
        PushInputData(obj, inData);
    end
    
end