classdef IDAQController < Symphony.Core.ITimelineProducer & Symphony.Core.IHardwareController
    
    properties (Abstract, SetAccess = private)
        Streams
        InputStreams
        OutputStreams
    end
    
    methods (Abstract)
        s = GetStream(obj, name);
    end
    
end