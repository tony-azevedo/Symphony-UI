classdef IDAQOutputStream < Symphony.Core.IDAQStream
   
    properties (Abstract)
        Device
        HasMoreData
        Background
    end
    
    methods (Abstract)
        d = PullOutputData(obj, duration)
    end
end