classdef IDAQController < Symphony.Core.ITimelineProducer & Symphony.Core.IHardwareController
    
    properties (Abstract)
        Streams
        InputStreams
        OutputStreams
    end
    
    methods (Abstract)
        s = GetStream(obj, name);
    end
    
end