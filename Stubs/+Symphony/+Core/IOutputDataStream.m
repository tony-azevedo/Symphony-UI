classdef IOutputDataStream < Symphony.Core.IIODataStream
    
    methods (Abstract)
        outData = PullOutputData(obj, duration);
    end
    
end

