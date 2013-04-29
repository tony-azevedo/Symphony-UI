classdef IHardwareController < handle
    
    properties (Abstract)
        Running
    end
    
    methods (Abstract)
        Start(obj, waitForTrigger)
        Stop(obj);
    end
    
end