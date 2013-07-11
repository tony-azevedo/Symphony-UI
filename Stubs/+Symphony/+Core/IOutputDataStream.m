classdef IOutputDataStream < handle
    
    methods (Abstract)
        d = PullOutputData(obj, duration);
    end
    
end

